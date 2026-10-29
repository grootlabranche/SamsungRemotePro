import Foundation

struct SamsungSocketEvent: Sendable {
    let event: String
    let token: String?
    let raw: String
}

/// Samsung local TVs may expose a self-signed certificate on their private IP.
/// The delegate accepts that certificate only for private IPv4 endpoints.
@MainActor
final class SamsungWebSocketClient {
    private var task: URLSessionWebSocketTask?
    private let session: URLSession
    private let trustDelegate: SamsungLocalNetworkTrustDelegate?
    var onEvent: ((SamsungSocketEvent) -> Void)?
    var onFailure: ((RemoteError) -> Void)?

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
            self.trustDelegate = nil
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.timeoutIntervalForRequest = 8
            let delegate = SamsungLocalNetworkTrustDelegate()
            self.trustDelegate = delegate
            self.session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        }
    }

    func connect(to television: SamsungTV, token: String?) throws {
        disconnect()
        var components = URLComponents()
        components.scheme = television.usesSecureWebSocket ? "wss" : "ws"
        components.host = television.host
        components.port = television.port
        components.path = "/api/v2/channels/samsung.remote.control"
        let encodedName = Data(AppConfiguration.clientName.utf8).base64EncodedString()
        components.queryItems = [URLQueryItem(name: "name", value: encodedName)] +
            (token.map { [URLQueryItem(name: "token", value: $0)] } ?? [])
        guard let url = components.url else { throw RemoteError.invalidAddress }
        let socket = session.webSocketTask(with: url)
        task = socket
        socket.resume()
        receiveNext(on: socket)
    }

    func send(_ data: Data) async throws {
        guard let task else { throw RemoteError.connectionLost }
        do {
            try await task.send(.data(data))
        } catch {
            throw RemoteError.transportError(error.localizedDescription)
        }
    }

    func disconnect() {
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
    }

    private func receiveNext(on socket: URLSessionWebSocketTask) {
        socket.receive { [weak self, weak socket] result in
            Task { @MainActor in
                guard let self, let socket, self.task === socket else { return }
                switch result {
                case .success(let message):
                    let text: String?
                    switch message {
                    case .string(let value): text = value
                    case .data(let value): text = String(data: value, encoding: .utf8)
                    @unknown default: text = nil
                    }
                    if let text { self.handleIncoming(text) }
                    self.receiveNext(on: socket)
                case .failure(let error):
                    self.onFailure?(Self.map(error))
                }
            }
        }
    }

    private func handleIncoming(_ raw: String) {
        guard let data = raw.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let event = root["event"] as? String else {
            AppLog.protocolEvents.debug("Message Samsung ignoré")
            return
        }
        let token = (root["data"] as? [String: Any])?["token"] as? String
        onEvent?(SamsungSocketEvent(event: event, token: token, raw: raw))
    }

    private static func map(_ error: Error) -> RemoteError {
        let nsError = error as NSError
        if nsError.code == NSURLErrorTimedOut { return .timeout }
        return .transportError(error.localizedDescription)
    }
}
