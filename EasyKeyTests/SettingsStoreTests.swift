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
        XCTAssertEqual(settings.system.menuBarIconStyle, .style9)
        XCTAssertEqual(settings.system.menuBarIconScale, .percent130)
        XCTAssertEqual(
            settings.compatibility.compatibilityModeApplicationBundleIdentifiers,
            ["com.google.Chrome", "org.chromium.Chromium"]
        )
        XCTAssertTrue(settings.compatibility.ignoredApplicationBundleIdentifiers.isEmpty)
    }

    func testMenuBarIconStyle_DecodesWithMissingKey_DefaultsToStyle9() throws {
        let data = Data(#"{"grayMenuIcon":true}"#.utf8)
        let decoded = try JSONDecoder().decode(SystemOptions.self, from: data)
        XCTAssertEqual(decoded.menuBarIconStyle, .style9)
    }

    func testMenuBarIconStyle_RoundTripsAllCases() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for style in SystemOptions.MenuBarIconStyle.allCases {
            var options = SystemOptions()
            options.menuBarIconStyle = style
            let data = try encoder.encode(options)
            let decoded = try decoder.decode(SystemOptions.self, from: data)
            XCTAssertEqual(decoded.menuBarIconStyle, style)
        }
    }

    func testMenuBarIconScale_DecodesWithMissingKey_DefaultsToPercent130() throws {
        let data = Data(#"{"grayMenuIcon":true}"#.utf8)
        let decoded = try JSONDecoder().decode(SystemOptions.self, from: data)
        XCTAssertEqual(decoded.menuBarIconScale, .percent130)
    }

    func testMenuBarIconScale_RoundTripsAllCases() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for scale in SystemOptions.MenuBarIconScale.allCases {
            var options = SystemOptions()
            options.menuBarIconScale = scale
            let data = try encoder.encode(options)
            let decoded = try decoder.decode(SystemOptions.self, from: data)
            XCTAssertEqual(decoded.menuBarIconScale, scale)
        }
    }

    func testMenuBarIconScale_FactorMapping() {
        XCTAssertEqual(SystemOptions.MenuBarIconScale.percent100.factor, 1.0)
        XCTAssertEqual(SystemOptions.MenuBarIconScale.percent110.factor, 1.1)
        XCTAssertEqual(SystemOptions.MenuBarIconScale.percent120.factor, 1.2)
        XCTAssertEqual(SystemOptions.MenuBarIconScale.percent130.factor, 1.3)
        XCTAssertEqual(SystemOptions.MenuBarIconScale.percent140.factor, 1.4)
        XCTAssertEqual(SystemOptions.MenuBarIconScale.percent150.factor, 1.5)
    }

    func testLegacyCompatibilitySettingsReceiveNewDefaults() throws {
        let data = Data(#"{"stepByStepSend":true,"keyboardLayoutCompatibility":false,"otherLanguageSupport":true}"#.utf8)
        let decoded = try JSONDecoder().decode(CompatibilityOptions.self, from: data)
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
        settings.typing.iosUniKeyLikeMode = false
        settings.macro.enabled = true
        settings.smartSwitch.enabled = true
        settings.system.launchAtLogin = true

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
        let snapshot = EngineConfiguration(settings: store.settings)
        XCTAssertEqual(snapshot.inputMethod, .simpleTelex)
        XCTAssertFalse(snapshot.autoRestoreKeys)
    }

    func testLegacyQuickConsonantSettingMigrates() throws {
        let data = Data(#"{"quickStartEndConsonant":true,"quickTelex":true}"#.utf8)
        let decoded = try JSONDecoder().decode(TypingOptions.self, from: data)
        XCTAssertTrue(decoded.quickTelexConsonants)
        XCTAssertEqual(decoded.toneStyle, .old)
        XCTAssertTrue(decoded.iosUniKeyLikeMode)
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

        XCTAssertThrowsError(try store.import(from: badURL)) { error in
            guard case SettingsRepositoryError.malformedDocument = error else {
                XCTFail("Expected malformedDocument error, got \(error)")
                return
            }
        }

        XCTAssertEqual(store.settings.input.inputMethod, .vni)
        XCTAssertEqual(try Data(contentsOf: settingsURL), persistedSettings)

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

    func testSettingsDelta_IdenticalSettings_HasNoChanges() {
        let s1 = EasyKeySettings()
        let s2 = EasyKeySettings()
        let delta = SettingsDelta.delta(from: s1, to: s2)
        XCTAssertFalse(delta.hasAnyChange)

        var s3 = s1
        s3.system.showDockIcon = true
        let deltaSystem = SettingsDelta.delta(from: s1, to: s3)
        XCTAssertTrue(deltaSystem.hasAnyChange)
        XCTAssertTrue(deltaSystem.systemChanged)
        XCTAssertFalse(deltaSystem.inputChanged)
        XCTAssertFalse(deltaSystem.typingChanged)
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
