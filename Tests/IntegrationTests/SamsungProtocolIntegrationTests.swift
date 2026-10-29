import XCTest
@testable import SamsungRemotePro

/// Opt-in smoke test for a real TV. It never sends a key; pairing must be verified manually.
final class SamsungProtocolIntegrationTests: XCTestCase {
    func testConfiguredTelevisionIsReachable() async throws {
        guard let host = ProcessInfo.processInfo.environment["SAMSUNG_TV_HOST"], !host.isEmpty else {
            throw XCTSkip("Définissez SAMSUNG_TV_HOST sur le Mac de test pour exécuter le test sur une TV réelle.")
        }
        let discovery = SamsungDiscoveryService()
        let television = await discovery.probe(host: host)
        XCTAssertNotNil(television, "La TV ne répond pas à /api/v2/. Vérifiez qu’elle est sur le même réseau.")
    }
}
