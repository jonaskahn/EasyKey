@testable import EasyEngineCore
import XCTest

/// Tests closing the last reachable coverage gaps in EasyEngineCore.
/// Each test names the branch it exercises so future edits keep the intent clear.
final class EngineCoverageGapTests: XCTestCase {
    // MARK: - TelexComposer

    func testToneTargetIndex_RemovesGiOnsetVowel() {
        let atoms: [BufferAtom] = [
            BufferAtom(base: "g"),
            BufferAtom(base: "i"),
            BufferAtom(base: "a"),
        ]
        XCTAssertEqual(TelexComposer.toneTargetIndex(atoms: atoms, style: .old), 2)
    }

    func testTrailingFinalConsonants_UnparseableTrailing_ReturnsEmpty() {
        let atoms: [BufferAtom] = [
            BufferAtom(base: "t"),
            BufferAtom(base: "a"),
            BufferAtom(base: "x"),
        ]
        XCTAssertEqual(TelexComposer.trailingFinalConsonants(atoms), "")
    }

    func testCompose_DoubleMarkUndo_OnRepeatKey() {
        let composition = TelexComposer.compose(
            rawKeys: Array("uoww"),
            configuration: EngineConfiguration(inputMethod: .telex)
        )
        XCTAssertEqual(TelexComposerCompositionRenderer.render(composition), "uow")
    }

    func testCompose_StandaloneWUndo_RemovesInsertedAtom() {
        let composition = TelexComposer.compose(
            rawKeys: Array("ww"),
            configuration: EngineConfiguration(inputMethod: .telex)
        )
        XCTAssertEqual(TelexComposerCompositionRenderer.render(composition), "w")
    }

    func testCompose_BracketCloseAppendsHornU() {
        let composition = TelexComposer.compose(
            rawKeys: Array("m]"),
            configuration: EngineConfiguration(inputMethod: .telex)
        )
        XCTAssertEqual(TelexComposerCompositionRenderer.render(composition), "mư")
    }

    func testCompose_WKeyOnUnmarkableVowel_AppendsLiteral() {
        let composition = TelexComposer.compose(
            rawKeys: Array("iw"),
            configuration: EngineConfiguration(inputMethod: .telex)
        )
        XCTAssertEqual(TelexComposerCompositionRenderer.render(composition), "iw")
    }

    func testCompose_VNIInvalidToneDigit_Dropped() {
        let composition = TelexComposer.compose(
            rawKeys: Array("ac2"),
            configuration: EngineConfiguration(inputMethod: .vni)
        )
        XCTAssertEqual(TelexComposerCompositionRenderer.render(composition), "ac")
    }

    func testCompose_VNIDiacriticNumber_NoVowel_AppendsLiteral() {
        let composition = TelexComposer.compose(
            rawKeys: Array("t8"),
            configuration: EngineConfiguration(inputMethod: .vni)
        )
        XCTAssertEqual(TelexComposerCompositionRenderer.render(composition), "t8")
    }

    func testCompose_VNIStrokeOnNonD_AppendsLiteral() {
        let composition = TelexComposer.compose(
            rawKeys: Array("a9"),
            configuration: EngineConfiguration(inputMethod: .vni)
        )
        XCTAssertEqual(TelexComposerCompositionRenderer.render(composition), "a9")
    }

    // MARK: - UnicodePrecomposedEncoding

    func testUnicodePrecomposedEncode_UncomposableVowel_FallsBackToCharacter() {
        let atoms: [BufferAtom] = [
            BufferAtom(base: "i", mark: .circumflex),
        ]
        let result = UnicodePrecomposedEncoding().encode(atoms: atoms, tone: .none, toneTargetIndex: 0)
        XCTAssertEqual(result, "i")
    }

    func testUnicodePrecomposedEncode_StrokeMarkOnNonD_FallsBackToCharacter() {
        let atoms: [BufferAtom] = [
            BufferAtom(base: "i", mark: .stroke),
        ]
        let result = UnicodePrecomposedEncoding().encode(atoms: atoms, tone: .none, toneTargetIndex: 0)
        XCTAssertEqual(result, "i")
    }

    // MARK: - SmartSwitchStore

    @MainActor
    func testSmartSwitchSave_DelayedTask_WritesFile() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ek-ss-save-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = SmartSwitchStore(fileURL: url)
        _ = try store.handleAppFocus(
            ApplicationIdentity(bundleIdentifier: "com.test.delayed", name: "Delayed"),
            currentChoice: SmartSwitchChoice(language: .vietnamese)
        )
        try await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    @MainActor
    func testSmartSwitchSave_MultiplePreferences_SortedByName() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ek-ss-sorted-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = SmartSwitchStore(fileURL: url)
        _ = try store.handleAppFocus(
            ApplicationIdentity(bundleIdentifier: "com.test.zebra", name: "Zebra"),
            currentChoice: SmartSwitchChoice(language: .english)
        )
        _ = try store.handleAppFocus(
            ApplicationIdentity(bundleIdentifier: "com.test.alpha", name: "Alpha"),
            currentChoice: SmartSwitchChoice(language: .vietnamese)
        )
        store.flush()
        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode(SavedSmartSwitchDocument.self, from: data)
        XCTAssertEqual(decoded.preferences.map(\.displayName), ["Alpha", "Zebra"])
    }

    // MARK: - TranslationOptions

    func testCmdCDoublePressTimeWindow_ConvertsMilliseconds() {
        let options = TranslationOptions(cmdCDoublePressWindowMs: 500)
        XCTAssertEqual(options.cmdCDoublePressTimeWindow, 0.5)
    }

    // MARK: - VietnameseOrthography

    func testLiveConfidence_LongNoModifierRun_AppliesLongPenalty() {
        let atoms = Array("bbbbbbbb").map { BufferAtom(base: $0) }
        let score = VietnameseOrthography.liveConfidenceScore(
            rawKeys: Array("bbbbbbbb"),
            atoms: atoms
        )
        XCTAssertLessThan(score, LiveConfidenceDefaults.lowThreshold)
    }

    // MARK: - SettingsRepository

    @MainActor
    func testDefaultFileURL_FallsBackThroughCaches() {
        let stub = StubFileManager(urlsByDirectory: [:])
        stub.cachesURL = URL(fileURLWithPath: "/stub/caches")
        let url = SettingsRepository.resolveDefaultFileURL(fileManager: stub)
        XCTAssertEqual(url.path, "/stub/caches/EasyKey/settings.json")
    }

    @MainActor
    func testDefaultFileURL_FallsBackToTemporaryDirectory() {
        let stub = StubFileManager(urlsByDirectory: [:])
        stub.cachesURL = nil
        let url = SettingsRepository.resolveDefaultFileURL(fileManager: stub)
        XCTAssertTrue(url.path.hasPrefix(FileManager.default.temporaryDirectory.path))
    }

    @MainActor
    func testDefaultFileURL_WhenCreateDirectoryFails_StillReturnsURL() {
        let stub = StubFileManager(urlsByDirectory: [
            .applicationSupportDirectory: URL(fileURLWithPath: "/stub/appsupport"),
        ])
        stub.failDirectoryCreation = true
        let url = SettingsRepository.resolveDefaultFileURL(fileManager: stub)
        XCTAssertEqual(url.lastPathComponent, "settings.json")
    }

    @MainActor
    func testLoad_SettingsWithOldSchemaVersion_IsMigrated() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ek-migrate-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        var oldSettings = EasyKeySettings()
        oldSettings.schemaVersion = 1
        let data = try JSONEncoder().encode(oldSettings)
        try data.write(to: url)
        let repo = SettingsRepository(fileURL: url)
        XCTAssertEqual(repo.settings.schemaVersion, EasyKeySettings.currentSchemaVersion)
    }

    @MainActor
    func testImport_SettingsWithOldSchemaVersion_IsMigrated() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ek-import-migrate-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        var oldSettings = EasyKeySettings()
        oldSettings.schemaVersion = 1
        let data = try JSONEncoder().encode(oldSettings)
        try data.write(to: url)
        let repo = SettingsRepository(fileURL: url)
        let diagnostics = try repo.import(from: url)
        XCTAssertEqual(repo.settings.schemaVersion, EasyKeySettings.currentSchemaVersion)
        XCTAssertFalse(diagnostics.entries.isEmpty)
    }
}

/// Mirror of the private SmartSwitchDocument used for decode assertions.
private struct SavedSmartSwitchDocument: Codable {
    struct Preference: Codable {
        var displayName: String
    }

    var schemaVersion: Int
    var preferences: [Preference]
}

/// Renders a TelexComposer composition through the public encoder path.
private enum TelexComposerCompositionRenderer {
    static func render(_ composition: TelexComposer.Composition) -> String {
        UnicodePrecomposedEncoding().encode(
            atoms: composition.atoms,
            tone: composition.tone,
            toneTargetIndex: TelexComposer.toneTargetIndex(atoms: composition.atoms, style: .old)
        )
    }
}

/// FileManager stub returning a fixed directory map.
private final class StubFileManager: FileManager {
    private let urlsByDirectory: [FileManager.SearchPathDirectory: URL]
    var cachesURL: URL?
    var failDirectoryCreation = false

    init(urlsByDirectory: [FileManager.SearchPathDirectory: URL]) {
        self.urlsByDirectory = urlsByDirectory
        super.init()
    }

    override func urls(
        for directory: FileManager.SearchPathDirectory,
        in domainMask: FileManager.SearchPathDomainMask
    ) -> [URL] {
        if directory == .cachesDirectory, let cachesURL {
            return [cachesURL]
        }
        guard let url = urlsByDirectory[directory] else { return [] }
        return [url]
    }

    override func createDirectory(
        at url: URL,
        withIntermediateDirectories createIntermediates: Bool,
        attributes: [FileAttributeKey: Any]? = nil
    ) throws {
        if failDirectoryCreation {
            throw CocoaError(.fileWriteNoPermission)
        }
        try super.createDirectory(
            at: url,
            withIntermediateDirectories: createIntermediates,
            attributes: attributes
        )
    }
}
