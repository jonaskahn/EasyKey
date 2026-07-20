import AppKit
import EasyEngineCore
@testable import EasyKey
import SwiftUI
import XCTest

@MainActor
private final class FakeCredentialValidator: TranslationCredentialValidating {
    struct Call {
        let provider: TranslationProviderID
        let credential: String
        let options: TranslationOptions
    }

    var result = true
    var error: Error?
    private(set) var calls: [Call] = []

    func validate(
        _ credential: String,
        for provider: TranslationProviderID,
        options: TranslationOptions
    ) async throws -> Bool {
        calls.append(Call(provider: provider, credential: credential, options: options))
        if let error {
            throw error
        }
        return result
    }
}

private final class CredentialStoreSpy: TranslationCredentialStoring, @unchecked Sendable {
    private(set) var credentialReadCount = 0
    private var credentials: [TranslationProviderID: String] = [:]

    func hasCredential(for provider: TranslationProviderID) throws -> Bool {
        credentials[provider] != nil
    }

    func credential(for provider: TranslationProviderID) throws -> String? {
        credentialReadCount += 1
        return credentials[provider]
    }

    func save(_ apiKey: String, for provider: TranslationProviderID) throws {
        credentials[provider] = apiKey
    }

    func deleteCredential(for provider: TranslationProviderID) throws {
        credentials.removeValue(forKey: provider)
    }
}

@MainActor
final class TranslationSettingsModelTests: XCTestCase {
    private var directory: URL!
    private var settingsURL: URL!
    private var settingsStore: SettingsStore!
    private var credentialStore: InMemoryTranslationCredentialStore!
    private var validator: FakeCredentialValidator!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("TranslationSettings-\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        settingsURL = directory.appendingPathComponent("settings.json")
        settingsStore = SettingsStore(fileURL: settingsURL)
        credentialStore = InMemoryTranslationCredentialStore()
        validator = FakeCredentialValidator()
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testSectionOrderPlacesTranslationImmediatelyAfterEncoding() {
        XCTAssertEqual(SettingsSection.allCases, [
            .typing, .encoding, .smartSwitch, .translation, .clipboard, .macros, .behavior, .system, .about,
        ])
        XCTAssertEqual(SettingsSection.translation.symbol, "character.bubble")
    }

    func testRuntimeFilteringRemovesEveryAppleSurfaceOnMacOS14() {
        settingsStore.update { $0.translation.preferredProviderID = .apple }
        let model = makeModel(supportsApple: false)
        XCTAssertFalse(model.selectableProviders.contains(.apple))
        XCTAssertFalse(model.visibleProviderCards.contains(.apple))
        XCTAssertEqual(model.selectableProviders.first, .automatic)
        XCTAssertEqual(model.visibleProviderCards, TranslationProviderResolver.cloudProviderOrder)
        XCTAssertEqual(model.preferredProvider, .automatic)
        XCTAssertEqual(settingsStore.settings.translation.preferredProviderID, .apple)
    }

    func testRuntimeFilteringShowsAppleFirstOnMacOS15() {
        let model = makeModel(supportsApple: true)
        XCTAssertEqual(model.selectableProviders.prefix(2), [.automatic, .apple])
        XCTAssertEqual(model.visibleProviderCards.first, .apple)
    }

    func testGeneralProviderSourceEndpointModelsAndDisclosurePersist() async {
        let model = makeModel()
        model.setPreferredProvider(.gemini)
        model.setDefaultSourceLanguage(.english)
        model.setDeepLEndpoint(.pro)
        XCTAssertTrue(model.setModelIdentifier("gpt-4.1-mini", for: .openAI))
        settingsStore.update { $0.translation.acknowledgedCloudDisclosureProviders = [.google, .gemini] }
        model.resetCloudDisclosures()
        await settingsStore.saveNow()

        let reloaded = SettingsStore(fileURL: settingsURL)
        XCTAssertEqual(reloaded.settings.translation.preferredProviderID, .gemini)
        XCTAssertEqual(reloaded.settings.translation.defaultSourceLanguage, .english)
        XCTAssertEqual(reloaded.settings.translation.deepLEndpoint, .pro)
        XCTAssertEqual(reloaded.settings.translation.openAIModelIdentifier, "gpt-4.1-mini")
        XCTAssertTrue(reloaded.settings.translation.acknowledgedCloudDisclosureProviders.isEmpty)
    }

    func testShowInMenuPopoverTogglePersists() async {
        let model = makeModel()
        XCTAssertFalse(model.showInMenuPopover)
        model.setShowInMenuPopover(true)
        XCTAssertTrue(model.showInMenuPopover)
        await settingsStore.saveNow()

        let reloaded = SettingsStore(fileURL: settingsURL)
        XCTAssertTrue(reloaded.settings.translation.showInMenuPopover)
    }

    func testAutoTranslateDelayPersists() async {
        let model = makeModel()
        XCTAssertEqual(model.autoTranslateDelayMs, 500)
        model.setAutoTranslateDelayMs(1000)
        XCTAssertEqual(model.autoTranslateDelayMs, 1000)
        model.setAutoTranslateDelayMs(99)
        XCTAssertEqual(model.autoTranslateDelayMs, 1000)
        await settingsStore.saveNow()

        let reloaded = SettingsStore(fileURL: settingsURL)
        XCTAssertEqual(reloaded.settings.translation.autoTranslateDelayMs, 1000)
    }

    func testPanelSizePersists() async {
        let model = makeModel()
        XCTAssertEqual(model.panelSize, .medium)
        model.setPanelSize(.large)
        XCTAssertEqual(model.panelSize, .large)
        await settingsStore.saveNow()

        let reloaded = SettingsStore(fileURL: settingsURL)
        XCTAssertEqual(reloaded.settings.translation.panelSize, .large)
    }

    func testSessionPersistencePersists() async {
        let model = makeModel()
        XCTAssertEqual(model.sessionPersistence, .keepUntilRestart)
        model.setSessionPersistence(.clearOnClose)
        XCTAssertEqual(model.sessionPersistence, .clearOnClose)
        await settingsStore.saveNow()

        let reloaded = SettingsStore(fileURL: settingsURL)
        XCTAssertEqual(reloaded.settings.translation.sessionPersistence, .clearOnClose)
    }

    func testIsEnabledTogglePersistsAndNotifiesRuntime() async {
        let model = makeModel()
        var callbackCount = 0
        model.onEnabledChange = { callbackCount += 1 }

        XCTAssertFalse(model.isEnabled)
        model.setIsEnabled(true)
        await settingsStore.saveNow()

        let reloaded = SettingsStore(fileURL: settingsURL)
        XCTAssertTrue(reloaded.settings.translation.isEnabled)
        XCTAssertEqual(callbackCount, 1)
    }

    func testInvalidModelIdentifierDoesNotOverwritePersistedValue() {
        let model = makeModel()
        let original = model.modelIdentifier(for: .anthropic)
        XCTAssertFalse(model.setModelIdentifier("bad/model", for: .anthropic))
        XCTAssertFalse(model.setModelIdentifier("", for: .anthropic))
        XCTAssertFalse(model.setModelIdentifier(String(repeating: "a", count: 101), for: .anthropic))
        XCTAssertEqual(model.modelIdentifier(for: .anthropic), original)
        XCTAssertTrue(TranslationSettingsModel.isValidModelIdentifier("claude-3.5_test"))
    }

    func testSaveValidateInvalidAndDeleteCredentialState() async throws {
        let model = makeModel()
        XCTAssertTrue(model.saveCredential(" secret-value ", for: .openAI))
        XCTAssertEqual(model.credentialStatuses[.openAI], .saved)
        XCTAssertEqual(try credentialStore.credential(for: .openAI), "secret-value")

        let validated = await model.validateCredential("replacement-value", for: .openAI)
        XCTAssertTrue(validated)
        XCTAssertEqual(model.credentialStatuses[.openAI], .ready)
        XCTAssertEqual(validator.calls.map(\.provider), [.openAI])
        XCTAssertEqual(validator.calls.first?.credential, "replacement-value")
        XCTAssertEqual(try credentialStore.credential(for: .openAI), "replacement-value")

        validator.result = false
        let invalid = await model.validateCredential("invalid-value", for: .openAI)
        XCTAssertFalse(invalid)
        XCTAssertEqual(model.credentialStatuses[.openAI], .invalid)
        model.deleteCredential(for: .openAI)
        XCTAssertEqual(model.credentialStatuses[.openAI], .missing)
        XCTAssertNil(try credentialStore.credential(for: .openAI))
    }

    func testBlankSaveFailsAndMissingValidationDoesNotCallValidator() async {
        let model = makeModel()
        XCTAssertFalse(model.saveCredential("  ", for: .google))
        XCTAssertEqual(model.credentialStatuses[.google], .missing)
        let validated = await model.validateCredential("", for: .deepL)
        XCTAssertFalse(validated)
        XCTAssertEqual(model.credentialStatuses[.deepL], .missing)
        XCTAssertTrue(validator.calls.isEmpty)
    }

    func testDeepLEndpointIsPassedToValidation() async {
        let model = makeModel()
        model.setDeepLEndpoint(.pro)
        XCTAssertTrue(model.saveCredential("key", for: .deepL))
        let validated = await model.validateCredential("key", for: .deepL)
        XCTAssertTrue(validated)
        XCTAssertEqual(validator.calls.first?.options.deepLEndpoint, .pro)
    }

    func testShortcutPersistenceAndConflictStatusUseInjectedSeam() {
        let conflict = Shortcut(keyCode: 11, modifiers: [.command, .shift])
        let model = makeModel(shortcutApplier: { shortcut in
            .conflict(attempted: shortcut, active: nil)
        })
        model.setShortcut(conflict)
        XCTAssertEqual(settingsStore.settings.translation.shortcut, conflict)
        XCTAssertEqual(model.shortcutRegistrationState, .conflict(attempted: conflict, active: nil))
    }

    func testSecretNeverEntersSettingsOrPublishedModelState() throws {
        let secret = "must-not-appear-anywhere"
        let model = makeModel()
        XCTAssertTrue(model.saveCredential(secret, for: .gemini))

        let encoded = try JSONEncoder().encode(settingsStore.settings)
        XCTAssertFalse(String(bytes: encoded, encoding: .utf8)?.contains(secret) == true)
        let publishedDescription = String(describing: model.credentialStatuses)
            + String(describing: model.storedCredentialProviders)
            + String(describing: model.shortcutRegistrationState)
            + String(describing: model.lastCredentialErrorProvider)
        XCTAssertFalse(publishedDescription.contains(secret))
    }

    func testSettingsModelNeverReloadsCredentialFromStore() async {
        let spy = CredentialStoreSpy()
        let model = TranslationSettingsModel(
            settingsStore: settingsStore,
            platformCapability: TranslationPlatformCapability(supportsAppleTranslation: false),
            credentialStore: spy,
            credentialValidator: validator
        )

        XCTAssertTrue(model.saveCredential("secret", for: .gemini))
        _ = await model.validateCredential("replacement", for: .gemini)
        model.refreshCredentialStatuses()
        XCTAssertEqual(spy.credentialReadCount, 0)
    }

    func testSettingsViewRendersAtWindowMinimumWithLargeTextAndNoCredential() {
        let model = makeModel(supportsApple: false)
        let view = TranslationSettingsView(model: model)
            .environment(\.dynamicTypeSize, .accessibility2)
        let host = NSHostingView(rootView: view)
        host.frame = NSRect(x: 0, y: 0, width: 508, height: 440)
        host.layoutSubtreeIfNeeded()
        XCTAssertGreaterThan(host.fittingSize.height, 0)
    }

    func testAccessibilityIdentifiersAreStableAndUnique() {
        let identifiers = TranslationSettingsModel.cloudProviders.map(TranslationSettingsAccessibility.credentialField)
            + [
                TranslationSettingsAccessibility.enableToggle,
                TranslationSettingsAccessibility.providerPicker,
                TranslationSettingsAccessibility.sourcePicker,
                TranslationSettingsAccessibility.shortcutStatus,
                TranslationSettingsAccessibility.disclosureReset,
                TranslationSettingsAccessibility.appleLanguageSettings,
            ]
        XCTAssertEqual(Set(identifiers).count, identifiers.count)
        XCTAssertFalse(identifiers.contains(where: \.isEmpty))
    }

    func testCredentialSaveDeleteAndRefreshPropagateErrorsToStatus() {
        let throwingStore = TranslationStatusThrowingStore()
        let model = TranslationSettingsModel(
            settingsStore: settingsStore,
            platformCapability: TranslationPlatformCapability(supportsAppleTranslation: false),
            credentialStore: throwingStore,
            credentialValidator: validator
        )

        XCTAssertFalse(model.saveCredential("key", for: .openAI))
        XCTAssertNotNil(model.lastCredentialErrorProvider)

        model.deleteCredential(for: .openAI)
        XCTAssertNotNil(model.lastCredentialErrorProvider)

        model.refreshCredentialStatuses()
        XCTAssertEqual(model.credentialStatuses[.openAI], .invalid)
        XCTAssertNotNil(model.lastCredentialErrorProvider)
    }

    func testSetDeepLEndpoint_WhenReady_ResetsToSaved() async {
        let model = makeModel()
        _ = await model.validateCredential("key", for: .deepL)
        XCTAssertEqual(model.credentialStatuses[.deepL], .ready)
        model.setDeepLEndpoint(.pro)
        XCTAssertEqual(model.credentialStatuses[.deepL], .saved)
    }

    func testSetCompatibleEndpoints_TrimsWhitespace() {
        let model = makeModel()
        model.setOpenAICompatibleEndpoint("  https://custom.com  ")
        XCTAssertEqual(model.openAICompatibleEndpoint(), "https://custom.com")
        model.setAnthropicCompatibleEndpoint("  https://custom.com  ")
        XCTAssertEqual(model.anthropicCompatibleEndpoint(), "https://custom.com")
    }

    func testValidateCredential_WithThrowingValidator_SetsInvalid() async {
        let throwingValidator = FakeCredentialValidator()
        throwingValidator.error = URLError(.badServerResponse)
        let model = TranslationSettingsModel(
            settingsStore: settingsStore,
            platformCapability: TranslationPlatformCapability(supportsAppleTranslation: false),
            credentialStore: credentialStore,
            credentialValidator: throwingValidator
        )
        let result = await model.validateCredential("key", for: .openAI)
        XCTAssertFalse(result)
        XCTAssertEqual(model.credentialStatuses[.openAI], .invalid)
        XCTAssertNotNil(model.lastCredentialErrorProvider)
    }

    func testLiveValidatorMapsHTTPStatusForOpenAIAndAnthropic() async throws {
        let session = URLSession(configuration: {
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [MockValidatorURLProtocol.self]
            return config
        }())
        let validator = LiveTranslationCredentialValidator(session: session)

        MockValidatorURLProtocol.nextStatus = 200
        let openAI = try await validator.validate("key", for: .openAI, options: settingsStore.settings.translation)
        XCTAssertTrue(openAI)

        MockValidatorURLProtocol.nextStatus = 401
        let anthropic = try await validator.validate("key", for: .anthropic, options: settingsStore.settings.translation)
        XCTAssertFalse(anthropic)

        MockValidatorURLProtocol.nextStatus = 500
        do {
            _ = try await validator.validate("key", for: .google, options: settingsStore.settings.translation)
            XCTFail("Expected throw for status 500")
        } catch {}

        MockValidatorURLProtocol.nextStatus = 200
        let openRouter = try await validator.validate("key", for: .openRouter, options: settingsStore.settings.translation)
        XCTAssertTrue(openRouter)

        MockValidatorURLProtocol.nextStatus = 200
        let groq = try await validator.validate("key", for: .groq, options: settingsStore.settings.translation)
        XCTAssertTrue(groq)

        MockValidatorURLProtocol.nextStatus = 200
        let deepL = try await validator.validate("key", for: .deepL, options: settingsStore.settings.translation)
        XCTAssertTrue(deepL)

        MockValidatorURLProtocol.nextStatus = 200
        let gemini = try await validator.validate("key", for: .gemini, options: settingsStore.settings.translation)
        XCTAssertTrue(gemini)
    }

    func testLiveValidatorReturnsFalseForAutomaticAppleAndEmptyCompatibleEndpoints() async throws {
        let validator = LiveTranslationCredentialValidator()
        let automatic = try await validator.validate("key", for: .automatic, options: settingsStore.settings.translation)
        XCTAssertFalse(automatic)

        let apple = try await validator.validate("key", for: .apple, options: settingsStore.settings.translation)
        XCTAssertFalse(apple)

        let openAIEmpty = try await validator.validate("key", for: .openAICompatible, options: settingsStore.settings.translation)
        XCTAssertFalse(openAIEmpty)

        let anthropicEmpty = try await validator.validate("key", for: .anthropicCompatible, options: settingsStore.settings.translation)
        XCTAssertFalse(anthropicEmpty)
    }

    func testLiveValidatorReturnsTrueForCompatibleWithEndpoint() async throws {
        let validator = LiveTranslationCredentialValidator()
        var options = settingsStore.settings.translation
        options.openAICompatibleEndpoint = "https://custom.com/v1"
        options.anthropicCompatibleEndpoint = "https://custom.com/v1"

        let openAI = try await validator.validate("key", for: .openAICompatible, options: options)
        XCTAssertTrue(openAI)

        let anthropic = try await validator.validate("key", for: .anthropicCompatible, options: options)
        XCTAssertTrue(anthropic)
    }

    private func makeModel(
        supportsApple: Bool = false,
        shortcutApplier: TranslationSettingsModel.ShortcutApplier? = nil
    ) -> TranslationSettingsModel {
        TranslationSettingsModel(
            settingsStore: settingsStore,
            platformCapability: TranslationPlatformCapability(supportsAppleTranslation: supportsApple),
            credentialStore: credentialStore,
            credentialValidator: validator,
            shortcutApplier: shortcutApplier
        )
    }
}

private final class TranslationStatusThrowingStore: TranslationCredentialStoring {
    func hasCredential(for _: TranslationProviderID) throws -> Bool {
        throw TranslationCredentialError.unexpectedStatus(-1)
    }

    func credential(for _: TranslationProviderID) throws -> String? {
        throw TranslationCredentialError.unexpectedStatus(-1)
    }

    func save(_: String, for _: TranslationProviderID) throws {
        throw TranslationCredentialError.unexpectedStatus(-1)
    }

    func deleteCredential(for _: TranslationProviderID) throws {
        throw TranslationCredentialError.unexpectedStatus(-1)
    }
}

private final class MockValidatorURLProtocol: URLProtocol {
    static var nextStatus: Int = 200

    override static func canInit(with _: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: Self.nextStatus,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data())
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
