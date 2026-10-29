import Foundation

struct RemoteApplication: Codable, Identifiable, Equatable, Hashable, Sendable {
    let id: String
    var name: String
    var deepLink: String?
    /// Optional icon URL reported by TV firmware; many models omit it.
    var iconURL: String?
    var isFavorite: Bool
    /// Small JPEG image selected by the user for this app's launcher tile.
    var customIconData: Data?

    init(
        id: String,
        name: String,
        deepLink: String? = nil,
        iconURL: String? = nil,
        isFavorite: Bool = false,
        customIconData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.deepLink = deepLink
        self.iconURL = iconURL
        self.isFavorite = isFavorite
        self.customIconData = customIconData
    }
}
