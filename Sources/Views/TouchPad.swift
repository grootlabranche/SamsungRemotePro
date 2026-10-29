import SwiftUI

struct TouchPad: View {
    let action: (RemoteCommand) -> Void
    @State private var isPressed = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Circle().fill(.white.opacity(isPressed ? 0.22 : 0.12))
                VStack(spacing: 8) {
                    Image(systemName: "hand.draw.fill").font(.system(size: 30, weight: .light))
                    Text("Touchez pour sélectionner\nGlissez pour naviguer")
                        .font(.caption).multilineTextAlignment(.center).foregroundStyle(.secondary)
                }
            }
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { _ in isPressed = true }
                    .onEnded { value in
                        isPressed = false
                        let translation = value.translation
                        guard max(abs(translation.width), abs(translation.height)) > 25 else { action(.select); return }
                        if abs(translation.width) > abs(translation.height) { action(translation.width > 0 ? .right : .left) }
                        else { action(translation.height > 0 ? .down : .up) }
                    }
            )
            .simultaneousGesture(TapGesture().onEnded { action(.select) })
            .frame(width: min(proxy.size.width, proxy.size.height), height: min(proxy.size.width, proxy.size.height))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Pavé tactile")
        .accessibilityHint("Touchez pour sélectionner ou glissez dans une direction")
    }
}

struct DirectionPad: View {
    let action: (RemoteCommand) -> Void
    var body: some View {
        ZStack {
            Circle().fill(.white.opacity(0.12))
            Button { action(.up) } label: { Image(systemName: "chevron.up") }.offset(y: -92)
            Button { action(.down) } label: { Image(systemName: "chevron.down") }.offset(y: 92)
            Button { action(.left) } label: { Image(systemName: "chevron.left") }.offset(x: -92)
            Button { action(.right) } label: { Image(systemName: "chevron.right") }.offset(x: 92)
            Button { action(.select) } label: { Image(systemName: "circle.fill") }.buttonStyle(.borderedProminent).tint(.white.opacity(0.25))
        }
        .font(.title2)
        .buttonStyle(RemoteCircleButtonStyle(size: 52, fill: .clear))
        .accessibilityElement(children: .contain)
    }
}
