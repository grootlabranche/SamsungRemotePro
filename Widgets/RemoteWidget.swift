import AppIntents
import Foundation
import SwiftUI
import WidgetKit

struct RemoteWidgetEntry: TimelineEntry {
    let date: Date
    let televisionName: String
}

struct RemoteWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> RemoteWidgetEntry { .init(date: .now, televisionName: "Télécommande Samsung") }
    func getSnapshot(in context: Context, completion: @escaping (RemoteWidgetEntry) -> Void) { completion(entry()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<RemoteWidgetEntry>) -> Void) {
        completion(Timeline(entries: [entry()], policy: .never))
    }

    private func entry() -> RemoteWidgetEntry { .init(date: .now, televisionName: "Télécommande Samsung") }
}

struct RemoteWidget: Widget {
    let kind = "SamsungRemoteWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RemoteWidgetProvider()) { entry in
            RemoteWidgetView(entry: entry)
        }
        .configurationDisplayName("Samsung Remote Pro")
        .description("Ouvrez rapidement la télécommande.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct RemoteWidgetView: View {
    let entry: RemoteWidgetEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "tv.fill").foregroundStyle(.blue)
                Text(entry.televisionName).lineLimit(1).font(.headline)
            }
            Spacer()
            Button(intent: OpenRemoteIntent()) {
                Label("Ouvrir", systemImage: "rectangle.inset.filled")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .containerBackground(.black, for: .widget)
    }
}
