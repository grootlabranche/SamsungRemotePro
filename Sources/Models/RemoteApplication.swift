import Foundation

struct RemoteApplication: Codable, Identifiable, Equatable, Hashable, Sendable {
    let id: String
    var name: String
    var deepLink: String?
    var isFavorite: Bool

    init(id: String, name: String, deepLink: String? = nil, isFavorite: Bool = false) {
        self.id = id
        self.name = name
        self.deepLink = deepLink
        self.isFavorite = isFavorite
    }
}
