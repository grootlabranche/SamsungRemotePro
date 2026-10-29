import Foundation

enum NavigationMode: String, CaseIterable, Codable, Identifiable {
    case gestures
    case directionalButtons
    var id: String { rawValue }
    var title: String { self == .gestures ? "Glissements" : "Boutons directionnels" }
}

struct RemotePreferences: Codable, Equatable {
    var reconnectAutomatically = true
    var hapticsEnabled = true
    var navigationMode: NavigationMode = .gestures
    var showExtraCommands = true
}
