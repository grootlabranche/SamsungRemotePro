import AppIntents

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
            if let app {
                await service.sendFromShortcut(.launchApplication(app))
            }
        } else if let action = LiveActivityQuickAction(rawValue: actionRawValue),
                  let command = command(for: action) {
            await service.sendFromShortcut(command)
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
