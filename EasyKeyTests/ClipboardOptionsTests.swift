@testable import EasyEngineCore
import XCTest

final class ClipboardOptionsTests: XCTestCase {
    func testDefaultsMatchApprovedProductDecisions() {
        let options = ClipboardOptions()
        XCTAssertFalse(options.isCaptureEnabled)
        XCTAssertEqual(options.shortcut, Shortcut(keyCode: 9, modifiers: [.option]))
        XCTAssertEqual(options.selectionAction, .pasteImmediately)
        XCTAssertEqual(options.maximumEntryCount, 100)
        XCTAssertEqual(options.retentionDays, 7)
        XCTAssertFalse(options.persistsHistory)
        XCTAssertEqual(options.capturedKinds, [.text, .url, .image, .file, .video])
        XCTAssertTrue(options.ignoredApplicationBundleIdentifiers.isEmpty)
    }

    func testCapturesRespectsFilterButAlwaysAllowsMixed() {
        var options = ClipboardOptions()
        options.capturedKinds = [.text]
        XCTAssertTrue(options.captures(.text))
        XCTAssertFalse(options.captures(.image))
        XCTAssertTrue(options.captures(.mixed))
    }

    func testOptionsRoundTripThroughJSON() throws {
        let options = ClipboardOptions(
            isCaptureEnabled: true,
            selectionAction: .copyOnly,
            maximumEntryCount: 42,
            retentionDays: 3,
            persistsHistory: true,
            capturedKinds: [.text, .image],
            ignoredApplicationBundleIdentifiers: ["com.example.secret"]
        )
        let data = try JSONEncoder().encode(options)
        let decoded = try JSONDecoder().decode(ClipboardOptions.self, from: data)
        XCTAssertEqual(options, decoded)
    }

    func testRepresentationRoundTripPreservesEachCase() throws {
        let cases: [ClipboardRepresentation] = [
            .string(typeIdentifier: "public.utf8-plain-text", value: "hello"),
            .data(typeIdentifier: "public.png", payloadReference: "ref-1"),
            .fileURL(URL(fileURLWithPath: "/tmp/movie.mp4")),
        ]
        for representation in cases {
            let data = try JSONEncoder().encode(representation)
            let decoded = try JSONDecoder().decode(ClipboardRepresentation.self, from: data)
            XCTAssertEqual(representation, decoded)
        }
    }

    func testLegacySettingsWithoutClipboardKeyDecodeWithDefaults() throws {
        let legacyData = try legacySettingsDataWithoutClipboard(schemaVersion: 3)
        let decoded = try JSONDecoder().decode(EasyKeySettings.self, from: legacyData)

        XCTAssertEqual(decoded.clipboard, ClipboardOptions())
        XCTAssertEqual(decoded.input, EasyKeySettings.defaults.input)
        XCTAssertEqual(decoded.typing, EasyKeySettings.defaults.typing)
        XCTAssertEqual(decoded.converter, EasyKeySettings.defaults.converter)
        XCTAssertEqual(decoded.schemaVersion, 3)
    }

    func testMissingRootFieldsFallBackToDefaultsInsteadOfFailing() throws {
        let sparse = Data("{\"schemaVersion\": 3}".utf8)
        let decoded = try JSONDecoder().decode(EasyKeySettings.self, from: sparse)
        XCTAssertEqual(decoded.input, EasyKeySettings.defaults.input)
        XCTAssertEqual(decoded.clipboard, ClipboardOptions())
    }

    func testCurrentSchemaVersionIsSeven() {
        XCTAssertEqual(EasyKeySettings.currentSchemaVersion, 9)
    }

    private func legacySettingsDataWithoutClipboard(schemaVersion: Int) throws -> Data {
        let data = try JSONEncoder().encode(EasyKeySettings.defaults)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object.removeValue(forKey: "clipboard")
        object["schemaVersion"] = schemaVersion
        return try JSONSerialization.data(withJSONObject: object)
    }
}
