import XCTest
@testable import SamsungRemotePro

final class ModelsTests: XCTestCase {
    func testTelevisionRoundTripPreservesConnectionConfiguration() throws {
        let tv = SamsungTV(name: "Salon", host: "192.168.1.42", port: 8002, usesSecureWebSocket: true, model: "UE55RU7405")
        let decoded = try JSONDecoder().decode(SamsungTV.self, from: JSONEncoder().encode(tv))
        XCTAssertEqual(decoded, tv)
    }

    func testConnectionLabelsAreUserFacing() {
        XCTAssertEqual(ConnectionState.connected.title, "Connecté")
        XCTAssertFalse(ConnectionState.disconnected.isConnected)
        XCTAssertTrue(ConnectionState.connected.isConnected)
    }

    func testPreferencesHaveSafeDefaults() {
        let preferences = RemotePreferences()
        XCTAssertTrue(preferences.reconnectAutomatically)
        XCTAssertEqual(preferences.navigationMode, .gestures)
    }
}
