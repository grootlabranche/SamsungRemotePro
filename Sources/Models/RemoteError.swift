import Foundation

enum RemoteError: Error, Equatable, LocalizedError, Sendable {
    case invalidAddress
    case televisionUnavailable
    case authorizationRequired
    case authorizationRefused
    case connectionLost
    case timeout
    case unsupportedCommand
    case localNetworkPermissionDenied
    case protocolError(String)
    case transportError(String)

    var userMessage: String {
        switch self {
        case .invalidAddress: return "L’adresse IP saisie n’est pas valide."
        case .televisionUnavailable: return "Le téléviseur est introuvable ou éteint. Vérifiez qu’il est sur le même réseau Wi‑Fi."
        case .authorizationRequired: return "Acceptez la demande de connexion affichée sur le téléviseur."
        case .authorizationRefused: return "Le téléviseur a refusé la connexion. Supprimez l’appareil autorisé sur la TV puis réessayez."
        case .connectionLost: return "La connexion avec le téléviseur a été perdue."
        case .timeout: return "Le téléviseur ne répond pas dans le délai prévu."
        case .unsupportedCommand: return "Cette commande n’est pas prise en charge par le téléviseur ou l’application ouverte."
        case .localNetworkPermissionDenied: return "Autorisez l’accès au réseau local dans Réglages pour rechercher le téléviseur."
        case .protocolError(let detail): return "Réponse inattendue du téléviseur : \(detail)"
        case .transportError: return "Impossible d’établir une connexion réseau sécurisée avec le téléviseur."
        }
    }

    var errorDescription: String? { userMessage }
}
