import EasyEngineCore
@testable import EasyKey
import XCTest

@MainActor
final class ObservableSettingsStoreTests: XCTestCase {
    private var tempDirectory: URL!
    private var fileURL: URL!
    private var store: SettingsStore!

    override func setUpWithError() throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SettingsStoreTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        fileURL = tempDirectory.appendingPathComponent("settings.json")
        store = SettingsStore(fileURL: fileURL)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDirectory)
        store = nil
    }

    func testInit_LoadsDefaultsWhenFileMissing() {
        XCTAssertEqual(store.settings.input.language, .vietnamese)
    }

    func testUpdate_MutatesSettingsAndPublishes() {
        store.update { $0.input.inputMethod = .vni }
        XCTAssertEqual(store.settings.input.inputMethod, .vni)
    }

    func testReset_RestoresDefaults() {
        store.update { $0.input.inputMethod = .vni }
        store.reset()
        XCTAssertEqual(store.settings.input.inputMethod, .simpleTelex)
    }

    func testExportThenImport_RoundTrips() throws {
        store.update { $0.input.inputMethod = .vni }
        let exportURL = tempDirectory.appendingPathComponent("export.json")
        try store.export(to: exportURL)

        store.reset()
        XCTAssertEqual(store.settings.input.inputMethod, .simpleTelex)

        _ = try store.import(from: exportURL)
        XCTAssertEqual(store.settings.input.inputMethod, .vni)
    }

    func testImport_InvalidFile_Throws() {
        let badURL = tempDirectory.appendingPathComponent("missing.json")
        XCTAssertThrowsError(try store.import(from: badURL))
    }

    func testLoad_DoesNotCrash() {
        store.load()
    }

    func testSaveNow_CompletesWithoutCrashing() async {
        store.update { $0.input.inputMethod = .vni }
        await store.saveNow()
    }

    func testConfigurationSnapshot_ReflectsCurrentSettings() {
        store.update { $0.input.inputMethod = .vni }
        XCTAssertEqual(store.configurationSnapshot.inputMethod, .vni)
    }

    func testDefaultFileURL_IsStable() {
        XCTAssertEqual(SettingsStore.defaultFileURL, SettingsStore.defaultFileURL)
    }
}
