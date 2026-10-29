import ActivityKit
import AVFAudio
import Combine
import Foundation

@MainActor
final class LiveActivityManager: ObservableObject {
    private var activity: Activity<RemoteActivityAttributes>?

    func start(
        for television: SamsungTV,
        state: ConnectionState,
        quickAction: LiveActivityQuickAction,
        launcherApps: [LiveActivityApp]
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = RemoteActivityAttributes(televisionName: television.name)
        let content = makeContent(for: television, state: state, quickAction: quickAction, launcherApps: launcherApps)

        // Reuse the existing activity for this TV, avoiding a stack of duplicate islands.
        if let existing = Activity<RemoteActivityAttributes>.activities.first(where: {
            $0.attributes.televisionName == television.name
        }) {
            activity = existing
            Task { await existing.update(content) }
            return
        }

        do {
            activity = try Activity.request(attributes: attributes, content: content)
        } catch {
            AppLog.network.error("Live Activity indisponible : \(error.localizedDescription, privacy: .public)")
        }
    }

    func update(
        for television: SamsungTV,
        state: ConnectionState,
        quickAction: LiveActivityQuickAction,
        launcherApps: [LiveActivityApp]
    ) async {
        if activity == nil {
            activity = Activity<RemoteActivityAttributes>.activities.first(where: {
                $0.attributes.televisionName == television.name
            })
        }
        guard let activity else { return }
        await activity.update(makeContent(for: television, state: state, quickAction: quickAction, launcherApps: launcherApps))
    }

    func end() async {
        await activity?.end(nil, dismissalPolicy: .default)
        activity = nil
    }

    private func makeContent(
        for television: SamsungTV,
        state: ConnectionState,
        quickAction: LiveActivityQuickAction,
        launcherApps: [LiveActivityApp]
    ) -> ActivityContent<RemoteActivityAttributes.ContentState> {
        ActivityContent(
            state: RemoteActivityAttributes.ContentState(
                connectionLabel: state.title,
                televisionName: television.name,
                quickAction: quickAction,
                launcherApps: Array(launcherApps.prefix(5))
            ),
            staleDate: nil
        )
    }
}

/// iOS exposes the system output volume as a KVO-observable value, not as raw
/// hardware-button events. This opt-in bridge translates a change while the app
/// is foregrounded into a TV volume command. iOS's own volume can change too.
@MainActor
final class HardwareVolumeButtonBridge: ObservableObject {
    var onVolumeStep: ((Bool) -> Void)?
    private var observation: NSKeyValueObservation?
    private var previousVolume: Float = 0

    func start() {
        guard observation == nil else { return }
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            AppLog.network.debug("Session audio non activée : \(error.localizedDescription, privacy: .public)")
        }
        previousVolume = session.outputVolume
        observation = session.observe(\.outputVolume, options: [.new]) { [weak self] session, _ in
            let currentVolume = session.outputVolume
            DispatchQueue.main.async { [weak self] in
                guard let self, self.observation != nil else { return }
                let delta = currentVolume - self.previousVolume
                self.previousVolume = currentVolume
                guard abs(delta) > 0.002 else { return }
                self.onVolumeStep?(delta > 0)
            }
        }
    }

    func stop() {
        observation?.invalidate()
        observation = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }
}
