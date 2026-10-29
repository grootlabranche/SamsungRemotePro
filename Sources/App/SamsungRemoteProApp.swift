import SwiftUI

@main
struct SamsungRemoteProApp: App {
    @StateObject private var store: TVStore
    @StateObject private var service: SamsungTVService
    @StateObject private var networkMonitor = NetworkMonitor()

    init() {
        let store = TVStore()
        _store = StateObject(wrappedValue: store)
        _service = StateObject(wrappedValue: SamsungTVService(store: store))
    }

    private static func remoteCommand(from identifier: String) -> RemoteCommand? {
        switch identifier {
        case "up": return .up
        case "down": return .down
        case "left": return .left
        case "right": return .right
        case "select": return .select
        case "back": return .back
        case "home": return .home
        case "volumeUp": return .volumeUp
        case "volumeDown": return .volumeDown
        case "mute": return .mute
        case "playPause": return .playPause
        case "channelUp": return .channelUp
        case "channelDown": return .channelDown
        case "power": return .power
        default: return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(store)
                .environmentObject(service)
                .environmentObject(networkMonitor)
                .task {
                    networkMonitor.start()
                    WatchConnectivityBridge.shared.start { identifier in
                        guard let command = Self.remoteCommand(from: identifier) else { return }
                        Task { @MainActor in await service.sendFromShortcut(command) }
                    }
                }
        }
    }
}
