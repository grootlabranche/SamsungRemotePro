import Combine
import Foundation

@MainActor
final class TVStore: ObservableObject {
    @Published private(set) var televisions: [SamsungTV] = []
    @Published private(set) var selectedID: UUID?
    @Published var preferences = RemotePreferences() { didSet { savePreferences() } }
    @Published var favoriteApps: [RemoteApplication] = [] { didSet { saveFavorites() } }
    @Published private(set) var customAppIcons: [String: Data] = [:] { didSet { saveCustomAppIcons() } }
    private let defaults: UserDefaults
    private enum Key { static let televisions = "televisions"; static let selected = "selectedTV"; static let preferences = "preferences"; static let favorites = "favoriteApps"; static let customAppIcons = "customAppIcons" }

    // Standard storage avoids the App Groups entitlement so a free Apple ID can re-sign the app.
    // Widgets deliberately do not read this private app container in the Sideloadly edition.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        televisions = Self.decode([SamsungTV].self, key: Key.televisions, defaults: defaults) ?? []
        selectedID = defaults.string(forKey: Key.selected).flatMap(UUID.init(uuidString:))
        preferences = Self.decode(RemotePreferences.self, key: Key.preferences, defaults: defaults) ?? RemotePreferences()
        favoriteApps = Self.decode([RemoteApplication].self, key: Key.favorites, defaults: defaults) ?? []
        customAppIcons = Self.decode([String: Data].self, key: Key.customAppIcons, defaults: defaults) ?? [:]
        // Migrate icons stored on favorites in earlier versions into the app-ID keyed icon library.
        for app in favoriteApps where customAppIcons[app.id] == nil {
            if let data = app.customIconData { customAppIcons[app.id] = data }
        }
    }

    var selectedTelevision: SamsungTV? { televisions.first { $0.id == selectedID } }

    func save(_ television: SamsungTV, select: Bool = true) {
        if let index = televisions.firstIndex(where: { $0.id == television.id || $0.host == television.host }) { televisions[index] = television }
        else { televisions.append(television) }
        if select { selectedID = television.id }
        persist()
    }

    func select(_ television: SamsungTV) { selectedID = television.id; persist() }

    func logoData(for appID: String) -> Data? {
        customAppIcons[appID] ?? favoriteApps.first(where: { $0.id == appID })?.customIconData
    }

    func setCustomIcon(_ data: Data?, for appID: String) {
        customAppIcons[appID] = data
        var updatedFavorites = favoriteApps
        for index in updatedFavorites.indices where updatedFavorites[index].id == appID {
            updatedFavorites[index].customIconData = data
        }
        if updatedFavorites != favoriteApps { favoriteApps = updatedFavorites }
    }

    func remove(_ television: SamsungTV) {
        televisions.removeAll { $0.id == television.id }
        if selectedID == television.id { selectedID = televisions.first?.id }
        KeychainStore.removeToken(for: television)
        persist()
    }

    private func persist() {
        defaults.set(try? JSONEncoder().encode(televisions), forKey: Key.televisions)
        defaults.set(selectedID?.uuidString, forKey: Key.selected)
    }
    private func savePreferences() { defaults.set(try? JSONEncoder().encode(preferences), forKey: Key.preferences) }
    private func saveFavorites() { defaults.set(try? JSONEncoder().encode(favoriteApps), forKey: Key.favorites) }
    private func saveCustomAppIcons() { defaults.set(try? JSONEncoder().encode(customAppIcons), forKey: Key.customAppIcons) }
    private static func decode<T: Decodable>(_ type: T.Type, key: String, defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
