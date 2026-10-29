import SwiftUI
import UIKit

struct RemoteControlView: View {
    @EnvironmentObject private var store: TVStore
    @EnvironmentObject private var service: SamsungTVService
    @Environment(\.scenePhase) private var scenePhase
    @Binding var showingPicker: Bool
    @State private var showingApps = false
    @State private var showingSettings = false
    @State private var showingDiagnostics = false
    @StateObject private var liveActivity = LiveActivityManager()
    @StateObject private var hardwareVolumeButtons = HardwareVolumeButtonBridge()

    private var television: SamsungTV? { store.selectedTelevision }
    private var liveActivityApps: [LiveActivityApp] {
        store.favoriteApps.prefix(5).map {
            LiveActivityApp(id: $0.id, name: $0.name, deepLink: $0.deepLink, customIconData: compactLiveActivityIcon(store.logoData(for: $0.id)))
        }
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let padDiameter = min(350, max(220, min(geometry.size.width - 40, geometry.size.height * 0.43)))
                VStack(spacing: 13) {
                    header
                    Spacer(minLength: 0)
                    if store.preferences.navigationMode == .gestures {
                        TouchPad { send($0) }
                            .frame(width: padDiameter, height: padDiameter)
                            .overlay(Circle().stroke(.white.opacity(0.12), lineWidth: 1))
                    } else {
                        DirectionPad { send($0) }
                            .frame(width: min(270, padDiameter), height: min(270, padDiameter))
                    }
                    Spacer(minLength: 0)
                    navigationButtons
                    volumeControls
                    mediaControls
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 6)
                .background(Color.black.ignoresSafeArea())
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingApps) { NavigationStack { ApplicationsView() } }
            .sheet(isPresented: $showingSettings) { NavigationStack { SettingsView() } }
            .sheet(isPresented: $showingDiagnostics) { NavigationStack { DiagnosticView() } }
        }
        .task(id: service.connectionState.title) {
            // Connection changes may update an existing activity, but must not create
            // one: a dismissed activity is restored only when the app is opened/active.
            guard store.preferences.liveActivityEnabled, let television else { return }
            refreshExistingLiveActivity(for: television)
        }
        .onAppear {
            updateHardwareVolumeBridge()
            synchronizeLiveActivityForCurrentState()
            if let television,
               !service.connectionState.isConnected,
               store.preferences.reconnectAutomatically {
                service.connect(to: television)
            }
        }
        .onDisappear { hardwareVolumeButtons.stop() }
        .onChange(of: scenePhase) { _, newPhase in
            updateHardwareVolumeBridge()
            if newPhase == .active {
                // Returning to the foreground is an explicit recovery point. If the
                // user dismissed the activity, create exactly one replacement here.
                synchronizeLiveActivityForCurrentState()
                if let television,
                   !service.connectionState.isConnected,
                   store.preferences.reconnectAutomatically,
                   service.connectionState == .disconnected {
                    service.connect(to: television)
                }
            }
        }
        .onChange(of: store.preferences.liveActivityEnabled) { _, _ in
            synchronizeLiveActivityForCurrentState()
        }
        .onChange(of: store.preferences.useHardwareVolumeButtons) { _, _ in updateHardwareVolumeBridge() }
        .onChange(of: store.preferences.dynamicIslandAction) { _, _ in refreshLiveActivityIfPresent() }
        .onChange(of: store.preferences.shortcutButtonColorHex) { _, _ in refreshLiveActivityIfPresent() }
        .onChange(of: store.favoriteApps) { _, _ in refreshLiveActivityIfPresent() }
        .onChange(of: store.customAppIcons) { _, _ in refreshLiveActivityIfPresent() }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(television?.name ?? "Téléviseur")
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.tail)
                ConnectionBadge(state: service.connectionState)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            headerButton("antenna.radiowaves.left.and.right", label: "Diagnostic réseau") { showingDiagnostics = true }
            headerButton("rectangle.inset.filled.and.person.filled", label: "Choisir le téléviseur") { showingPicker = true }
            headerButton("gearshape", label: "Réglages") { showingSettings = true }
            headerButton("power", label: "Alimentation", tint: .red) { send(.power) }
        }
        .padding(.top, 2)
    }

    private func headerButton(_ symbol: String, label: String, tint: Color = .white, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(tint)
        }
        .buttonStyle(RemoteCircleButtonStyle(size: 42, fill: Color(hexRGB: store.preferences.shortcutButtonColorHex).opacity(0.82)))
        .accessibilityLabel(label)
    }

    /// The three utility buttons from the reference design; text input lives in the Apps sheet.
    private var navigationButtons: some View {
        HStack(spacing: 42) {
            remoteButton("arrow.uturn.backward", command: .back, label: "Retour", size: 54)
            remoteButton("house.fill", command: .home, label: "Accueil", size: 54)
            remoteButton("square.grid.2x2", action: { showingApps = true }, label: "Applications", size: 54)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
    }

    /// One combined vertical volume rocker and one mute button, so volume controls aren't duplicated.
    private var volumeControls: some View {
        HStack(spacing: 30) {
            remoteButton("speaker.slash.fill", command: .mute, label: "Sourdine", size: 56)
            VStack(spacing: 0) {
                Button { send(.volumeUp) } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .medium))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Augmenter le volume")
                Rectangle().fill(.white.opacity(0.23)).frame(height: 1)
                Button { send(.volumeDown) } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 22, weight: .medium))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Diminuer le volume")
            }
            .buttonStyle(.plain)
            .frame(width: 74, height: 108)
            .background(Color(hexRGB: store.preferences.shortcutButtonColorHex).opacity(0.82), in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 1))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 1)
    }

    /// Compact media player kept on the main page: previous, one play/pause action, next.
    private var mediaControls: some View {
        HStack(spacing: 48) {
            remoteButton("backward.end.fill", command: .rewind, label: "Retour rapide", size: 54)
            remoteButton("playpause.fill", command: .playPause, label: "Lecture ou pause", size: 58)
            remoteButton("forward.end.fill", command: .fastForward, label: "Avance rapide", size: 54)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 2)
    }

    private func remoteButton(_ icon: String, command: RemoteCommand, label: String, size: CGFloat = 46) -> some View {
        remoteButton(icon, action: { send(command) }, label: label, size: size)
    }

    private func remoteButton(_ icon: String, action: @escaping () -> Void, label: String, size: CGFloat = 46) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 20, weight: .semibold))
        }
        .buttonStyle(RemoteCircleButtonStyle(size: size, fill: Color(hexRGB: store.preferences.shortcutButtonColorHex).opacity(0.82)))
        .accessibilityLabel(label)
    }

    private func send(_ command: RemoteCommand) {
        Haptics.tap(enabled: store.preferences.hapticsEnabled)
        Task { await service.send(command) }
    }

    private func startOrRefreshLiveActivity(for television: SamsungTV) {
        liveActivity.start(
            for: television,
            state: service.connectionState,
            quickAction: store.preferences.dynamicIslandAction,
            launcherApps: liveActivityApps,
            buttonTintHex: store.preferences.shortcutButtonColorHex
        )
    }

    private func synchronizeLiveActivityForCurrentState() {
        guard store.preferences.liveActivityEnabled, let television else {
            // Also removes any activity left by an older build when the new opt-in
            // preference has its default value of false.
            liveActivity.endAll()
            return
        }
        startOrRefreshLiveActivity(for: television)
    }

    private func refreshLiveActivityIfPresent() {
        guard store.preferences.liveActivityEnabled, let television else { return }
        refreshExistingLiveActivity(for: television)
    }

    private func refreshExistingLiveActivity(for television: SamsungTV) {
        liveActivity.update(
            for: television, state: service.connectionState,
            quickAction: store.preferences.dynamicIslandAction, launcherApps: liveActivityApps,
            buttonTintHex: store.preferences.shortcutButtonColorHex
        )
    }

    /// ActivityKit state should stay small; 96 px is enough for the 27–32 pt launcher tiles.
    private func compactLiveActivityIcon(_ data: Data?) -> Data? {
        guard let data, let image = UIImage(data: data) else { return data }
        let size = CGSize(width: 96, height: 96)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }.pngData() ?? data
    }

    private func updateHardwareVolumeBridge() {
        guard store.preferences.useHardwareVolumeButtons, scenePhase == .active else {
            hardwareVolumeButtons.stop()
            return
        }
        hardwareVolumeButtons.onVolumeStep = { increase in
            send(increase ? .volumeUp : .volumeDown)
        }
        hardwareVolumeButtons.start()
    }
}

private struct ConnectionBadge: View {
    let state: ConnectionState
    var body: some View {
        Label(state.title, systemImage: state.isConnected ? "circle.fill" : "circle")
            .font(.caption2)
            .foregroundStyle(state.isConnected ? .green : .secondary)
            .lineLimit(1)
    }
}

struct RemoteCircleButtonStyle: ButtonStyle {
    var size: CGFloat
    var fill: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: size, height: size)
            .background(fill.opacity(configuration.isPressed ? 0.72 : 1), in: Circle())
            .overlay(Circle().stroke(.white.opacity(0.10), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
