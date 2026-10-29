import Foundation
import Network

/// SSDP discovery for Samsung TVs. iOS may require Apple's multicast entitlement;
/// manual IP entry remains available when multicast is unavailable.
final class SamsungDiscoveryService {
    private let queue = DispatchQueue(label: "fr.samsungremotepro.ssdp")
    private let searchTarget = "ssdp:all"

    func discover(timeout: TimeInterval = 3) async -> [SamsungTV] {
        let hosts = await discoverHosts(timeout: timeout)
        var televisions: [SamsungTV] = []
        for host in hosts {
            if let television = await probe(host: host) { televisions.append(television) }
        }
        return televisions
    }

    /// A non-nil security choice never silently falls back to the other transport.
    func probe(host: String, useSecureConnection: Bool? = nil) async -> SamsungTV? {
        guard !host.isEmpty else { return nil }
        if let useSecureConnection {
            return await probe(host: host,
                               port: useSecureConnection ? AppConfiguration.defaultSecurePort : AppConfiguration.defaultInsecurePort,
                               secure: useSecureConnection)
        }
        let secure = await probe(host: host, port: AppConfiguration.defaultSecurePort, secure: true)
        if let secure {
            return secure
        }
        return await probe(host: host, port: AppConfiguration.defaultInsecurePort, secure: false)
    }

    private func discoverHosts(timeout: TimeInterval) async -> [String] {
        await withCheckedContinuation { continuation in
            let endpoint = NWEndpoint.hostPort(host: "239.255.255.250", port: 1900)
            let connection = NWConnection(to: endpoint, using: .udp)
            var hosts = Set<String>()
            let request = "M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: \"ssdp:discover\"\r\nMX: 2\r\nST: \(searchTarget)\r\n\r\n"
            connection.stateUpdateHandler = { state in
                guard case .ready = state else { return }
                connection.send(content: Data(request.utf8), completion: .contentProcessed { _ in })
                func receive() {
                    connection.receiveMessage { data, _, _, error in
                        guard error == nil else { return }
                        if let data, let response = String(data: data, encoding: .utf8),
                           let host = Self.host(fromSSDPResponse: response) { hosts.insert(host) }
                        receive()
                    }
                }
                receive()
            }
            connection.start(queue: queue)
            queue.asyncAfter(deadline: .now() + timeout) {
                connection.cancel()
                continuation.resume(returning: Array(hosts))
            }
        }
    }

    private func probe(host: String, port: Int, secure: Bool) async -> SamsungTV? {
        var components = URLComponents()
        components.scheme = secure ? "https" : "http"
        components.host = host
        components.port = port
        components.path = "/api/v2/"
        guard let url = components.url else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 2
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            let root = (try JSONSerialization.jsonObject(with: data)) as? [String: Any]
            let device = root?["device"] as? [String: Any]
            let name = (device?["name"] as? String) ?? "Samsung TV"
            let model = (device?["modelName"] as? String) ?? (device?["model"] as? String)
            let tokenAuth = (device?["TokenAuthSupport"] as? Bool) ?? true
            return SamsungTV(name: name, host: host, port: port, usesSecureWebSocket: secure && tokenAuth, model: model, lastSeen: .now)
        } catch {
            return nil
        }
    }

    private static func host(fromSSDPResponse response: String) -> String? {
        let headers = response.split(separator: "\n")
        guard headers.contains(where: { $0.uppercased().contains("SAMSUNG") }),
              let location = headers.first(where: { $0.uppercased().hasPrefix("LOCATION:") }) else { return nil }
        let value = location.dropFirst("LOCATION:".count).trimmingCharacters(in: .whitespacesAndNewlines)
        return URL(string: value)?.host
    }
}
