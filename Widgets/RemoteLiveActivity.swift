import ActivityKit
import AppIntents
import SwiftUI
import UIKit
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
                                    LiveActivityAppIcon(app: app, size: 32, tint: tint)
                                    Text(app.name).font(.system(size: 10)).lineLimit(1).frame(maxWidth: 56)
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
                                            LiveActivityAppIcon(app: app, size: 27, tint: tint)
                                            Text(app.name)
                                                .font(.system(size: 9, weight: .medium))
                                                .lineLimit(1)
                                                .frame(maxWidth: 54)
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

private struct LiveActivityAppIcon: View {
    let app: LiveActivityApp
    let size: CGFloat
    var tint: Color = Color(hexRGB: "283447")

    var body: some View {
        Group {
            if let data = app.customIconData, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Image(systemName: "app.fill")
                    .font(.system(size: size * 0.48, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .background(tint.opacity(0.82), in: RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
    }
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
