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
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "tv.fill").foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.televisionName).font(.headline).lineLimit(1)
                        Text(context.state.connectionLabel).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Link(destination: actionURL(action)) {
                        Image(systemName: action.systemImage)
                            .font(.title3.weight(.semibold))
                            .frame(width: 40, height: 40)
                            .background(.white.opacity(0.10), in: Circle())
                    }
                    .accessibilityLabel(action.title)
                }
                if !apps.isEmpty {
                    HStack(spacing: 12) {
                        ForEach(apps.prefix(5)) { app in
                            Link(destination: applicationURL(app)) {
                                VStack(spacing: 4) {
                                    LiveActivityAppIcon(app: app, size: 32)
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
            DynamicIsland {
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
                    Link(destination: actionURL(action)) {
                        Image(systemName: action.systemImage)
                            .font(.title3.weight(.semibold))
                            .frame(width: 36, height: 36)
                    }
                    .accessibilityLabel(action.title)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 10) {
                        Link(destination: actionURL(action)) {
                            Label(action.title, systemImage: action.systemImage)
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.white.opacity(0.10), in: Capsule())
                        }
                        if !apps.isEmpty {
                            HStack(spacing: 8) {
                                ForEach(apps.prefix(5)) { app in
                                    Link(destination: applicationURL(app)) {
                                        VStack(spacing: 4) {
                                            LiveActivityAppIcon(app: app, size: 27)
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
                Image(systemName: action.systemImage)
            } minimal: {
                Image(systemName: "tv")
            }
            .widgetURL(URL(string: "samsungremotepro://remote"))
            .keylineTint(.blue)
        }
    }

    private func actionURL(_ action: LiveActivityQuickAction) -> URL {
        var components = URLComponents()
        components.scheme = "samsungremotepro"
        components.host = "remote"
        components.queryItems = [URLQueryItem(name: "action", value: action.rawValue)]
        return components.url ?? URL(string: "samsungremotepro://remote")!
    }

    private func applicationURL(_ app: LiveActivityApp) -> URL {
        var components = URLComponents()
        components.scheme = "samsungremotepro"
        components.host = "remote"
        components.queryItems = [URLQueryItem(name: "launchApp", value: app.id)]
        return components.url ?? URL(string: "samsungremotepro://remote")!
    }
}

private struct LiveActivityAppIcon: View {
    let app: LiveActivityApp
    let size: CGFloat

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
        .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
    }
}
