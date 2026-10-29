import Combine
import Foundation

/// Keeps user-intent methods outside SwiftUI views while the service owns transport state.
@MainActor
final class RemoteViewModel: ObservableObject {
    let service: SamsungTVService
    let store: TVStore

    init(service: SamsungTVService, store: TVStore) {
        self.service = service
        self.store = store
    }

    func send(_ command: RemoteCommand) {
        Haptics.tap(enabled: store.preferences.hapticsEnabled)
        Task { await service.send(command) }
    }
}
