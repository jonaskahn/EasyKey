@testable import EasyEngineCore
import XCTest

final class TranslationOptionsTests: XCTestCase {
    func testDefaults_MatchApprovedProductDecisions() {
        let options = TranslationOptions()
        XCTAssertEqual(options.preferredProviderID, .apple, "Default provider preference is Apple")
        XCTAssertEqual(options.shortcut, Shortcut(keyCode: 8, modifiers: [.option]))
        XCTAssertNil(options.defaultSourceLanguage, "Default source is automatic detection")
        XCTAssertEqual(options.openAIModelIdentifier, TranslationOptions.defaultOpenAIModelIdentifier)
        XCTAssertEqual(options.anthropicModelIdentifier, TranslationOptions.defaultAnthropicModelIdentifier)
        XCTAssertEqual(options.geminiModelIdentifier, TranslationOptions.defaultGeminiModelIdentifier)
        XCTAssertEqual(options.deepLEndpoint, .free)
        XCTAssertTrue(options.acknowledgedCloudDisclosureProviders.isEmpty)
        XCTAssertFalse(options.isEnabled)
        XCTAssertFalse(options.showInMenuPopover)
        XCTAssertFalse(options.cmdCDoublePressEnabled, "Double-press Cmd+C is off by default")
        XCTAssertEqual(options.cmdCDoublePressWindowMs, 400)
        XCTAssertEqual(options.autoTranslateDelayMs, TranslationOptions.AutoTranslateDelayPreset.ms500.rawValue)
        XCTAssertEqual(options.panelSize, .medium)
        XCTAssertEqual(options.sessionPersistence, .keepUntilRestart)
    }

    func testDefaultShortcut_DisplaysAsOptionC() {
        XCTAssertEqual(TranslationOptions().shortcut.displayLabel, "\u{2325} + C")
    }

    func testJSONRoundTrip_PreservesEveryField() throws {
        var options = TranslationOptions()
        options.preferredProviderID = .deepL
        options.shortcut = Shortcut(keyCode: 1, modifiers: [.option, .command])
        options.defaultSourceLanguage = .vietnamese
        options.openAIModelIdentifier = "custom-model"
        options.deepLEndpoint = .pro
        options.acknowledgedCloudDisclosureProviders = [.deepL, .openAI]
        options.isEnabled = false
        options.showInMenuPopover = false
        options.cmdCDoublePressEnabled = true
        options.cmdCDoublePressWindowMs = 600
        options.autoTranslateDelayMs = 1000
        options.panelSize = .large
        options.sessionPersistence = .clearOnClose

        let data = try JSONEncoder().encode(options)
        let decoded = try JSONDecoder().decode(TranslationOptions.self, from: data)
        XCTAssertEqual(decoded, options)
        XCTAssertFalse(decoded.isEnabled)
        XCTAssertFalse(decoded.showInMenuPopover)
        XCTAssertTrue(decoded.cmdCDoublePressEnabled)
        XCTAssertEqual(decoded.cmdCDoublePressWindowMs, 600)
        XCTAssertEqual(decoded.autoTranslateDelayMs, 1000)
        XCTAssertEqual(decoded.panelSize, .large)
        XCTAssertEqual(decoded.sessionPersistence, .clearOnClose)
    }

    func testLegacyDecode_MissingIsEnabledDefaultsToFalse() throws {
        let data = Data("{}".utf8)
        let decoded = try JSONDecoder().decode(TranslationOptions.self, from: data)
        XCTAssertFalse(decoded.isEnabled)
    }

    func testLegacyDecode_MissingShowInMenuPopoverDefaultsToFalse() throws {
        let data = Data("{}".utf8)
        let decoded = try JSONDecoder().decode(TranslationOptions.self, from: data)
        XCTAssertFalse(decoded.showInMenuPopover)
    }

    func testLegacyDecode_MissingCmdCDoublePressEnabledDefaultsToFalse() throws {
        let data = Data("{}".utf8)
        let decoded = try JSONDecoder().decode(TranslationOptions.self, from: data)
        XCTAssertFalse(decoded.cmdCDoublePressEnabled)
    }

    func testLegacyDecode_MissingCmdCDoublePressWindowMsDefaultsTo400() throws {
        let data = Data("{}".utf8)
        let decoded = try JSONDecoder().decode(TranslationOptions.self, from: data)
        XCTAssertEqual(decoded.cmdCDoublePressWindowMs, 400)
    }

    func testLegacyDecode_MissingAutoTranslateDelayMs_DefaultsTo500() throws {
        let data = Data("{}".utf8)
        let decoded = try JSONDecoder().decode(TranslationOptions.self, from: data)
        XCTAssertEqual(decoded.autoTranslateDelayMs, TranslationOptions.AutoTranslateDelayPreset.ms500.rawValue)
    }

    func testLegacyDecode_MissingPanelSizeDefaultsToMedium() throws {
        let data = Data("{}".utf8)
        let decoded = try JSONDecoder().decode(TranslationOptions.self, from: data)
        XCTAssertEqual(decoded.panelSize, .medium)
    }

    func testLegacyDecode_MissingSessionPersistenceDefaultsToKeepUntilRestart() throws {
        let data = Data("{}".utf8)
        let decoded = try JSONDecoder().decode(TranslationOptions.self, from: data)
        XCTAssertEqual(decoded.sessionPersistence, .keepUntilRestart)
    }

    func testPanelSize_CGSizeWidthsRespectViewMinimumWidth() {
        for size in TranslationOptions.PanelSize.allCases {
            XCTAssertGreaterThanOrEqual(size.cgSize.width, 420)
            XCTAssertGreaterThanOrEqual(size.cgSize.height, 500)
        }
    }

    func testAutoTranslateDelayPresets_ProduceCorrectTimeIntervals() {
        XCTAssertEqual(TranslationOptions.AutoTranslateDelayPreset.ms250.timeInterval, 0.25)
        XCTAssertEqual(TranslationOptions.AutoTranslateDelayPreset.ms500.timeInterval, 0.5)
        XCTAssertEqual(TranslationOptions.AutoTranslateDelayPreset.ms750.timeInterval, 0.75)
        XCTAssertEqual(TranslationOptions.AutoTranslateDelayPreset.ms1000.timeInterval, 1.0)
        XCTAssertEqual(TranslationOptions.AutoTranslateDelayPreset.ms1500.timeInterval, 1.5)
    }

    func testEncodedRepresentation_ContainsNoSecretOrContentKeys() throws {
        let data = try JSONEncoder().encode(TranslationOptions())
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let forbiddenKeys = [
            "apiKey", "credential", "sourceText", "translatedText",
            "detectedLanguage", "progress", "error",
        ]
        for forbidden in forbiddenKeys {
            XCTAssertNil(object[forbidden], "TranslationOptions must never persist \(forbidden)")
        }
    }

    func testEasyKeySettings_DefaultsIncludeTranslationOptions() {
        XCTAssertEqual(EasyKeySettings.defaults.translation, TranslationOptions())
    }

    func testCurrentSchemaVersion_IsSeven() {
        XCTAssertEqual(EasyKeySettings.currentSchemaVersion, 9)
    }

    func testLegacySettingsWithoutTranslationKey_DecodeWithDefaultsAndPreserveOthers() throws {
        let data = try JSONEncoder().encode(EasyKeySettings.defaults)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object.removeValue(forKey: "translation")
        object["schemaVersion"] = 4
        let legacyData = try JSONSerialization.data(withJSONObject: object)

        let decoded = try JSONDecoder().decode(EasyKeySettings.self, from: legacyData)

        XCTAssertEqual(decoded.translation, TranslationOptions())
        XCTAssertEqual(decoded.input, EasyKeySettings.defaults.input)
        XCTAssertEqual(decoded.clipboard, EasyKeySettings.defaults.clipboard)
        XCTAssertEqual(decoded.converter, EasyKeySettings.defaults.converter)
        XCTAssertEqual(decoded.schemaVersion, 4)
    }

    func testSparseDocument_FallsBackToTranslationDefaults() throws {
        let sparse = Data("{\"schemaVersion\": 4}".utf8)
        let decoded = try JSONDecoder().decode(EasyKeySettings.self, from: sparse)
        XCTAssertEqual(decoded.translation, TranslationOptions())
    }

    func testDocumentWithoutSchemaVersionKey_DefaultsToCurrentSchemaVersion() throws {
        let noVersion = Data("{}".utf8)
        let decoded = try JSONDecoder().decode(EasyKeySettings.self, from: noVersion)
        XCTAssertEqual(decoded.schemaVersion, EasyKeySettings.currentSchemaVersion)
    }

    func testFullSettingsJSONRoundTrip_PreservesCustomTranslationOptions() throws {
        var settings = EasyKeySettings.defaults
        settings.translation.preferredProviderID = .anthropic
        settings.translation.acknowledgedCloudDisclosureProviders = [.anthropic]

        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(EasyKeySettings.self, from: data)
        XCTAssertEqual(decoded.translation, settings.translation)
    }
}
