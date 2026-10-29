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
    /// Kept for backwards compatibility with settings saved by earlier versions.
    var showExtraCommands = true
    var dynamicIslandAction: LiveActivityQuickAction = .playPause
    var useHardwareVolumeButtons = false

    private enum CodingKeys: String, CodingKey {
        case reconnectAutomatically, hapticsEnabled, navigationMode, showExtraCommands
        case dynamicIslandAction, useHardwareVolumeButtons
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        reconnectAutomatically = try container.decodeIfPresent(Bool.self, forKey: .reconnectAutomatically) ?? true
        hapticsEnabled = try container.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? true
        navigationMode = try container.decodeIfPresent(NavigationMode.self, forKey: .navigationMode) ?? .gestures
        showExtraCommands = try container.decodeIfPresent(Bool.self, forKey: .showExtraCommands) ?? true
        dynamicIslandAction = try container.decodeIfPresent(LiveActivityQuickAction.self, forKey: .dynamicIslandAction) ?? .playPause
        useHardwareVolumeButtons = try container.decodeIfPresent(Bool.self, forKey: .useHardwareVolumeButtons) ?? false
    }
}
