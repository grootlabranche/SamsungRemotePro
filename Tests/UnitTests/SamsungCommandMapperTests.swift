import XCTest
@testable import SamsungRemotePro

final class SamsungCommandMapperTests: XCTestCase {
    func testVolumeUpEncodesDocumentedRemoteEnvelope() throws {
        let payload = try SamsungCommandMapper.payload(for: .volumeUp)
        XCTAssertEqual(payload["method"] as? String, "ms.remote.control")
        let params = try XCTUnwrap(payload["params"] as? [String: String])
        XCTAssertEqual(params["Cmd"], "Click")
        XCTAssertEqual(params["DataOfCmd"], "KEY_VOLUP")
        XCTAssertEqual(params["TypeOfRemote"], "SendRemoteKey")
    }

    func testLaunchApplicationPreservesCallerSuppliedIdentifier() throws {
        let app = RemoteApplication(id: "11101200001", name: "Test", deepLink: "content://example")
        let payload = try SamsungCommandMapper.payload(for: .launchApplication(app))
        let params = try XCTUnwrap(payload["params"] as? [String: Any])
        let data = try XCTUnwrap(params["data"] as? [String: String])
        XCTAssertEqual(params["event"] as? String, "ed.apps.launch")
        XCTAssertEqual(data["appId"], "11101200001")
        XCTAssertEqual(data["metaTag"], "content://example")
    }

    func testEmptyTextIsRejected() {
        XCTAssertThrowsError(try SamsungCommandMapper.payload(for: .typeText("   "))) { error in
            XCTAssertEqual(error as? RemoteError, .unsupportedCommand)
        }
    }

    func testEveryPayloadSerializesAsJSON() throws {
        let data = try SamsungCommandMapper.data(for: .home)
        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: data))
    }

    func testTextUsesTheDocumentedBase64Envelope() throws {
        let payload = try SamsungCommandMapper.payload(for: .typeText("été"))
        let params = try XCTUnwrap(payload["params"] as? [String: String])
        XCTAssertEqual(params["Cmd"], Data("été".utf8).base64EncodedString())
        XCTAssertEqual(params["DataOfCmd"], "base64")
        XCTAssertEqual(params["TypeOfRemote"], "SendInputString")
    }
}
