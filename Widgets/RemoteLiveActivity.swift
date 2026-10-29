import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

struct RemoteLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RemoteActivityAttributes.self) { context in
            let action = context.state.quickAction ?? .playPause
            let apps = context.state.launcherApps ?? []
            let actionTitle = displayTitle(action, isPlaying: context.state.isPlaying)
            let actionSymbol = displaySymbol(action, isPlaying: context.state.isPlaying)
            let tint = Color(hexRGB: context.state.buttonTintHex)
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "tv.fill").foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.televisionName).font(.headline).lineLimit(1)
                        Text(context.state.connectionLabel).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    actionControl(action) {
                        Image(systemName: actionSymbol)
                            .font(.title3.weight(.semibold))
                            .frame(width: 40, height: 40)
                            .background(tint.opacity(0.82), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(actionTitle)
                }
                if !apps.isEmpty {
                    HStack(spacing: 12) {
                        ForEach(apps.prefix(5)) { app in
                            Button(intent: applicationIntent(app)) {
                                VStack(spacing: 4) {
                                    LiveActivityAppBadge(app: app, size: 36)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Lancer \(app.name) sur le téléviseur")
                        }
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .activityBackgroundTint(.black)
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let action = context.state.quickAction ?? .playPause
            let apps = context.state.launcherApps ?? []
            let actionTitle = displayTitle(action, isPlaying: context.state.isPlaying)
            let actionSymbol = displaySymbol(action, isPlaying: context.state.isPlaying)
            let tint = Color(hexRGB: context.state.buttonTintHex)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "tv.fill").foregroundStyle(.blue)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.televisionName).lineLimit(1)
                        Text(context.state.connectionLabel).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    actionControl(action) {
                        Image(systemName: actionSymbol)
                            .font(.title3.weight(.semibold))
                            .frame(width: 36, height: 36)
                            .background(tint.opacity(0.82), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(actionTitle)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 10) {
                        actionControl(action) {
                            Label(actionTitle, systemImage: actionSymbol)
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(tint.opacity(0.82), in: Capsule())
                        }
                        .buttonStyle(.plain)
                        if !apps.isEmpty {
                            HStack(spacing: 8) {
                                ForEach(apps.prefix(5)) { app in
                                    Button(intent: applicationIntent(app)) {
                                        VStack(spacing: 4) {
                                            LiveActivityAppBadge(app: app, size: 30)
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Lancer \(app.name)")
                                }
                            }
                        } else {
                            Text("Ajoutez jusqu’à cinq apps dans Applications")
                                .font(.caption2).foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: "tv.fill")
            } compactTrailing: {
                actionControl(action) {
                    Image(systemName: actionSymbol)
                }
                .buttonStyle(.plain)
            } minimal: {
                actionControl(action) {
                    Image(systemName: "tv")
                }
                .buttonStyle(.plain)
            }
            .widgetURL(URL(string: "samsungremotepro://remote"))
            .keylineTint(.blue)
        }
    }

    @ViewBuilder
    private func actionControl<Label: View>(
        _ action: LiveActivityQuickAction,
        @ViewBuilder label: () -> Label
    ) -> some View {
        if action == .openRemote {
            Button(intent: OpenRemoteIntent(), label: label)
        } else {
            Button(intent: actionIntent(action), label: label)
        }
    }

    private func displayTitle(_ action: LiveActivityQuickAction, isPlaying: Bool) -> String {
        action == .playPause ? (isPlaying ? "Pause" : "Lecture") : action.title
    }

    private func displaySymbol(_ action: LiveActivityQuickAction, isPlaying: Bool) -> String {
        action == .playPause ? (isPlaying ? "pause.fill" : "play.fill") : action.systemImage
    }

    private func actionIntent(_ action: LiveActivityQuickAction) -> RemoteActivityActionIntent {
        RemoteActivityActionIntent(actionRawValue: action.rawValue)
    }

    private func applicationIntent(_ app: LiveActivityApp) -> RemoteActivityActionIntent {
        RemoteActivityActionIntent(actionRawValue: "launchApplication", appID: app.id)
    }
}

private struct LiveActivityAppBadge: View {
    let app: LiveActivityApp
    let size: CGFloat

    private var acronym: String {
        let value = (app.id + " " + app.name).lowercased()
        if value.contains("apple-music") || value.contains("apple music") || value.contains("music") { return "AM" }
        if value.contains("youtube") { return "YT" }
        if value.contains("disney") { return "D+" }
        if value.contains("prime") { return "PV" }
        if value.contains("netflix") { return "N" }
        if value.contains("spotify") { return "SP" }
        if value.contains("plex") { return "PX" }
        let words = app.name.split { !$0.isLetter && !$0.isNumber }
        if words.count >= 2 { return String(words.prefix(2).compactMap(\.first).map { $0.uppercased() }.joined().prefix(3)) }
        return String(app.name.filter { $0.isLetter || $0.isNumber }.prefix(2)).uppercased().ifEmpty("TV")
    }

    private var badgeColor: Color {
        let value = (app.id + " " + app.name).lowercased()
        if value.contains("apple-music") || value.contains("apple music") || value.contains("music") { return Color(hexRGB: "FA243C") }
        if value.contains("youtube") { return Color(hexRGB: "FF0033") }
        if value.contains("disney") { return Color(hexRGB: "113CCF") }
        if value.contains("prime") { return Color(hexRGB: "00A8E0") }
        if value.contains("netflix") { return Color(hexRGB: "E50914") }
        if value.contains("spotify") { return Color(hexRGB: "1DB954") }
        if value.contains("plex") { return Color(hexRGB: "E5A00D") }
        // Deterministic color from the app identifier, with no image or logo payload.
        let palette = ["6C5CE7", "008F95", "C44569", "4C6FFF", "A35DCC", "287D55"]
        let index = abs(app.id.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0x7fffffff }) % palette.count
        return Color(hexRGB: palette[index])
    }

    var body: some View {
        Text(acronym)
            .font(.system(size: size * 0.36, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(badgeColor, in: RoundedRectangle(cornerRadius: size * 0.25, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: size * 0.25, style: .continuous).stroke(.white.opacity(0.18), lineWidth: 1))
            .accessibilityLabel(app.name)
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String { isEmpty ? fallback : self }
}

private extension Color {
    init(hexRGB: String) {
        let cleaned = hexRGB.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        let value = UInt64(cleaned, radix: 16) ?? 0x283447
        self.init(.sRGB, red: Double((value >> 16) & 0xFF) / 255.0,
                  green: Double((value >> 8) & 0xFF) / 255.0,
                  blue: Double(value & 0xFF) / 255.0, opacity: 1)
    }
}
