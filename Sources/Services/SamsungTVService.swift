import Combine
import Foundation
import UIKit

@MainActor
final class SamsungTVService: ObservableObject {
    @Published private(set) var connectionState: ConnectionState = .disconnected
    @Published private(set) var lastDiagnostic = "Aucun diagnostic réseau exécuté."
    @Published private(set) var lastCommandDate: Date?
    @Published private(set) var isPairingRequested = false
    @Published private(set) var detectedApplications: [RemoteApplication] = []

    private let socket: SamsungWebSocketClient
    private let discovery: SamsungDiscoveryService
    private let store: TVStore
    private var connectedTV: SamsungTV?
    private var reconnectAttempts = 0
    private var reconnectTask: Task<Void, Never>?
    private var connectionDeadline: Task<Void, Never>?

    init(store: TVStore) {
        self.store = store
        self.socket = SamsungWebSocketClient()
        self.discovery = SamsungDiscoveryService()
        socket.onEvent = { [weak self] event in self?.handle(event) }
        socket.onFailure = { [weak self] error in self?.handleFailure(error) }
    }

    init(store: TVStore, socket: SamsungWebSocketClient, discovery: SamsungDiscoveryService) {
        self.store = store
        self.socket = socket
        self.discovery = discovery
        socket.onEvent = { [weak self] event in self?.handle(event) }
        socket.onFailure = { [weak self] error in self?.handleFailure(error) }
    }

    func discoverTelevisions() async -> [SamsungTV] {
        connectionState = .discovering
        let results = await discovery.discover()
        connectionState = .disconnected
        lastDiagnostic = results.isEmpty
            ? "Aucun téléviseur Samsung n’a été détecté par Bonjour ni par le scan IPv4. Vous pouvez saisir son adresse IP."
            : "\(results.count) téléviseur(s) compatible(s) trouvé(s)."
        return results
    }

    func validateAndConnect(host: String, secure: Bool = true) async {
        let normalized = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidHost(normalized) else { connectionState = .failed(.invalidAddress); return }
        // Respect the selected preference first, but try the other known Samsung
        // endpoint if the selected port is not exposed by this TV/firmware.
        let preferred = await discovery.probe(host: normalized, useSecureConnection: secure)
        let alternate: SamsungTV?
        if preferred == nil {
            alternate = await discovery.probe(host: normalized, useSecureConnection: !secure)
        } else {
            alternate = nil
        }
        guard let tv = preferred ?? alternate else {
            connectionState = .failed(.televisionUnavailable)
            lastDiagnostic = "Aucun service Samsung n’a répondu sur \(normalized):8002 ni :8001. Vérifiez que l’iPhone et la TV sont sur le même réseau local, que la TV est allumée et que l’accès au réseau local est autorisé dans iOS."
            return
        }
        store.save(tv)
        connect(to: tv)
    }

    func connect(to television: SamsungTV) {
        reconnectTask?.cancel()
        connectionDeadline?.cancel()
        reconnectAttempts = 0
        connectedTV = television
        isPairingRequested = false
        connectionState = .connecting
        do {
            try socket.connect(to: television, token: KeychainStore.token(for: television))
            lastDiagnostic = "Connexion WebSocket demandée à \(television.endpointDescription)."
            scheduleConnectionDeadline()
        } catch let error as RemoteError {
            connectionState = .failed(error)
        } catch {
            connectionState = .failed(.transportError(error.localizedDescription))
        }
    }

    func disconnect() {
        reconnectTask?.cancel()
        connectionDeadline?.cancel()
        socket.disconnect()
        connectedTV = nil
        isPairingRequested = false
        connectionState = .disconnected
    }

    /// Used by Live Activity deep links: reconnect if the app was suspended and
    /// wait briefly for the WebSocket handshake before sending a one-shot command.
    func sendFromShortcut(_ command: RemoteCommand) async {
        if !connectionState.isConnected {
            guard let television = store.selectedTelevision else {
                lastDiagnostic = "Choisissez d’abord un téléviseur pour utiliser ce raccourci."
                return
            }
            connect(to: television)
            for _ in 0..<40 {
                if connectionState.isConnected {
                    await send(command)
                    return
                }
                if case .failed = connectionState { return }
                try? await Task.sleep(nanoseconds: 250_000_000)
            }
            lastDiagnostic = "La commande rapide a expiré avant la connexion. Vérifiez l’autorisation affichée sur la TV."
            return
        }
        await send(command)
    }

    func send(_ command: RemoteCommand) async {
        guard connectionState.isConnected else {
            connectionState = .failed(.connectionLost)
            return
        }
        do {
            if case .typeText = command {
                // Some TVs need a broadcast to enter text mode; every field closes its input session.
                try await socket.send(SamsungCommandMapper.textSessionStartedData())
                try await socket.send(SamsungCommandMapper.data(for: command))
                try await socket.send(SamsungCommandMapper.textSessionEndedData())
            } else {
                try await socket.send(SamsungCommandMapper.data(for: command))
            }
            lastCommandDate = .now
            // Samsung does not acknowledge every individual remote key. This only records handoff to URLSession.
            lastDiagnostic = "Commande « \(command.accessibilityLabel) » transmise au canal réseau."
        } catch let error as RemoteError {
            connectionState = .failed(error)
        } catch {
            connectionState = .failed(.transportError(error.localizedDescription))
        }
    }

    func remove(_ television: SamsungTV) {
        if connectedTV?.id == television.id { disconnect() }
        store.remove(television)
    }

    func refreshInstalledApplications() async {
        guard connectionState.isConnected else { return }
        do {
            try await socket.send(SamsungCommandMapper.installedApplicationsData())
            lastDiagnostic = "Demande de liste d’applications envoyée. Certaines TV ne répondent pas à cette fonctionnalité."
        } catch let error as RemoteError {
            connectionState = .failed(error)
        } catch {
            connectionState = .failed(.transportError(error.localizedDescription))
        }
    }

    func runDiagnostic(for television: SamsungTV) async {
        lastDiagnostic = "Vérification de \(television.endpointDescription)…"
        if let found = await discovery.probe(host: television.host) {
            lastDiagnostic = "Téléviseur accessible : \(found.name)\(found.model.map { " (\($0))" } ?? "")."
        } else {
            lastDiagnostic = RemoteError.televisionUnavailable.userMessage
        }
    }

    private func handle(_ event: SamsungSocketEvent) {
        switch event.event {
        case "ms.channel.connect", "ms.channel.ready":
            connectionDeadline?.cancel()
            if let token = event.token, let connectedTV { KeychainStore.save(token: token, for: connectedTV) }
            reconnectAttempts = 0
            isPairingRequested = false
            connectionState = .connected
            lastDiagnostic = "Canal de télécommande Samsung établi."
        case "ms.channel.unauthorized":
            isPairingRequested = true
            connectionState = .awaitingAuthorization
            lastDiagnostic = RemoteError.authorizationRequired.userMessage
        case "ms.channel.timeOut":
            handleFailure(.timeout)
        case "ms.error":
            connectionState = .failed(.protocolError("Le téléviseur a renvoyé une erreur."))
        case "ed.installedApp.get":
            updateInstalledApplications(from: event.raw)
        default:
            AppLog.protocolEvents.debug("Événement Samsung : \(event.event, privacy: .public)")
        }
    }

    private func handleFailure(_ error: RemoteError) {
        guard store.preferences.reconnectAutomatically, let television = connectedTV else {
            connectionState = .failed(error); return
        }
        guard reconnectAttempts < 3 else { connectionState = .failed(error); return }
        reconnectAttempts += 1
        let attempt = reconnectAttempts
        connectionState = .reconnecting(attempt: attempt)
        reconnectTask?.cancel()
        connectionDeadline?.cancel()
        reconnectTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Double(attempt) * 2))
            guard !Task.isCancelled else { return }
            self?.connectForReconnect(television, attempt: attempt)
        }
    }

    private func connectForReconnect(_ television: SamsungTV, attempt: Int) {
        connectedTV = television
        connectionState = .reconnecting(attempt: attempt)
        do { try socket.connect(to: television, token: KeychainStore.token(for: television)) }
        catch { connectionState = .failed(.transportError(error.localizedDescription)) }
        scheduleConnectionDeadline()
    }

    private func isValidHost(_ host: String) -> Bool {
        let parts = host.split(separator: ".")
        guard parts.count == 4 else { return false }
        let octets = parts.compactMap { Int($0) }
        guard octets.count == 4, octets.allSatisfy({ (0...255).contains($0) }) else { return false }
        return octets[0] == 10 || (octets[0] == 192 && octets[1] == 168) ||
            (octets[0] == 172 && (16...31).contains(octets[1])) ||
            (octets[0] == 169 && octets[1] == 254)
    }

    private func updateInstalledApplications(from raw: String) {
        guard let data = raw.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let outer = root["data"] as? [String: Any],
              let apps = outer["data"] as? [[String: Any]] else {
            lastDiagnostic = "La TV a répondu à la liste d’applications dans un format non reconnu."
            return
        }
        detectedApplications = apps.compactMap { item in
            guard let id = item["appId"] as? String, let name = item["name"] as? String else { return nil }
            let iconURL = (item["icon"] as? String)
                ?? (item["iconUrl"] as? String)
                ?? (item["icon_url"] as? String)
                ?? (item["iconPath"] as? String)
                ?? (item["icon_path"] as? String)
            return RemoteApplication(id: id, name: name, iconURL: iconURL)
        }
        lastDiagnostic = "\(detectedApplications.count) application(s) signalée(s) par le téléviseur."
        if let television = connectedTV {
            let appsForIcons = detectedApplications
            Task { await fetchTVProvidedIcons(for: appsForIcons, television: television) }
        }
    }

    private func fetchTVProvidedIcons(for apps: [RemoteApplication], television: SamsungTV) async {
        for app in apps where !store.hasCustomLogo(for: app.id) {
            if let rawIconURL = app.iconURL, !rawIconURL.isEmpty {
                let baseURL = URL(string: "http://\(television.host):8001/")
                if let url = URL(string: rawIconURL, relativeTo: baseURL)?.absoluteURL,
                   ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
                    do {
                        var request = URLRequest(url: url)
                        request.timeoutInterval = 4
                        let (data, response) = try await URLSession.shared.data(for: request)
                        if let http = response as? HTTPURLResponse,
                           (200..<300).contains(http.statusCode),
                           let image = UIImage(data: data),
                           let iconData = makeTVIconData(from: image) {
                            store.setTVIcon(iconData, for: app.id)
                        }
                    } catch {
                        AppLog.network.debug("Logo TV indisponible pour \(app.name, privacy: .public)")
                    }
                }
            }

            // Offline fallback artwork is displayed by the UI but is not persisted as a
            // custom/TV logo, so a later refresh can still fetch the real TV artwork.
        }
    }

    private func makeTVIconData(from image: UIImage) -> Data? {
        let side: CGFloat = 256
        let scale = max(side / max(image.size.width, 1), side / max(image.size.height, 1))
        let scaled = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let rect = CGRect(x: (side - scaled.width) / 2, y: (side - scaled.height) / 2, width: scaled.width, height: scaled.height)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format)
        return renderer.image { context in
            UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: side, height: side), cornerRadius: side * 0.22).addClip()
            image.draw(in: rect)
        }.pngData()
    }

    private func scheduleConnectionDeadline() {
        connectionDeadline?.cancel()
        connectionDeadline = Task { [weak self] in
            try? await Task.sleep(for: .seconds(12))
            guard !Task.isCancelled, let self, !self.connectionState.isConnected else { return }
            self.handleFailure(.timeout)
        }
    }
}
