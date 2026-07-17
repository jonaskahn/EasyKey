import EasyEngineCore
@testable import EasyKey
import XCTest

@MainActor
final class SmartSwitchControllerTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var localizationDefaults: UserDefaults!
    private var localizationSuiteName: String!
    private var settingsStore: ObservableSettingsStore!
    private var smartSwitchStore: SmartSwitchStore!
    private var localization: LocalizationStore!
    private var controller: SmartSwitchController!
    private var tempDirectory: URL!

    override func setUpWithError() throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SmartSwitchControllerTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        settingsStore = ObservableSettingsStore(fileURL: tempDirectory.appendingPathComponent("settings.json"))
        smartSwitchStore = SmartSwitchStore(fileURL: tempDirectory.appendingPathComponent("smart-switch.json"))

        localizationSuiteName = "one.ifelse.easykey.smartswitch-tests.\(UUID().uuidString)"
        localizationDefaults = UserDefaults(suiteName: localizationSuiteName)
        localizationDefaults.removePersistentDomain(forName: localizationSuiteName)
        localization = LocalizationStore(defaults: localizationDefaults, bundle: .main)

        controller = SmartSwitchController(
            smartSwitchStore: smartSwitchStore,
            settingsStore: settingsStore,
            localization: localization
        )
    }

    override func tearDownWithError() throws {
        localizationDefaults.removePersistentDomain(forName: localizationSuiteName)
        try? FileManager.default.removeItem(at: tempDirectory)
        controller = nil
        smartSwitchStore = nil
        settingsStore = nil
        localization = nil
    }

    func testInit_SetsDefaultDisplayStrings() {
        XCTAssertFalse(controller.currentApplicationName.isEmpty)
        XCTAssertFalse(controller.currentAppSmartSwitchStatus.isEmpty)
    }

    func testHandleApplicationActivation_NilApplication_ShowsNoActiveApp() {
        var changeCount = 0
        controller.onPublishedStateChange = { changeCount += 1 }
        controller.handleApplicationActivation(nil)
        XCTAssertEqual(changeCount, 1)
    }

    func testHandleApplicationActivation_SmartSwitchDisabled_ShowsOffStatus() {
        settingsStore.update { $0.smartSwitch.enabled = false }
        let app = NSWorkspace.shared.frontmostApplication
        controller.handleApplicationActivation(app)
        XCTAssertFalse(controller.currentAppSmartSwitchStatus.isEmpty)
    }

    func testResetPreference_RemovesStoredChoice() {
        let identity = ApplicationIdentity(bundleIdentifier: "com.example.App", path: nil, name: "App")
        let choice = SmartSwitchChoice(language: .english, encoding: .unicode)
        _ = try? smartSwitchStore.handleAppFocus(identity, currentChoice: choice)
        guard let preference = controller.preferences.first else {
            XCTFail("Expected a stored preference")
            return
        }
        var changeCount = 0
        controller.onPublishedStateChange = { changeCount += 1 }
        controller.resetPreference(preference)
        XCTAssertEqual(changeCount, 1)
        XCTAssertTrue(controller.preferences.isEmpty)
    }

    func testClearPreferences_RemovesAllChoices() {
        let identity = ApplicationIdentity(bundleIdentifier: "com.example.App", path: nil, name: "App")
        let choice = SmartSwitchChoice(language: .english, encoding: .unicode)
        _ = try? smartSwitchStore.handleAppFocus(identity, currentChoice: choice)

        var changeCount = 0
        controller.onPublishedStateChange = { changeCount += 1 }
        controller.clearPreferences()
        XCTAssertEqual(changeCount, 1)
        XCTAssertTrue(controller.preferences.isEmpty)
    }

    func testRememberChoiceIfNeeded_Disabled_DoesNothing() {
        settingsStore.update { $0.smartSwitch.enabled = false }
        controller.rememberChoiceIfNeeded(from: settingsStore.settings)
    }

    func testRememberChoiceIfNeeded_FirstCall_OnlySeedsLastChoice() {
        settingsStore.update { $0.smartSwitch.enabled = true }
        controller.rememberChoiceIfNeeded(from: settingsStore.settings)
        controller.rememberChoiceIfNeeded(from: settingsStore.settings)
    }

    func testHandleApplicationActivation_Enabled_RecordsChoiceForUnknownApp() throws {
        settingsStore.update {
            $0.smartSwitch.enabled = true
            $0.smartSwitch.rememberEncoding = false
        }
        let identity = ApplicationIdentity(
            bundleIdentifier: "com.example.NotReal-\(UUID().uuidString)",
            path: nil,
            name: "NotReal"
        )
        let choice = SmartSwitchChoice(language: .vietnamese, encoding: .unicode)
        _ = try smartSwitchStore.handleAppFocus(identity, currentChoice: choice)
        XCTAssertTrue(controller.preferences.contains(where: { $0.key.contains("com.example.NotReal") }))
        let frontmost = NSWorkspace.shared.frontmostApplication
        controller.handleApplicationActivation(frontmost)
        XCTAssertNotNil(frontmost?.bundleIdentifier)
    }

    func testHandleApplicationActivation_EnabledAndRememberEncoding_AppliesLanguageAndEncoding() throws {
        settingsStore.update {
            $0.smartSwitch.enabled = true
            $0.smartSwitch.rememberEncoding = true
        }
        let identity = ApplicationIdentity(
            bundleIdentifier: "com.example.ApplyBoth-\(UUID().uuidString)",
            path: nil,
            name: "App"
        )
        let appliedChoice = SmartSwitchChoice(language: .vietnamese, encoding: .unicode)
        _ = try smartSwitchStore.handleAppFocus(identity, currentChoice: appliedChoice)
        let preApply = smartSwitchStore.preferences.first { $0.key.contains("com.example.ApplyBoth") }
        XCTAssertNotNil(preApply)
        XCTAssertEqual(preApply?.choice.language, .vietnamese)
        XCTAssertEqual(preApply?.choice.encoding, .unicode)
    }

    func testHandleApplicationActivation_EnabledWithoutRememberEncoding_AppliesLanguageOnly() throws {
        settingsStore.update {
            $0.smartSwitch.enabled = true
            $0.smartSwitch.rememberEncoding = false
        }
        let identity = ApplicationIdentity(
            bundleIdentifier: "com.example.LanguageOnly-\(UUID().uuidString)",
            path: nil,
            name: "App"
        )
        let appliedChoice = SmartSwitchChoice(language: .vietnamese, encoding: nil)
        _ = try smartSwitchStore.handleAppFocus(identity, currentChoice: appliedChoice)
        let preApply = smartSwitchStore.preferences.first { $0.key.contains("com.example.LanguageOnly") }
        XCTAssertNotNil(preApply)
        XCTAssertEqual(preApply?.choice.language, .vietnamese)
        XCTAssertNil(preApply?.choice.encoding)
    }

    func testHandleApplicationActivation_EnabledNoFrontmost_ShowsUnavailable() {
        settingsStore.update { $0.smartSwitch.enabled = true }
        controller.handleApplicationActivation(NSWorkspace.shared.frontmostApplication)
        XCTAssertFalse(controller.currentAppSmartSwitchStatus.isEmpty)
    }

    func testResetPreference_WhenStoreThrows_DoesNotCrash() {
        let preference = SmartSwitchPreference(
            key: "missing",
            displayName: "Missing",
            choice: SmartSwitchChoice(language: .english),
            lastUsedAt: Date()
        )
        controller.resetPreference(preference)
    }

    func testClearPreferences_WhenStoreIsEmpty_DoesNotCrash() {
        controller.clearPreferences()
        XCTAssertTrue(controller.preferences.isEmpty)
    }

    func testHandleApplicationActivation_EnabledWithFrontmostApp_RecordsOrApplies() {
        settingsStore.update {
            $0.smartSwitch.enabled = true
            $0.smartSwitch.rememberEncoding = true
            $0.input.language = .vietnamese
        }
        let frontmost = NSWorkspace.shared.frontmostApplication
        controller.handleApplicationActivation(frontmost)
        XCTAssertFalse(controller.currentAppSmartSwitchStatus.isEmpty)
    }

    func testRememberChoiceIfNeeded_DisabledBranch_DoesNotUpdateStore() {
        settingsStore.update { $0.smartSwitch.enabled = false }
        controller.rememberChoiceIfNeeded(from: settingsStore.settings)
    }

    func testRememberChoiceIfNeeded_EnabledNoFrontmost_DoesNotUpdateStore() {
        settingsStore.update { $0.smartSwitch.enabled = true }
        controller.rememberChoiceIfNeeded(from: settingsStore.settings)
    }

    func testApplyLanguage_UpdatesSettings() {
        settingsStore.update { $0.input.language = .english }
        controller.applyLanguage(from: SmartSwitchChoice(language: .vietnamese))
        XCTAssertEqual(settingsStore.settings.input.language, .vietnamese)
    }

    func testApplyLanguageAndEncoding_UpdatesSettings() {
        settingsStore.update {
            $0.input.language = .english
            $0.input.encoding = .unicode
        }
        controller.applyLanguageAndEncoding(from: SmartSwitchChoice(language: .vietnamese, encoding: .tcvn3))
        XCTAssertEqual(settingsStore.settings.input.language, .vietnamese)
        XCTAssertEqual(settingsStore.settings.input.encoding, .tcvn3)
    }

    func testApplyLanguageAndEncoding_NilEncoding_OnlyUpdatesLanguage() {
        settingsStore.update {
            $0.input.language = .english
            $0.input.encoding = .unicode
        }
        controller.applyLanguageAndEncoding(from: SmartSwitchChoice(language: .vietnamese, encoding: nil))
        XCTAssertEqual(settingsStore.settings.input.language, .vietnamese)
        XCTAssertEqual(settingsStore.settings.input.encoding, .unicode)
    }
}
