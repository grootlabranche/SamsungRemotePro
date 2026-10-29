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

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(store)
                .environmentObject(service)
                .environmentObject(networkMonitor)
                .task { networkMonitor.start() }
        }
    }
}
