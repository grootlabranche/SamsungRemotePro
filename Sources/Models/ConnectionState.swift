import Foundation

enum ConnectionState: Equatable, Sendable {
    case disconnected
    case discovering
    case connecting
    case awaitingAuthorization
    case connected
    case reconnecting(attempt: Int)
    case failed(RemoteError)

    var title: String {
        switch self {
        case .disconnected: return "Non connecté"
        case .discovering: return "Recherche en cours"
        case .connecting: return "Connexion…"
        case .awaitingAuthorization: return "Autorisez sur le téléviseur"
        case .connected: return "Connecté"
        case .reconnecting: return "Reconnexion…"
        case .failed(let error): return error.userMessage
        }
    }

    var isConnected: Bool { if case .connected = self { return true }; return false }
}
