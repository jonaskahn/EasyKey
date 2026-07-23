@testable import EasyEngineCore
import XCTest

final class SmartSwitchStoreTests: XCTestCase {
    func testHandleAppFocus_MissingPreference_RecordsChoice() throws {
        let store = SmartSwitchStore()
        let application = ApplicationIdentity(
            bundleIdentifier: "com.example.Editor",
            path: "/Applications/Editor.app",
            name: "Editor"
        )
        let first = SmartSwitchChoice(language: .vietnamese, encoding: .unicode)
        let date = Date(timeIntervalSince1970: 10)

        XCTAssertEqual(try store.handleAppFocus(application, currentChoice: first, now: date), .recorded(first))
        XCTAssertEqual(store.choice(for: application), first)
    }

    func testHandleAppFocus_ExistingPreference_AppliesStoredChoice() throws {
        let store = SmartSwitchStore()
        let application = ApplicationIdentity(
            bundleIdentifier: "com.example.Editor",
            path: "/Applications/Editor.app",
            name: "Editor"
        )
        let first = SmartSwitchChoice(language: .vietnamese, encoding: .unicode)
        let date = Date(timeIntervalSince1970: 10)

        _ = try store.handleAppFocus(application, currentChoice: first, now: date)
        XCTAssertEqual(
            try store.handleAppFocus(
                application,
                currentChoice: SmartSwitchChoice(language: .english),
                now: date.addingTimeInterval(1)
            ),
            .applied(first)
        )
    }

    func testStableKey_PathPresent_UsesPathPrefix() {
        XCTAssertEqual(
            ApplicationIdentity(path: "/Applications/Editor.app", name: "Editor").stableKey,
            "path:/Applications/Editor.app"
        )
    }

    func testStableKey_NameOnly_UsesNamePrefix() {
        XCTAssertEqual(ApplicationIdentity(name: "Editor").stableKey, "name:Editor")
    }

    func testHandleAppFocus_UnknownApp_RecordsWithoutChangingChoice() throws {
        let store = SmartSwitchStore()
        let application = ApplicationIdentity(bundleIdentifier: "com.example.Writer", name: "Writer")
        let current = SmartSwitchChoice(language: .english)

        XCTAssertEqual(try store.handleAppFocus(application, currentChoice: current), .recorded(current))
        XCTAssertEqual(store.choice(for: application), current)
    }

    func testEdit_AfterFocus_PersistsEncodingAcrossReload() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileURL = directory.appendingPathComponent("smart-switch.json")
        let app = ApplicationIdentity(bundleIdentifier: "com.example.Terminal", name: "Terminal")
        let store = SmartSwitchStore(fileURL: fileURL)
        _ = try store.handleAppFocus(app, currentChoice: SmartSwitchChoice(language: .english), now: .distantPast)

        let key = try XCTUnwrap(app.stableKey)
        try store.edit(key: key, choice: SmartSwitchChoice(language: .vietnamese, encoding: .vniWindows))
        store.flush()
        XCTAssertEqual(store.search("terminal").count, 1)
        XCTAssertEqual(SmartSwitchStore(fileURL: fileURL).choice(for: app)?.encoding, .vniWindows)
    }

    func testReset_ExistingKey_RemovesPreference() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileURL = directory.appendingPathComponent("smart-switch.json")
        let app = ApplicationIdentity(bundleIdentifier: "com.example.Terminal", name: "Terminal")
        let store = SmartSwitchStore(fileURL: fileURL)
        _ = try store.handleAppFocus(app, currentChoice: SmartSwitchChoice(language: .english), now: .distantPast)
        let key = try XCTUnwrap(app.stableKey)
        try store.edit(key: key, choice: SmartSwitchChoice(language: .vietnamese, encoding: .vniWindows))

        try store.reset(key: key)
        XCTAssertTrue(store.preferences.isEmpty)
    }

    func testUpdateChoice_ExistingPreference_RevisesForNextFocus() throws {
        let store = SmartSwitchStore()
        let application = ApplicationIdentity(bundleIdentifier: "com.example.Notes", name: "Notes")
        let vietnamese = SmartSwitchChoice(language: .vietnamese, encoding: .unicode)
        let english = SmartSwitchChoice(language: .english)

        XCTAssertEqual(try store.handleAppFocus(application, currentChoice: vietnamese), .recorded(vietnamese))
        XCTAssertTrue(try store.updateChoice(for: application, choice: english))
        XCTAssertEqual(store.choice(for: application), english)
        XCTAssertEqual(
            try store.handleAppFocus(application, currentChoice: vietnamese),
            .applied(english)
        )
    }

    func testUpdateChoice_SameChoice_ReturnsFalse() throws {
        let store = SmartSwitchStore()
        let application = ApplicationIdentity(bundleIdentifier: "com.example.Notes", name: "Notes")
        let english = SmartSwitchChoice(language: .english)

        _ = try store.handleAppFocus(application, currentChoice: english)
        XCTAssertFalse(try store.updateChoice(for: application, choice: english))
    }

    func testUpdateChoice_NoPreference_ReturnsFalse() throws {
        let store = SmartSwitchStore()
        let application = ApplicationIdentity(bundleIdentifier: "com.example.New", name: "New")
        XCTAssertFalse(
            try store.updateChoice(for: application, choice: SmartSwitchChoice(language: .english))
        )
    }
}
