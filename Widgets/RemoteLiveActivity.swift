import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

struct RemoteLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RemoteActivityAttributes.self) { context in
            HStack {
                Image(systemName: "tv.fill").foregroundStyle(.blue)
                VStack(alignment: .leading) {
                    Text(context.state.televisionName).font(.headline)
                    Text(context.state.connectionLabel).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button(intent: OpenRemoteIntent()) { Image(systemName: "rectangle.inset.filled") }
            }
            .padding(.horizontal)
            .activityBackgroundTint(.black)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) { Image(systemName: "tv.fill").foregroundStyle(.blue) }
                DynamicIslandExpandedRegion(.center) { Text(context.state.televisionName).lineLimit(1) }
                DynamicIslandExpandedRegion(.trailing) { Button(intent: OpenRemoteIntent()) { Image(systemName: "rectangle.inset.filled") } }
                DynamicIslandExpandedRegion(.bottom) { Text(context.state.connectionLabel).foregroundStyle(.secondary) }
            } compactLeading: {
                Image(systemName: "tv.fill")
            } compactTrailing: {
                Image(systemName: "dot.radiowaves.left.and.right")
            } minimal: {
                Image(systemName: "tv")
            }
            .widgetURL(URL(string: "samsungremotepro://remote"))
            .keylineTint(.blue)
        }
    }
}
