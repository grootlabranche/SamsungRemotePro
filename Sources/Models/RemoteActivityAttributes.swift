import ActivityKit
import Foundation

/// Quick action shown in the expanded Dynamic Island. The actual network command
/// is routed back to the app, because the app's WebSocket and Keychain session
/// intentionally remain in the app process for the Sideloadly/free-signing build.
enum LiveActivityQuickAction: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case openRemote
    case playPause
    case play
    case pause
    case rewind
    case fastForward
    case volumeUp
    case volumeDown
    case mute
    case back
    case home

    var id: String { rawValue }

    var title: String {
        switch self {
        case .openRemote: return "Ouvrir la télécommande"
        case .playPause: return "Lecture / pause"
        case .play: return "Lecture"
        case .pause: return "Pause"
        case .rewind: return "Retour rapide"
        case .fastForward: return "Avance rapide"
        case .volumeUp: return "Volume +"
        case .volumeDown: return "Volume −"
        case .mute: return "Sourdine"
        case .back: return "Retour"
        case .home: return "Accueil"
        }
    }

    var systemImage: String {
        switch self {
        case .openRemote: return "rectangle.inset.filled"
        case .playPause: return "playpause.fill"
        case .play: return "play.fill"
        case .pause: return "pause.fill"
        case .rewind: return "backward.end.fill"
        case .fastForward: return "forward.end.fill"
        case .volumeUp: return "speaker.wave.2.fill"
        case .volumeDown: return "speaker.wave.1.fill"
        case .mute: return "speaker.slash.fill"
        case .back: return "arrow.uturn.backward"
        case .home: return "house.fill"
        }
    }
}

/// Compact copy of a favorite app stored in the Live Activity state. Keeping the
/// downsampled icon data here lets WidgetKit render custom artwork without App Groups.
struct LiveActivityApp: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var name: String
    var deepLink: String?
    var customIconData: Data?

    init(id: String, name: String, deepLink: String?, customIconData: Data?) {
        self.id = id
        self.name = name
        self.deepLink = deepLink
        self.customIconData = customIconData
    }
}

struct RemoteActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var connectionLabel: String
        var televisionName: String
        var quickAction: LiveActivityQuickAction? = .playPause
        var launcherApps: [LiveActivityApp]? = []
        /// UI-side optimistic media state; Samsung does not acknowledge every media key.
        var isPlaying: Bool = false
        var buttonTintHex: String = "283447"

        private enum CodingKeys: String, CodingKey {
            case connectionLabel, televisionName, quickAction, launcherApps, isPlaying, buttonTintHex
        }

        init(
            connectionLabel: String,
            televisionName: String,
            quickAction: LiveActivityQuickAction? = .playPause,
            launcherApps: [LiveActivityApp]? = [],
            isPlaying: Bool = false,
            buttonTintHex: String = "283447"
        ) {
            self.connectionLabel = connectionLabel
            self.televisionName = televisionName
            self.quickAction = quickAction
            self.launcherApps = launcherApps
            self.isPlaying = isPlaying
            self.buttonTintHex = buttonTintHex
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            connectionLabel = try container.decode(String.self, forKey: .connectionLabel)
            televisionName = try container.decode(String.self, forKey: .televisionName)
            quickAction = try container.decodeIfPresent(LiveActivityQuickAction.self, forKey: .quickAction) ?? .playPause
            launcherApps = try container.decodeIfPresent([LiveActivityApp].self, forKey: .launcherApps) ?? []
            isPlaying = try container.decodeIfPresent(Bool.self, forKey: .isPlaying) ?? false
            buttonTintHex = try container.decodeIfPresent(String.self, forKey: .buttonTintHex) ?? "283447"
        }
    }

    var televisionName: String
}
