import Combine
import Foundation

@MainActor
final class TVStore: ObservableObject {
    @Published private(set) var televisions: [SamsungTV] = []
    @Published private(set) var selectedID: UUID?
    @Published var preferences = RemotePreferences() { didSet { savePreferences() } }
    @Published var favoriteApps: [RemoteApplication] = [] { didSet { saveFavorites() } }
    @Published private(set) var customAppIcons: [String: Data] = [:] { didSet { saveCustomAppIcons() } }
    @Published private(set) var tvAppIcons: [String: Data] = [:] { didSet { saveTVAppIcons() } }
    private let defaults: UserDefaults
    private enum Key { static let televisions = "televisions"; static let selected = "selectedTV"; static let preferences = "preferences"; static let favorites = "favoriteApps"; static let customAppIcons = "customAppIcons"; static let tvAppIcons = "tvAppIcons" }

    // Standard storage avoids the App Groups entitlement so a free Apple ID can re-sign the app.
    // Widgets deliberately do not read this private app container in the Sideloadly edition.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        televisions = Self.decode([SamsungTV].self, key: Key.televisions, defaults: defaults) ?? []
        selectedID = defaults.string(forKey: Key.selected).flatMap(UUID.init(uuidString:))
        preferences = Self.decode(RemotePreferences.self, key: Key.preferences, defaults: defaults) ?? RemotePreferences()
        favoriteApps = Self.decode([RemoteApplication].self, key: Key.favorites, defaults: defaults) ?? []
        customAppIcons = Self.decode([String: Data].self, key: Key.customAppIcons, defaults: defaults) ?? [:]
        tvAppIcons = Self.decode([String: Data].self, key: Key.tvAppIcons, defaults: defaults) ?? [:]
        // Migrate legacy icons from favorites. Known generated fallback icons are not treated as user customizations.
        for app in favoriteApps where customAppIcons[app.id] == nil {
            if let data = app.customIconData {
                if let fallback = AppLogoCatalog.iconData(forAppName: app.name), data == fallback {
                    tvAppIcons[app.id] = tvAppIcons[app.id] ?? data
                } else {
                    customAppIcons[app.id] = data
                }
            }
        }
        // Older versions saved generated fallback artwork in the custom-icon dictionary.
        let legacyFallbackIDs = customAppIcons.compactMap { appID, data -> String? in
            guard let app = favoriteApps.first(where: { $0.id == appID }),
                  let fallback = AppLogoCatalog.iconData(forAppName: app.name), data == fallback else { return nil }
            return appID
        }
        for appID in legacyFallbackIDs {
            if let data = customAppIcons.removeValue(forKey: appID) {
                tvAppIcons[appID] = tvAppIcons[appID] ?? data
            }
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

    /// Display priority: user-selected artwork, TV-provided artwork, then offline fallback.
    func logoData(for appID: String, appName: String? = nil) -> Data? {
        if let custom = customAppIcons[appID] { return custom }
        if let tvIcon = tvAppIcons[appID] { return tvIcon }
        if let legacy = favoriteApps.first(where: { $0.id == appID })?.customIconData {
            if let name = appName ?? favoriteApps.first(where: { $0.id == appID })?.name,
               AppLogoCatalog.iconData(forAppName: name) == legacy { return legacy }
            return legacy
        }
        if let name = appName ?? favoriteApps.first(where: { $0.id == appID })?.name {
            return AppLogoCatalog.iconData(forAppName: name)
        }
        return nil
    }

    func customIconData(for appID: String) -> Data? { customAppIcons[appID] }
    func hasCustomLogo(for appID: String) -> Bool { customAppIcons[appID] != nil }
    func hasStoredLogo(for appID: String) -> Bool { customAppIcons[appID] != nil || tvAppIcons[appID] != nil }
    func setTVIcon(_ data: Data, for appID: String) { tvAppIcons[appID] = data }

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
    private func saveTVAppIcons() { defaults.set(try? JSONEncoder().encode(tvAppIcons), forKey: Key.tvAppIcons) }
    private static func decode<T: Decodable>(_ type: T.Type, key: String, defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
