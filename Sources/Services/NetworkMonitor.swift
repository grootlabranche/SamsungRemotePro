import Combine
import Foundation
import Network

@MainActor
final class NetworkMonitor: ObservableObject {
    @Published private(set) var isConnected = false
    @Published private(set) var usesWiFi = false
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "fr.samsungremotepro.network-monitor")

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
                self?.usesWiFi = path.usesInterfaceType(.wifi)
            }
        }
        monitor.start(queue: queue)
    }

    deinit { monitor.cancel() }
}
