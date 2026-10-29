import SwiftUI

struct RemoteControlView: View {
    @EnvironmentObject private var store: TVStore
    @EnvironmentObject private var service: SamsungTVService
    @Binding var showingPicker: Bool
    @State private var showingApps = false
    @State private var showingKeyboard = false
    @State private var showingSettings = false
    @State private var showingDiagnostics = false
    @StateObject private var liveActivity = LiveActivityManager()

    private var television: SamsungTV? { store.selectedTelevision }
    private let mediaColumns = [GridItem(.adaptive(minimum: 66, maximum: 92), spacing: 12)]

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView(.vertical) {
                    VStack(spacing: 18) {
                        header
                        if store.preferences.navigationMode == .gestures {
                            TouchPad { send($0) }
                                .frame(width: min(geometry.size.width - 36, 340), height: min(geometry.size.width - 36, 340))
                                .frame(maxWidth: .infinity)
                        } else {
                            DirectionPad { send($0) }
                                .frame(width: min(geometry.size.width - 36, 280), height: min(geometry.size.width - 36, 280))
                                .frame(maxWidth: .infinity)
                        }
                        remoteControls
                        if store.preferences.showExtraCommands { mediaControls }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 22)
                    .frame(maxWidth: .infinity)
                }
                .background(Color.black.ignoresSafeArea())
                .scrollIndicators(.hidden)
            }
            .background(Color.black.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingApps) { NavigationStack { ApplicationsView() } }
            .sheet(isPresented: $showingKeyboard) { TextInputView() }
            .sheet(isPresented: $showingSettings) { NavigationStack { SettingsView() } }
            .sheet(isPresented: $showingDiagnostics) { NavigationStack { DiagnosticView() } }
        }
        .task(id: service.connectionState.title) {
            guard let television else { return }
            await liveActivity.update(for: television, state: service.connectionState)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Button { showingPicker = true } label: {
                VStack(alignment: .leading, spacing: 3) {
                    Text(displayName).font(.headline).lineLimit(1).minimumScaleFactor(0.75)
                    ConnectionBadge(state: service.connectionState)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Choisir un téléviseur")
            headerButton("antenna.radiowaves.left.and.right", label: "Diagnostic réseau") { showingDiagnostics = true }
            headerButton("rectangle.inset.filled.and.person.filled", label: "Activité en direct") {
                if let television { liveActivity.start(for: television, state: service.connectionState) }
            }
            headerButton("gearshape", label: "Réglages") { showingSettings = true }
            headerButton("power", label: "Alimentation") { send(.power) }
        }
        .padding(.vertical, 4)
    }

    private var displayName: String {
        guard let television else { return "Choisir une TV" }
        switch service.connectionState {
        case .connected: return television.name
        case .connecting, .discovering, .reconnecting: return television.host
        case .awaitingAuthorization: return television.host
        case .failed, .disconnected: return television.name == "Samsung TV" ? television.host : television.name
        }
    }

    private func headerButton(_ icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: icon).font(.system(size: 17, weight: .semibold)) }
            .buttonStyle(RemoteCircleButtonStyle(size: 40, fill: .white.opacity(0.12)))
            .accessibilityLabel(label)
    }

    private var remoteControls: some View {
        HStack(spacing: 0) {
            remoteButton("arrow.uturn.backward", command: .back, label: "Retour")
            Spacer(minLength: 8)
            remoteButton("house.fill", command: .home, label: "Accueil")
            Spacer(minLength: 8)
            remoteButton("keyboard", action: { showingKeyboard = true }, label: "Saisir du texte")
            Spacer(minLength: 8)
            remoteButton("square.grid.2x2", action: { showingApps = true }, label: "Applications")
        }
        .frame(maxWidth: 340)
        .frame(maxWidth: .infinity)
    }

    private var mediaControls: some View {
        LazyVGrid(columns: mediaColumns, spacing: 12) {
            remoteButton("speaker.wave.1", command: .volumeDown, label: "Diminuer le volume")
            remoteButton("speaker.slash", command: .mute, label: "Sourdine")
            remoteButton("speaker.wave.3", command: .volumeUp, label: "Augmenter le volume")
            remoteButton("backward.fill", command: .rewind, label: "Retour rapide")
            remoteButton("play.fill", command: .play, label: "Lecture")
            remoteButton("pause.fill", command: .pause, label: "Pause")
            remoteButton("forward.fill", command: .fastForward, label: "Avance rapide")
        }
        .frame(maxWidth: 340)
        .frame(maxWidth: .infinity)
    }

    private func remoteButton(_ icon: String, command: RemoteCommand, label: String) -> some View {
        remoteButton(icon, action: { send(command) }, label: label)
    }
    private func remoteButton(_ icon: String, action: @escaping () -> Void, label: String) -> some View {
        Button(action: action) { Image(systemName: icon).font(.system(size: 18, weight: .semibold)) }
            .buttonStyle(RemoteCircleButtonStyle(size: 46, fill: .white.opacity(0.12)))
            .accessibilityLabel(label)
    }
    private func send(_ command: RemoteCommand) {
        Haptics.tap(enabled: store.preferences.hapticsEnabled)
        Task { await service.send(command) }
    }
}

private struct ConnectionBadge: View {
    let state: ConnectionState
    var body: some View {
        Label(state.title, systemImage: state.isConnected ? "circle.fill" : "circle")
            .font(.caption2)
            .lineLimit(1)
            .foregroundStyle(state.isConnected ? .green : .secondary)
    }
}

struct RemoteCircleButtonStyle: ButtonStyle {
    var size: CGFloat
    var fill: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: size, height: size)
            .background(fill.opacity(configuration.isPressed ? 0.58 : 1), in: Circle())
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
