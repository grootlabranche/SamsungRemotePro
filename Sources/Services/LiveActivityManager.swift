import ActivityKit
import AVFAudio
import Combine
import Foundation

@MainActor
final class LiveActivityManager: ObservableObject {
    private var operationTask: Task<Void, Never>?
    private var queuedOperationID: UUID?

    /// Queue ActivityKit operations so rapid scene/setting changes cannot race a
    /// request, update, and dismissal against each other.
    private func enqueue(_ operation: @escaping @MainActor (LiveActivityManager) async -> Void) {
        let previous = operationTask
        let operationID = UUID()
        queuedOperationID = operationID
        operationTask = Task { [weak self] in
            await previous?.value
            guard let self else { return }
            await operation(self)
            // Release the completed task chain when this is still the newest operation.
            if self.queuedOperationID == operationID {
                self.operationTask = nil
                self.queuedOperationID = nil
            }
        }
    }

    func start(
        for television: SamsungTV,
        state: ConnectionState,
        quickAction: LiveActivityQuickAction,
        launcherApps: [LiveActivityApp],
        buttonTintHex: String = "283447"
    ) {
        enqueue { manager in
            await manager.performStart(
                for: television, state: state, quickAction: quickAction,
                launcherApps: launcherApps, buttonTintHex: buttonTintHex
            )
        }
    }

    private func performStart(
        for television: SamsungTV,
        state: ConnectionState,
        quickAction: LiveActivityQuickAction,
        launcherApps: [LiveActivityApp],
        buttonTintHex: String
    ) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let allActivities = Activity<RemoteActivityAttributes>.activities.filter {
            $0.activityState != .dismissed
        }
        // Prefer an activity already showing the selected TV; otherwise reuse one
        // existing activity instead of requesting another one for a second TV.
        let existing = allActivities.first(where: {
            $0.content.state.televisionName == television.name
        }) ?? allActivities.first

        // Clean up duplicates left by previous app versions or interrupted tests.
        for duplicate in allActivities where duplicate.id != existing?.id {
            await duplicate.end(nil, dismissalPolicy: .immediate)
        }

        if let existing {
            let content = makeContent(
                for: television, state: state, quickAction: quickAction,
                launcherApps: launcherApps, buttonTintHex: buttonTintHex,
                isPlaying: existing.content.state.isPlaying
            )
            await existing.update(content)
            return
        }

        let content = makeContent(
            for: television, state: state, quickAction: quickAction,
            launcherApps: launcherApps, buttonTintHex: buttonTintHex,
            isPlaying: false
        )
        do {
            _ = try Activity.request(
                attributes: RemoteActivityAttributes(televisionName: television.name),
                content: content
            )
        } catch {
            AppLog.network.error("Live Activity indisponible : \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Refreshes only an activity that is already active. This deliberately never
    /// recreates one after the user dismisses it while the app remains in background.
    func update(
        for television: SamsungTV,
        state: ConnectionState,
        quickAction: LiveActivityQuickAction,
        launcherApps: [LiveActivityApp],
        buttonTintHex: String = "283447"
    ) {
        enqueue { manager in
            await manager.performUpdate(
                for: television, state: state, quickAction: quickAction,
                launcherApps: launcherApps, buttonTintHex: buttonTintHex
            )
        }
    }

    private func performUpdate(
        for television: SamsungTV,
        state: ConnectionState,
        quickAction: LiveActivityQuickAction,
        launcherApps: [LiveActivityApp],
        buttonTintHex: String
    ) async {
        let allActivities = Activity<RemoteActivityAttributes>.activities.filter {
            $0.activityState != .dismissed
        }
        guard let existing = allActivities.first(where: {
            $0.content.state.televisionName == television.name
        }) ?? allActivities.first else {
            return
        }

        for duplicate in allActivities where duplicate.id != existing.id {
            await duplicate.end(nil, dismissalPolicy: .immediate)
        }
        await existing.update(makeContent(
            for: television, state: state, quickAction: quickAction,
            launcherApps: launcherApps, buttonTintHex: buttonTintHex,
            isPlaying: existing.content.state.isPlaying
        ))
    }

    /// Ends every activity of this type, not just the one cached in this view.
    /// Used when the user turns the setting off and when an opt-out is detected on launch.
    func endAll() {
        enqueue { manager in await manager.performEndAll() }
    }

    private func performEndAll() async {
        let allActivities = Activity<RemoteActivityAttributes>.activities.filter {
            $0.activityState != .dismissed
        }
        for existing in allActivities {
            await existing.end(nil, dismissalPolicy: .immediate)
        }
    }

    private func makeContent(
        for television: SamsungTV,
        state: ConnectionState,
        quickAction: LiveActivityQuickAction,
        launcherApps: [LiveActivityApp],
        buttonTintHex: String,
        isPlaying: Bool
    ) -> ActivityContent<RemoteActivityAttributes.ContentState> {
        ActivityContent(
            state: RemoteActivityAttributes.ContentState(
                connectionLabel: state.title,
                televisionName: television.name,
                quickAction: quickAction,
                launcherApps: Array(launcherApps.prefix(5)),
                isPlaying: isPlaying,
                buttonTintHex: buttonTintHex
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
