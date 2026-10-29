import Foundation
import SwiftUI
import UIKit

enum NavigationMode: String, CaseIterable, Codable, Identifiable {
    case gestures
    case directionalButtons
    var id: String { rawValue }
    var title: String { self == .gestures ? "Glissements" : "Boutons directionnels" }
}

struct RemotePreferences: Codable, Equatable {
    var reconnectAutomatically = true
    var hapticsEnabled = true
    var navigationMode: NavigationMode = .gestures
    /// Kept for backwards compatibility with settings saved by earlier versions.
    var showExtraCommands = true
    var dynamicIslandAction: LiveActivityQuickAction = .playPause
    /// Live Activities are opt-in. The remote remains fully functional when disabled.
    var liveActivityEnabled = false
    var useHardwareVolumeButtons = false
    /// Hex RGB color used for remote shortcut button backgrounds.
    var shortcutButtonColorHex = "283447"

    private enum CodingKeys: String, CodingKey {
        case reconnectAutomatically, hapticsEnabled, navigationMode, showExtraCommands
        case dynamicIslandAction, liveActivityEnabled, useHardwareVolumeButtons, shortcutButtonColorHex
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        reconnectAutomatically = try container.decodeIfPresent(Bool.self, forKey: .reconnectAutomatically) ?? true
        hapticsEnabled = try container.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? true
        navigationMode = try container.decodeIfPresent(NavigationMode.self, forKey: .navigationMode) ?? .gestures
        showExtraCommands = try container.decodeIfPresent(Bool.self, forKey: .showExtraCommands) ?? true
        dynamicIslandAction = try container.decodeIfPresent(LiveActivityQuickAction.self, forKey: .dynamicIslandAction) ?? .playPause
        liveActivityEnabled = try container.decodeIfPresent(Bool.self, forKey: .liveActivityEnabled) ?? false
        useHardwareVolumeButtons = try container.decodeIfPresent(Bool.self, forKey: .useHardwareVolumeButtons) ?? false
        shortcutButtonColorHex = try container.decodeIfPresent(String.self, forKey: .shortcutButtonColorHex) ?? "283447"
    }
}

/// Small, stable RGB hex bridge for saving a SwiftUI Color in UserDefaults.
extension Color {
    init(hexRGB: String) {
        let cleaned = hexRGB.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        let value = UInt64(cleaned, radix: 16) ?? 0x283447
        let red = Double((value >> 16) & 0xFF) / 255.0
        let green = Double((value >> 8) & 0xFF) / 255.0
        let blue = Double(value & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)
    }

    var rgbHexString: String {
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else { return "283447" }
        let red = Int((components[0] * 255).rounded())
        let green = Int((components[1] * 255).rounded())
        let blue = Int((components[2] * 255).rounded())
        return String(format: "%02X%02X%02X", red, green, blue)
    }
}
