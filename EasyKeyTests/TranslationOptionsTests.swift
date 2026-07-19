@testable import EasyEngineCore
import XCTest

final class TranslationOptionsTests: XCTestCase {
    // MARK: - Defaults

    func testDefaults_MatchApprovedProductDecisions() {
        let options = TranslationOptions()
        XCTAssertNil(options.preferredProviderID, "Automatic preference is represented as nil, not .automatic")
        XCTAssertEqual(options.shortcut, Shortcut(keyCode: 0, modifiers: [.option]))
        XCTAssertNil(options.defaultSourceLanguage, "Default source is automatic detection")
        XCTAssertEqual(options.openAIModelIdentifier, TranslationOptions.defaultOpenAIModelIdentifier)
        XCTAssertEqual(options.anthropicModelIdentifier, TranslationOptions.defaultAnthropicModelIdentifier)
        XCTAssertEqual(options.geminiModelIdentifier, TranslationOptions.defaultGeminiModelIdentifier)
        XCTAssertEqual(options.deepLEndpoint, .free)
        XCTAssertTrue(options.acknowledgedCloudDisclosureProviders.isEmpty)
    }

    func testDefaultShortcut_DisplaysAsOptionA() {
        XCTAssertEqual(TranslationOptions().shortcut.displayLabel, "\u{2325} + A")
    }

    // MARK: - Coding round trip

    func testJSONRoundTrip_PreservesEveryField() throws {
        var options = TranslationOptions()
        options.preferredProviderID = .deepL
        options.shortcut = Shortcut(keyCode: 1, modifiers: [.option, .command])
        options.defaultSourceLanguage = .vietnamese
        options.openAIModelIdentifier = "custom-model"
        options.deepLEndpoint = .pro
        options.acknowledgedCloudDisclosureProviders = [.deepL, .openAI]

        let data = try JSONEncoder().encode(options)
        let decoded = try JSONDecoder().decode(TranslationOptions.self, from: data)
        XCTAssertEqual(decoded, options)
    }

    // MARK: - No secrets or translation content in Codable representation

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

    // MARK: - EasyKeySettings integration

    func testEasyKeySettings_DefaultsIncludeTranslationOptions() {
        XCTAssertEqual(EasyKeySettings.defaults.translation, TranslationOptions())
    }

    func testCurrentSchemaVersion_IsFive() {
        XCTAssertEqual(EasyKeySettings.currentSchemaVersion, 5)
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
