import SwiftUI
import WidgetKit

@main
struct SamsungRemoteProWidgets: WidgetBundle {
    var body: some Widget {
        RemoteWidget()
        RemoteLiveActivityWidget()
    }
}
