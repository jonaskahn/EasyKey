@testable import EasyEngineCore
import XCTest

final class SmartSwitchStoreEdgeCaseTests: XCTestCase {
    func testHandleAppFocus_DisplayNameFallsBackToPath_WhenNameMissing() throws {
        let store = SmartSwitchStore()
        let app = ApplicationIdentity(bundleIdentifier: nil, path: "/Applications/Test.app", name: nil)
        _ = try store.handleAppFocus(app, currentChoice: SmartSwitchChoice(language: .vietnamese))

        XCTAssertEqual(store.preferences.first?.displayName, "/Applications/Test.app")
    }

    func testHandleAppFocus_DisplayNameFallsBackToBundleIdentifier_WhenNameAndPathMissing() throws {
        let store = SmartSwitchStore()
        let app = ApplicationIdentity(bundleIdentifier: "com.example.Test", path: nil, name: nil)
        _ = try store.handleAppFocus(app, currentChoice: SmartSwitchChoice(language: .vietnamese))

        XCTAssertEqual(store.preferences.first?.displayName, "com.example.Test")
    }

    func testClearAll() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let fileURL = directory.appendingPathComponent("smart-switch.json")
        let store = SmartSwitchStore(fileURL: fileURL)

        let app = ApplicationIdentity(bundleIdentifier: "com.example.Test", name: "Test")
        _ = try store.handleAppFocus(app, currentChoice: SmartSwitchChoice(language: .vietnamese), now: .distantPast)

        XCTAssertFalse(store.preferences.isEmpty)
        try store.clearAll()
        XCTAssertTrue(store.preferences.isEmpty)
    }

    func testSearchByBundleIdentifier() throws {
        let store = SmartSwitchStore()
        let app = ApplicationIdentity(bundleIdentifier: "com.example.UniqueApp", name: "UniqueApp")
        _ = try store.handleAppFocus(app, currentChoice: SmartSwitchChoice(language: .vietnamese), now: .distantPast)

        let results = store.search("com.example.UniqueApp")
        XCTAssertEqual(results.count, 1)
    }

    func testSearchByAppName() throws {
        let store = SmartSwitchStore()
        let app = ApplicationIdentity(bundleIdentifier: "com.example.Foo", name: "Foo Bar")
        _ = try store.handleAppFocus(app, currentChoice: SmartSwitchChoice(language: .vietnamese), now: .distantPast)

        let results = store.search("Foo")
        XCTAssertEqual(results.count, 1)
    }

    func testSearchByEncoding() throws {
        let store = SmartSwitchStore()
        let app = ApplicationIdentity(bundleIdentifier: "com.example.Test", name: "TestApp")
        _ = try store.handleAppFocus(
            app,
            currentChoice: SmartSwitchChoice(language: .vietnamese, encoding: .vniWindows),
            now: .distantPast
        )

        let results = store.search("TestApp")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.choice.encoding, .vniWindows)
    }

    func testSearchEmptyQuery() throws {
        let store = SmartSwitchStore()
        let app1 = ApplicationIdentity(bundleIdentifier: "com.example.A", name: "A")
        let app2 = ApplicationIdentity(bundleIdentifier: "com.example.B", name: "B")

        _ = try store.handleAppFocus(app1, currentChoice: SmartSwitchChoice(language: .vietnamese), now: .distantPast)
        _ = try store.handleAppFocus(app2, currentChoice: SmartSwitchChoice(language: .english), now: .distantPast)

        XCTAssertEqual(store.search("").count, 2)
    }

    func testStableKeyPrefersPath() {
        let app = ApplicationIdentity(
            bundleIdentifier: "com.example.Test",
            path: "/Applications/Test.app",
            name: "Test"
        )
        let key = app.stableKey
        XCTAssertNotNil(key)
    }

    func testStableKeyFallsBackToName() {
        let app = ApplicationIdentity(name: "Test")
        let key = app.stableKey
        XCTAssertNotNil(key)
    }

    func testApplicationOverrideInit() {
        let override = SmartSwitchOptions.ApplicationOverride(inputLanguage: .vietnamese, encoding: .tcvn3)
        XCTAssertEqual(override.inputLanguage, .vietnamese)
        XCTAssertEqual(override.encoding, .tcvn3)
    }

    func testPreferencesGetterWithFileURL() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let fileURL = directory.appendingPathComponent("smart-switch.json")
        let store = SmartSwitchStore(fileURL: fileURL)
        let app = ApplicationIdentity(bundleIdentifier: "com.example.Test", name: "Test")
        _ = try store.handleAppFocus(app, currentChoice: SmartSwitchChoice(language: .vietnamese), now: .distantPast)

        let preferences = store.preferences
        XCTAssertEqual(preferences.count, 1)
    }

    func testLoadDuplicatePersistedKeysKeepsLatestWithoutTrapping() throws {
        struct Document: Encodable {
            let schemaVersion: Int
            let preferences: [SmartSwitchPreference]
        }

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileURL = directory.appendingPathComponent("smart-switch.json")
        let stored = Document(schemaVersion: 1, preferences: [
            SmartSwitchPreference(
                key: "bundle:duplicate",
                displayName: "Old",
                choice: SmartSwitchChoice(language: .english),
                lastUsedAt: .distantPast
            ),
            SmartSwitchPreference(
                key: "bundle:duplicate",
                displayName: "Latest",
                choice: SmartSwitchChoice(language: .vietnamese),
                lastUsedAt: .distantFuture
            ),
        ])
        try JSONEncoder().encode(stored).write(to: fileURL)

        let store = SmartSwitchStore(fileURL: fileURL)

        XCTAssertEqual(store.preferences.map(\.displayName), ["Latest"])
    }

    func testEditWithNonExistentKey() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let fileURL = directory.appendingPathComponent("smart-switch.json")
        let store = SmartSwitchStore(fileURL: fileURL)

        XCTAssertThrowsError(try store.edit(key: "nonexistent", choice: SmartSwitchChoice(language: .vietnamese))) {
            XCTAssertEqual($0 as? SmartSwitchStoreError, .unknownPreference)
        }
    }

    func testChoiceWhenNone() {
        let store = SmartSwitchStore()
        let app = ApplicationIdentity(name: "Unknown")
        XCTAssertNil(store.choice(for: app))
    }

    func testResetNonExistentKey() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let fileURL = directory.appendingPathComponent("smart-switch.json")
        let store = SmartSwitchStore(fileURL: fileURL)

        XCTAssertThrowsError(try store.reset(key: "nonexistent")) {
            XCTAssertEqual($0 as? SmartSwitchStoreError, .unknownPreference)
        }
    }
}
