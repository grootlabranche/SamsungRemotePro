import ActivityKit
import Foundation

struct RemoteActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var connectionLabel: String
        var televisionName: String
    }

    var televisionName: String
}
