import AppIntents

/// Widgets and the Live Activity open the app instead of performing network I/O in an extension.
struct OpenRemoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Ouvrir Samsung Remote Pro"
    static var description = IntentDescription("Ouvre la télécommande complète.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult { .result() }
}
