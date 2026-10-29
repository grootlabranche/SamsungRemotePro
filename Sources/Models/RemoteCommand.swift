import Foundation

enum RemoteCommand: Equatable, Sendable {
    case up, down, left, right, select, back, home, menu, power
    case volumeUp, volumeDown, mute
    case play, pause, playPause, rewind, fastForward
    case channelUp, channelDown
    case launchApplication(RemoteApplication)
    case typeText(String)

    var accessibilityLabel: String {
        switch self {
        case .up: return "Haut"
        case .down: return "Bas"
        case .left: return "Gauche"
        case .right: return "Droite"
        case .select: return "Sélectionner"
        case .back: return "Retour"
        case .home: return "Accueil"
        case .menu: return "Menu"
        case .power: return "Alimentation"
        case .volumeUp: return "Augmenter le volume"
        case .volumeDown: return "Diminuer le volume"
        case .mute: return "Couper le son"
        case .play: return "Lecture"
        case .pause: return "Pause"
        case .playPause: return "Lecture ou pause"
        case .rewind: return "Retour rapide"
        case .fastForward: return "Avance rapide"
        case .channelUp: return "Chaîne suivante"
        case .channelDown: return "Chaîne précédente"
        case .launchApplication(let app): return "Ouvrir \(app.name)"
        case .typeText: return "Envoyer le texte"
        }
    }
}
