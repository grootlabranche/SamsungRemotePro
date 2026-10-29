import AppIntents
import ActivityKit

/// Keeps the general Live Activity background tap as a deliberate app-opening action.
struct OpenRemoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Ouvrir Samsung Remote Pro"
    static var description = IntentDescription("Ouvre la télécommande complète.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult { .result() }
}

/// Interactive Live Activity action. LiveActivityIntent runs in the app process
/// without presenting the app UI, so the saved TV and its Keychain pairing token
/// remain available and commands can use the normal Samsung service implementation.
struct RemoteActivityActionIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Commande Samsung Remote Pro"
    static var description = IntentDescription("Exécute une commande sur le téléviseur depuis la Live Activity.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Action") var actionRawValue: String
    @Parameter(title: "Identifiant de l’application TV") var appID: String

    init() {
        self.actionRawValue = "playPause"
        self.appID = ""
    }

    init(actionRawValue: String, appID: String = "") {
        self.actionRawValue = actionRawValue
        self.appID = appID
    }

    func perform() async throws -> some IntentResult {
        #if !WIDGET_EXTENSION
        let store = await MainActor.run { TVStore() }
        let service = await MainActor.run { SamsungTVService(store: store) }

        if !appID.isEmpty {
            let app = await MainActor.run { store.favoriteApps.first(where: { $0.id == appID }) }
            if let app { await service.sendFromShortcut(.launchApplication(app)) }
        } else if let action = LiveActivityQuickAction(rawValue: actionRawValue),
                  let command = command(for: action) {
            let selectedName = await MainActor.run { store.selectedTelevision?.name }
            let matchingActivity = Activity<RemoteActivityAttributes>.activities.first(where: {
                selectedName == nil || $0.attributes.televisionName == selectedName
            })
            let currentlyPlaying = matchingActivity?.content.state.isPlaying ?? false
            let actualCommand: RemoteCommand
            switch action {
            case .playPause: actualCommand = currentlyPlaying ? .pause : .play
            case .play: actualCommand = .play
            case .pause: actualCommand = .pause
            default: actualCommand = command
            }
            await service.sendFromShortcut(actualCommand)

            if let matchingActivity {
                let old = matchingActivity.content.state
                let nextPlaying: Bool? = {
                    switch action {
                    case .playPause: return !currentlyPlaying
                    case .play: return true
                    case .pause: return false
                    default: return nil
                    }
                }()
                if let nextPlaying {
                    let updated = RemoteActivityAttributes.ContentState(
                        connectionLabel: old.connectionLabel, televisionName: old.televisionName,
                        quickAction: old.quickAction, launcherApps: old.launcherApps,
                        isPlaying: nextPlaying, buttonTintHex: old.buttonTintHex
                    )
                    await matchingActivity.update(ActivityContent(state: updated, staleDate: nil))
                }
            }
        }
        #endif
        return .result()
    }

    #if !WIDGET_EXTENSION
    private func command(for action: LiveActivityQuickAction) -> RemoteCommand? {
        switch action {
        case .openRemote: return nil
        case .playPause: return .playPause
        case .play: return .play
        case .pause: return .pause
        case .rewind: return .rewind
        case .fastForward: return .fastForward
        case .volumeUp: return .volumeUp
        case .volumeDown: return .volumeDown
        case .mute: return .mute
        case .back: return .back
        case .home: return .home
        }
    }
    #endif
}

#if !WIDGET_EXTENSION
/// All useful physical-remote commands are available as a parameterized action in Shortcuts.
enum RemoteShortcutAction: String, AppEnum, CaseIterable, Codable, Hashable, Sendable {
    case up, down, left, right, select, back, home, menu, power
    case volumeUp, volumeDown, mute
    case play, pause, playPause, rewind, fastForward
    case channelUp, channelDown

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Commande de télécommande"
    static var caseDisplayRepresentations: [RemoteShortcutAction: DisplayRepresentation] = [
        .up: "Haut", .down: "Bas", .left: "Gauche", .right: "Droite", .select: "Sélectionner",
        .back: "Retour", .home: "Accueil", .menu: "Menu", .power: "Alimentation",
        .volumeUp: "Volume +", .volumeDown: "Volume −", .mute: "Sourdine",
        .play: "Lecture", .pause: "Pause", .playPause: "Lecture / pause",
        .rewind: "Retour rapide", .fastForward: "Avance rapide",
        .channelUp: "Chaîne suivante", .channelDown: "Chaîne précédente"
    ]

    var remoteCommand: RemoteCommand {
        switch self {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .select: return .select
        case .back: return .back
        case .home: return .home
        case .menu: return .menu
        case .power: return .power
        case .volumeUp: return .volumeUp
        case .volumeDown: return .volumeDown
        case .mute: return .mute
        case .play: return .play
        case .pause: return .pause
        case .playPause: return .playPause
        case .rewind: return .rewind
        case .fastForward: return .fastForward
        case .channelUp: return .channelUp
        case .channelDown: return .channelDown
        }
    }
}

struct SendRemoteCommandIntent: AppIntent {
    static var title: LocalizedStringResource = "Envoyer une commande à la TV Samsung"
    static var description = IntentDescription("Exécute une commande précise de la télécommande Samsung Remote Pro.")
    static var openAppWhenRun = false

    @Parameter(title: "Commande") var action: RemoteShortcutAction

    init() { action = .playPause }
    init(action: RemoteShortcutAction) { self.action = action }

    func perform() async throws -> some IntentResult {
        let store = await MainActor.run { TVStore() }
        let service = await MainActor.run { SamsungTVService(store: store) }
        await service.sendFromShortcut(action.remoteCommand)
        return .result()
    }
}

/// Siri's preconfigured phrases are limited to the most commonly used commands.
/// Every additional direction/media/channel command remains selectable in the Shortcuts app
/// through the single "Envoyer une commande à la TV Samsung" action above.
struct SamsungRemoteAppShortcuts: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: SendRemoteCommandIntent(action: .power),
                    phrases: ["\(.applicationName) bascule l’alimentation de la télévision", "\(.applicationName) éteins ou allume la télé"],
                    shortTitle: "Alimentation TV", systemImageName: "power")
        AppShortcut(intent: SendRemoteCommandIntent(action: .playPause),
                    phrases: ["\(.applicationName) lecture ou pause sur la télévision", "\(.applicationName) mets la télé en pause"],
                    shortTitle: "Lecture / pause", systemImageName: "playpause.fill")
        AppShortcut(intent: SendRemoteCommandIntent(action: .volumeUp),
                    phrases: ["\(.applicationName) augmente le volume de la télévision"],
                    shortTitle: "Volume +", systemImageName: "speaker.wave.2.fill")
        AppShortcut(intent: SendRemoteCommandIntent(action: .volumeDown),
                    phrases: ["\(.applicationName) baisse le volume de la télévision"],
                    shortTitle: "Volume −", systemImageName: "speaker.wave.1.fill")
        AppShortcut(intent: SendRemoteCommandIntent(action: .mute),
                    phrases: ["\(.applicationName) coupe le son de la télévision"],
                    shortTitle: "Sourdine", systemImageName: "speaker.slash.fill")
        AppShortcut(intent: SendRemoteCommandIntent(action: .home),
                    phrases: ["\(.applicationName) ouvre l’accueil de la télévision"],
                    shortTitle: "Accueil TV", systemImageName: "house.fill")
        AppShortcut(intent: SendRemoteCommandIntent(action: .back),
                    phrases: ["\(.applicationName) retour sur la télévision"],
                    shortTitle: "Retour TV", systemImageName: "arrow.uturn.backward")
        AppShortcut(intent: SendRemoteCommandIntent(action: .up),
                    phrases: ["\(.applicationName) monte dans les menus de la télévision"],
                    shortTitle: "Haut", systemImageName: "arrow.up")
        AppShortcut(intent: SendRemoteCommandIntent(action: .down),
                    phrases: ["\(.applicationName) descend dans les menus de la télévision"],
                    shortTitle: "Bas", systemImageName: "arrow.down")
        AppShortcut(intent: SendRemoteCommandIntent(action: .select),
                    phrases: ["\(.applicationName) valide la sélection sur la télévision"],
                    shortTitle: "Valider TV", systemImageName: "checkmark")
    }
}

#endif
