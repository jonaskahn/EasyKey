@testable import EasyEngineCore
import XCTest

final class SettingsImporterTests: XCTestCase {
    func testImportValidPlistMapsKnownKeys() throws {
        let plist: [String: Any] = [
            "InputMethod": 1,
            "Encoding": 3,
            "ModernOrthography": false,
            "QuickTelex": true,
            "RestoreKeyIfInvalid": false,
            "RunOnStartup": true,
            "GrayIcon": true,
            "MacroEnabled": true,
            "SmartSwitchEnabled": true,
            "CheckForUpdates": false,
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        let result = try SettingsImporter.importFromPlistData(data)

        XCTAssertEqual(result.settings.input.inputMethod, .vni)
        XCTAssertEqual(result.settings.input.encoding, .vniWindows)
        XCTAssertFalse(result.settings.typing.spellingModernization)
        XCTAssertTrue(result.settings.typing.quickTelex)
        XCTAssertFalse(result.settings.typing.restoreInvalidWord)
        XCTAssertTrue(result.settings.system.launchAtLogin)
        XCTAssertTrue(result.settings.system.grayMenuIcon)
        XCTAssertTrue(result.settings.macro.enabled)
        XCTAssertTrue(result.settings.smartSwitch.enabled)
        XCTAssertFalse(result.settings.system.checkForUpdates)
    }

    func testImportMissingKeysDefaultSafely() throws {
        let plist: [String: Any] = [:]
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        let result = try SettingsImporter.importFromPlistData(data)

        XCTAssertEqual(result.settings, .defaults)
        XCTAssertTrue(result.entries.contains { $0.key == "InputMethod" })
        XCTAssertTrue(result.entries.contains { $0.key == "Encoding" })
    }

    func testImportUnknownInputMethodFallsToDefault() throws {
        let plist: [String: Any] = ["InputMethod": 99]
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        let result = try SettingsImporter.importFromPlistData(data)

        XCTAssertEqual(result.settings.input.inputMethod, .telex)
    }

    func testImportUnknownEncodingFallsToDefault() throws {
        let plist: [String: Any] = ["Encoding": 99]
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        let result = try SettingsImporter.importFromPlistData(data)

        XCTAssertEqual(result.settings.input.encoding, .unicode)
    }

    func testImportUnmappedKeysReportedAsSkipped() throws {
        let plist: [String: Any] = [
            "InputMethod": 0,
            "SomeCustomKey": "value",
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        let result = try SettingsImporter.importFromPlistData(data)

        XCTAssertTrue(result.entries.contains { $0.key == "SomeCustomKey" })
    }

    func testImportFromPlistData_TooLarge_Throws() {
        let oversized = Data(repeating: 0, count: SettingsImporter.maxPlistFileBytes + 1)
        XCTAssertThrowsError(try SettingsImporter.importFromPlistData(oversized)) { error in
            XCTAssertEqual(error as? SettingsImporterError, .fileTooLarge)
        }
    }

    func testImportFromPlistAt_TooLarge_Throws() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fileURL = tempDir.appendingPathComponent("huge.plist")
        try Data(repeating: 0, count: SettingsImporter.maxPlistFileBytes + 1).write(to: fileURL)
        XCTAssertThrowsError(try SettingsImporter.import(fromPlistAt: fileURL)) { error in
            XCTAssertEqual(error as? SettingsImporterError, .fileTooLarge)
        }
    }

    func testImportFromPlistData_NotADictionary_Throws() throws {
        let data = try PropertyListSerialization.data(fromPropertyList: ["a", "b"], format: .xml, options: 0)
        XCTAssertThrowsError(try SettingsImporter.importFromPlistData(data)) { error in
            XCTAssertEqual(error as? SettingsImporterError, .notADictionary)
        }
    }

    func testImportFromPlistFile() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let plist: [String: Any] = ["InputMethod": 2, "Encoding": 4]
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        let fileURL = tempDir.appendingPathComponent("settings.plist")
        try data.write(to: fileURL)

        let result = try SettingsImporter.import(fromPlistAt: fileURL)
        XCTAssertEqual(result.settings.input.inputMethod, .simpleTelex)
        XCTAssertEqual(result.settings.input.encoding, .cp1258)
    }

    func testImportInvalidPlistThrows() {
        let data = Data("not a plist".utf8)
        XCTAssertThrowsError(try SettingsImporter.importFromPlistData(data))
    }

    func testImportNonDictionaryPlistThrows() throws {
        let data = try PropertyListSerialization.data(fromPropertyList: ["a", "b"], format: .xml, options: 0)
        XCTAssertThrowsError(try SettingsImporter.importFromPlistData(data))
    }
}
