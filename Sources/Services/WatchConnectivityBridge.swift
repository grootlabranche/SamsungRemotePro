import Foundation
import WatchConnectivity

/// Receives simple command identifiers from the companion watchOS app.
/// The iPhone remains responsible for the Samsung TV WebSocket connection.
final class WatchConnectivityBridge: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityBridge()
    private var onCommand: ((String) -> Void)?

    private override init() { super.init() }

    func start(onCommand: @escaping (String) -> Void) {
        self.onCommand = onCommand
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let command = message["command"] as? String else { return }
        DispatchQueue.main.async { [weak self] in self?.onCommand?(command) }
    }
}
