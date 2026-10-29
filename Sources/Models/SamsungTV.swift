import Foundation

struct SamsungTV: Codable, Identifiable, Equatable, Hashable, Sendable {
    var id: UUID
    var name: String
    var host: String
    var port: Int
    var usesSecureWebSocket: Bool
    var model: String?
    var macAddress: String?
    var lastSeen: Date?

    init(
        id: UUID = UUID(), name: String, host: String, port: Int = AppConfiguration.defaultSecurePort,
        usesSecureWebSocket: Bool = true, model: String? = nil, macAddress: String? = nil, lastSeen: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.usesSecureWebSocket = usesSecureWebSocket
        self.model = model
        self.macAddress = macAddress
        self.lastSeen = lastSeen
    }

    var endpointDescription: String { "\(host):\(port)" }
}
