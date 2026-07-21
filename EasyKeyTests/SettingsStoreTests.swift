@testable import EasyEngineCore
import XCTest

@MainActor
final class SettingsStoreTests: XCTestCase {
    func testDefaultsProduceValidSettings() {
        let settings = EasyKeySettings.defaults
        XCTAssertEqual(settings.schemaVersion, EasyKeySettings.currentSchemaVersion)
        XCTAssertEqual(settings.input.language, .vietnamese)
        XCTAssertEqual(settings.input.inputMethod, .simpleTelex)
        XCTAssertEqual(settings.input.encoding, .unicode)
        XCTAssertEqual(settings.input.switchShortcut, Shortcut(keyCode: 6, modifiers: [.option]))
        XCTAssertEqual(settings.input.switchShortcut.displayLabel, "\u{2325} + Z")
        XCTAssertFalse(settings.system.launchAtLogin)
        XCTAssertFalse(settings.system.showDockIcon)
        XCTAssertTrue(settings.system.checkForUpdates)
        XCTAssertEqual(
            settings.compatibility.compatibilityModeApplicationBundleIdentifiers,
            ["com.google.Chrome", "org.chromium.Chromium"]
        )
        XCTAssertTrue(settings.compatibility.ignoredApplicationBundleIdentifiers.isEmpty)
    }

    func testLegacyCompatibilitySettingsReceiveNewDefaults() throws {
        let data = Data(#"{"stepByStepSend":true,"keyboardLayoutCompatibility":false,"otherLanguageSupport":true}"#.utf8)
        let decoded = try JSONDecoder().decode(CompatibilityOptions.self, from: data)
        XCTAssertTrue(decoded.stepByStepSend)
        XCTAssertTrue(decoded.otherLanguageSupport)
        XCTAssertEqual(
            decoded.compatibilityModeApplicationBundleIdentifiers,
            CompatibilityOptions.defaultCompatibilityModeApplicationBundleIdentifiers
        )
        XCTAssertTrue(decoded.ignoredApplicationBundleIdentifiers.isEmpty)
    }

    func testLegacyChromiumListMigratesWithoutChangingEntries() throws {
        let data = Data(#"{"chromiumBrowserBundleIdentifiers":["com.microsoft.edgemac","dev.example.Custom"]}"#.utf8)
        let decoded = try JSONDecoder().decode(CompatibilityOptions.self, from: data)
        XCTAssertEqual(
            decoded.compatibilityModeApplicationBundleIdentifiers,
            ["com.microsoft.edgemac", "dev.example.Custom"]
        )

        let encoded = try JSONEncoder().encode(decoded)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        XCTAssertNotNil(json["compatibilityModeApplicationBundleIdentifiers"])
        XCTAssertNil(json["chromiumBrowserBundleIdentifiers"])
    }

    func testRoundTrip() throws {
        var settings = EasyKeySettings.defaults
        settings.input.inputMethod = .vni
        settings.input.encoding = .tcvn3
        settings.typing.quickTelexConsonants = true
        settings.macro.enabled = true
        settings.smartSwitch.enabled = true
        settings.system.launchAtLogin = true
        settings.converter.shortcut = Shortcut(keyCode: 36, modifiers: [.command, .option])

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(settings)
        let decoded = try JSONDecoder().decode(EasyKeySettings.self, from: data)

        XCTAssertEqual(decoded, settings)
    }

    func testSettingsStoreLoadDefaultsWhenNoFile() {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("settings.json")
        let store = SettingsRepository(fileURL: tempURL)
        XCTAssertEqual(store.settings, .defaults)
    }

    func testSettingsStorePersistAndReload() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let fileURL = tempDir.appendingPathComponent("settings.json")

        let store = SettingsRepository(fileURL: fileURL)
        store.update { $0.input.inputMethod = .vni }
        await store.saveNow()
        XCTAssertEqual(store.settings.input.inputMethod, .vni)

        let reloaded = SettingsRepository(fileURL: fileURL)
        XCTAssertEqual(reloaded.settings.input.inputMethod, .vni)

        try FileManager.default.removeItem(at: tempDir)
    }

    func testSettingsStoreReset() {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("settings.json")
        let store = SettingsRepository(fileURL: tempURL)
        store.update { $0.input.inputMethod = .vni }
        store.reset()
        XCTAssertEqual(store.settings, .defaults)
    }

    func testSettingsStoreExportImport() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let exportURL = tempDir.appendingPathComponent("export.json")

        let source = SettingsRepository(fileURL: tempDir.appendingPathComponent("src.json"))
        source.update {
            $0.input.inputMethod = .vni
            $0.typing.bracketShortcuts = false
        }
        await source.saveNow()
        try source.export(to: exportURL)

        let dest = SettingsRepository(fileURL: tempDir.appendingPathComponent("dst.json"))
        let diagnostic = try dest.import(from: exportURL)
        XCTAssertEqual(dest.settings.input.inputMethod, .vni)
        XCTAssertFalse(dest.settings.typing.bracketShortcuts)
        XCTAssertFalse(diagnostic.entries.isEmpty)

        try FileManager.default.removeItem(at: tempDir)
    }

    func testConfigurationSnapshot() {
        let store = SettingsRepository(
            fileURL: FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString).appendingPathComponent("s.json")
        )
        store.update {
            $0.input.inputMethod = .simpleTelex
            $0.typing.restoreInvalidWord = false
        }
        let snapshot = store.configurationSnapshot
        XCTAssertEqual(snapshot.inputMethod, .simpleTelex)
        XCTAssertFalse(snapshot.autoRestoreKeys)
    }

    func testLegacyQuickConsonantSettingMigrates() throws {
        let data = Data(#"{"quickStartEndConsonant":true,"quickTelex":true}"#.utf8)
        let decoded = try JSONDecoder().decode(TypingOptions.self, from: data)
        XCTAssertTrue(decoded.quickTelexConsonants)
        XCTAssertEqual(decoded.toneStyle, .old)
    }

    func testImportInvalidFilePreservesCurrentSettings() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let badURL = tempDir.appendingPathComponent("bad.json")
        let settingsURL = tempDir.appendingPathComponent("s.json")
        try "not valid json".write(to: badURL, atomically: true, encoding: .utf8)

        let store = SettingsRepository(fileURL: settingsURL)
        store.update { $0.input.inputMethod = .vni }
        await store.saveNow()
        let persistedSettings = try Data(contentsOf: settingsURL)

        let diagnostic = try store.import(from: badURL)

        XCTAssertEqual(store.settings.input.inputMethod, .vni)
        XCTAssertEqual(try Data(contentsOf: settingsURL), persistedSettings)
        XCTAssertTrue(diagnostic.entries.contains { $0.severity == .warning })

        try FileManager.default.removeItem(at: tempDir)
    }

    func testImportFileTooLargeThrowsError() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let largeFile = tempDir.appendingPathComponent("large.json")
        let largeData = Data(repeating: 0x41, count: SettingsRepository.maxImportFileBytes + 1)
        try largeData.write(to: largeFile)

        let store = SettingsRepository(fileURL: tempDir.appendingPathComponent("s.json"))
        XCTAssertThrowsError(try store.import(from: largeFile)) { error in
            if let repoError = error as? SettingsRepositoryError {
                XCTAssertEqual(repoError, .importFileTooLarge)
            }
        }
    }

    func testLoadWhenFileExists() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fileURL = tempDir.appendingPathComponent("settings.json")
        let store = SettingsRepository(fileURL: fileURL)
        store.update { $0.input.inputMethod = .vni }
        await store.saveNow()

        store.update { $0.input.inputMethod = .simpleTelex }
        store.load()
        XCTAssertEqual(store.settings.input.inputMethod, .vni)
    }

    func testLoadWhenNoFileResetsToDefaults() {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("nonexistent-\(UUID().uuidString)")
            .appendingPathComponent("settings.json")
        let store = SettingsRepository(fileURL: fileURL)
        store.update { $0.input.inputMethod = .vni }
        XCTAssertEqual(store.settings.input.inputMethod, .vni)
        store.load()
        XCTAssertEqual(store.settings, .defaults)
    }

    func testOnSettingsChangeCallback() {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("settings.json")
        let store = SettingsRepository(fileURL: fileURL)
        var changed = false
        store.onSettingsChange = { _ in changed = true }
        store.update { $0.input.language = .english }
        XCTAssertTrue(changed)
    }

    func testSettingsRepositoryErrorEquality() {
        XCTAssertEqual(SettingsRepositoryError.importFileTooLarge, SettingsRepositoryError.importFileTooLarge)
    }
}

@MainActor
final class DomainTypeTests: XCTestCase {
    func testInputLanguageRoundTrip() throws {
        for lang in InputLanguage.allCases {
            let data = try JSONEncoder().encode(lang)
            let decoded = try JSONDecoder().decode(InputLanguage.self, from: data)
            XCTAssertEqual(decoded, lang)
        }
    }

    func testShortcutDisplayLabel() {
        let shortcut = Shortcut(keyCode: 36, modifiers: [.command, .option])
        XCTAssertTrue(shortcut.isActive)
        XCTAssertTrue(shortcut.displayLabel.contains("\u{2318}"))
        XCTAssertTrue(shortcut.displayLabel.contains("\u{2325}"))

        let none = Shortcut.none
        XCTAssertFalse(none.isActive)
        XCTAssertEqual(none.displayLabel, "")
    }

    func testShortcutModifiersRoundTrip() throws {
        let original = Shortcut(keyCode: 12, modifiers: [.shift, .control])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Shortcut.self, from: data)
        XCTAssertEqual(decoded, original)
    }
}
