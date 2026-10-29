import SwiftUI
import WatchConnectivity

@main
struct SamsungRemoteProWatchApp: App {
    @StateObject private var sessionManager = WatchSessionManager()
    var body: some Scene {
        WindowGroup { WatchRemoteView(sessionManager: sessionManager) }
    }
}

final class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    @Published var reachable = false

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async { self.reachable = session.isReachable }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { self.reachable = session.isReachable }
    }
}

struct WatchRemoteView: View {
    @ObservedObject var sessionManager: WatchSessionManager
    @State private var lastStatus = "Prêt"

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                HStack {
                    Circle().fill(sessionManager.reachable ? .green : .orange).frame(width: 7, height: 7)
                    Text(sessionManager.reachable ? "iPhone connecté" : "Ouvrez l’app iPhone")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                LazyVGrid(columns: columns, spacing: 8) {
                    commandButton("power", symbol: "power", label: "")
                    commandButton("home", symbol: "house.fill", label: "Accueil")
                    commandButton("back", symbol: "arrow.uturn.backward", label: "Retour")
                    Color.clear.frame(height: 2)
                    commandButton("up", symbol: "chevron.up", label: "")
                    Color.clear.frame(height: 2)
                    commandButton("left", symbol: "chevron.left", label: "")
                    commandButton("select", symbol: "circle.fill", label: "OK")
                    commandButton("right", symbol: "chevron.right", label: "")
                    Color.clear.frame(height: 2)
                    commandButton("down", symbol: "chevron.down", label: "")
                    Color.clear.frame(height: 2)
                }
                HStack(spacing: 8) {
                    commandButton("volumeDown", symbol: "speaker.down.fill", label: "Vol −")
                    commandButton("mute", symbol: "speaker.slash.fill", label: "Muet")
                    commandButton("volumeUp", symbol: "speaker.wave.2.fill", label: "Vol +")
                }
                HStack(spacing: 8) {
                    commandButton("channelDown", symbol: "minus", label: "Chaîne")
                    commandButton("playPause", symbol: "playpause.fill", label: "Lecture")
                    commandButton("channelUp", symbol: "plus", label: "Chaîne")
                }
                Text(lastStatus).font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            .padding(.horizontal, 8).padding(.vertical, 6)
        }
        .navigationTitle("Samsung Remote")
        .onAppear(perform: refreshReachability)
    }

    private func commandButton(_ command: String, symbol: String, label: String) -> some View {
        Button {
            send(command)
        } label: {
            VStack(spacing: 3) {
                Image(systemName: symbol).font(.system(size: 17, weight: .semibold))
                if !label.isEmpty { Text(label).font(.system(size: 9, weight: .medium)).lineLimit(1) }
            }
            .frame(maxWidth: .infinity, minHeight: 37)
        }
        .buttonStyle(.borderedProminent)
        .tint(command == "power" ? .red : .blue)
    }

    private func send(_ command: String) {
        guard WCSession.isSupported() else { lastStatus = "WatchConnectivity indisponible"; return }
        let session = WCSession.default
        guard session.isReachable else {
            lastStatus = "Ouvrez SamsungRemotePro sur l’iPhone, puis réessayez."
            return
        }
        session.sendMessage(["command": command], replyHandler: { _ in
            DispatchQueue.main.async { lastStatus = "Commande envoyée" }
        }, errorHandler: { error in
            DispatchQueue.main.async { lastStatus = "Échec : \(error.localizedDescription)" }
        })
    }

    private func refreshReachability() {
        sessionManager.reachable = WCSession.isSupported() && WCSession.default.isReachable
    }
}
