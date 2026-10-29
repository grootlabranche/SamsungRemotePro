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

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                header
                Spacer(minLength: 0)
                if store.preferences.navigationMode == .gestures {
                    TouchPad { send($0) }
                        .frame(maxWidth: 340, maxHeight: 340)
                        .aspectRatio(1, contentMode: .fit)
                } else {
                    DirectionPad { send($0) }
                        .frame(width: 270, height: 270)
                }
                remoteControls
                if store.preferences.showExtraCommands { mediaControls }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .background(Color.black.ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(isPresented: $showingApps) { NavigationStack { ApplicationsView() } }
            .sheet(isPresented: $showingKeyboard) { TextInputView() }
            .sheet(isPresented: $showingSettings) { NavigationStack { SettingsView() } }
            .sheet(isPresented: $showingDiagnostics) { NavigationStack { DiagnosticView() } }
        }
        .task(id: service.connectionState.title) {
            guard let television else { return }
            // The activity is a convenience surface, not a persistent network session.
            await liveActivity.update(for: television, state: service.connectionState)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button { showingPicker = true } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(television?.name ?? "Téléviseur").font(.headline).lineLimit(1)
                    ConnectionBadge(state: service.connectionState)
                }
            }
            .accessibilityLabel("Choisir un téléviseur")
            Spacer()
            Button { showingDiagnostics = true } label: { Image(systemName: "antenna.radiowaves.left.and.right") }
            Button {
                if let television { liveActivity.start(for: television, state: service.connectionState) }
            } label: { Image(systemName: "rectangle.inset.filled.and.person.filled") }
                .accessibilityLabel("Afficher l’activité en direct")
            Button { showingSettings = true } label: { Image(systemName: "gearshape") }
            Button { send(.power) } label: { Image(systemName: "power") }
                .tint(.red)
        }
        .font(.title3)
        .buttonStyle(RemoteCircleButtonStyle(size: 42, fill: .white.opacity(0.12)))
        .padding(.top, 8)
    }

    private var remoteControls: some View {
        HStack(spacing: 22) {
            remoteButton("arrow.uturn.backward", command: .back, label: "Retour")
            remoteButton("house.fill", command: .home, label: "Accueil")
            remoteButton("keyboard", action: { showingKeyboard = true }, label: "Saisir du texte")
            remoteButton("square.grid.2x2", action: { showingApps = true }, label: "Applications")
        }
    }

    private var mediaControls: some View {
        HStack(spacing: 18) {
            remoteButton("speaker.wave.1", command: .volumeDown, label: "Diminuer le volume")
            remoteButton("speaker.slash", command: .mute, label: "Sourdine")
            remoteButton("speaker.wave.3", command: .volumeUp, label: "Augmenter le volume")
            remoteButton("backward.fill", command: .rewind, label: "Retour rapide")
            remoteButton("play.fill", command: .play, label: "Lecture")
            remoteButton("pause.fill", command: .pause, label: "Pause")
            remoteButton("forward.fill", command: .fastForward, label: "Avance rapide")
        }
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
