import ActivityKit
import Combine
import Foundation

@MainActor
final class LiveActivityManager: ObservableObject {
    private var activity: Activity<RemoteActivityAttributes>?

    func start(for television: SamsungTV, state: ConnectionState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = RemoteActivityAttributes(televisionName: television.name)
        let content = ActivityContent(state: RemoteActivityAttributes.ContentState(connectionLabel: state.title, televisionName: television.name), staleDate: nil)
        do { activity = try Activity.request(attributes: attributes, content: content) }
        catch { AppLog.network.error("Live Activity indisponible : \(error.localizedDescription, privacy: .public)") }
    }

    func update(for television: SamsungTV, state: ConnectionState) async {
        let content = ActivityContent(state: RemoteActivityAttributes.ContentState(connectionLabel: state.title, televisionName: television.name), staleDate: nil)
        await activity?.update(content)
    }

    func end() async {
        await activity?.end(nil, dismissalPolicy: .default)
        activity = nil
    }
}
