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

private final class FakeModelCatalog: TranslationModelCatalogProviding, @unchecked Sendable {
    func fetchModels(
        for _: TranslationProviderID
    ) async throws(TranslationModelCatalogError) -> [TranslationModelCatalogEntry] {
        []
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
        XCTAssertTrue(model.saveCredential("test-key", for: .openAI))
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
        XCTAssertTrue(model.saveCredential("test-key", for: .anthropic))
        let original = model.modelIdentifier(for: .anthropic)
        XCTAssertFalse(model.setModelIdentifier("bad/model", for: .anthropic))
        XCTAssertFalse(model.setModelIdentifier("", for: .anthropic))
        XCTAssertFalse(model.setModelIdentifier(String(repeating: "a", count: 101), for: .anthropic))
        XCTAssertEqual(model.modelIdentifier(for: .anthropic), original)
        XCTAssertTrue(TranslationSettingsModel.isValidModelIdentifier("claude-3.5_test", for: .anthropic))
    }

    func testSetModelIdentifier_RequiresSavedCredential() {
        let model = makeModel()
        XCTAssertFalse(model.canManageModels(for: .openAI))
        XCTAssertFalse(model.setModelIdentifier("gpt-4.1-mini", for: .openAI))
        XCTAssertTrue(model.saveCredential("test-key", for: .openAI))
        XCTAssertTrue(model.canManageModels(for: .openAI))
        XCTAssertTrue(model.setModelIdentifier("gpt-4.1-mini", for: .openAI))
        model.deleteCredential(for: .openAI)
        XCTAssertFalse(model.canManageModels(for: .openAI))
        XCTAssertFalse(model.setModelIdentifier("gpt-4o", for: .openAI))
        XCTAssertEqual(model.modelIdentifier(for: .openAI), "gpt-4.1-mini")
    }

    func testOpenRouterCanManageModelsAndSetIdentifierWithoutCredential() {
        let model = makeModel()
        XCTAssertTrue(model.canManageModels(for: .openRouter))
        XCTAssertTrue(model.setModelIdentifier("openai/gpt-4o-mini", for: .openRouter))
        XCTAssertEqual(model.modelIdentifier(for: .openRouter), "openai/gpt-4o-mini")
    }

    func testLoadModelCatalog_LoadsOpenRouterWithoutCredential() {
        let model = makeModel()
        model.loadModelCatalog(for: .openRouter)
        XCTAssertEqual(model.modelCatalogStates[.openRouter], .loading)
    }

    func testSanitizedCredential_StripsPasteArtifacts() {
        XCTAssertEqual(
            TranslationSettingsModel.sanitizedCredential("\u{FEFF} sk-test-key \n"),
            "sk-test-key"
        )
        XCTAssertEqual(
            TranslationSettingsModel.sanitizedCredential("\u{200B}abc\u{200D}"),
            "abc"
        )
        XCTAssertEqual(TranslationSettingsModel.sanitizedCredential("   \n"), "")
    }

    func testSaveCredential_SanitizesBeforeStore() {
        let model = makeModel()
        XCTAssertTrue(model.saveCredential("\u{FEFF} pasted-key \n", for: .openAI))
        XCTAssertEqual(try credentialStore.credential(for: .openAI), "pasted-key")
    }

    func testModelIdentifierValidationAllowsPathSeparatorForOpenRouterAndCompatible() {
        XCTAssertTrue(TranslationSettingsModel.isValidModelIdentifier("openai/gpt-4o-mini", for: .openRouter))
        XCTAssertTrue(TranslationSettingsModel.isValidModelIdentifier("google/gemini-2.5-flash:free", for: .openRouter))
        XCTAssertTrue(TranslationSettingsModel.isValidModelIdentifier("openai/gpt-4o-mini", for: .groq))
        XCTAssertTrue(TranslationSettingsModel.isValidModelIdentifier("openai/gpt-4o-mini", for: .openAICompatible))
        XCTAssertTrue(TranslationSettingsModel.isValidModelIdentifier("openai/gpt-4o-mini", for: .anthropicCompatible))
        XCTAssertFalse(TranslationSettingsModel.isValidModelIdentifier("openai/gpt-4o-mini", for: .openAI))
        XCTAssertFalse(TranslationSettingsModel.isValidModelIdentifier("google/gemini-2.5-flash:free", for: .openAI))
        XCTAssertFalse(TranslationSettingsModel.isValidModelIdentifier("openai/gpt-4o-mini", for: .anthropic))
        XCTAssertFalse(TranslationSettingsModel.isValidModelIdentifier("openai/gpt-4o-mini", for: .gemini))
    }

    func testModelIdentifierValidationMaxLength() {
        XCTAssertFalse(TranslationSettingsModel.isValidModelIdentifier(String(repeating: "a", count: 101), for: .openAI))
        XCTAssertFalse(TranslationSettingsModel.isValidModelIdentifier("", for: .openAI))
        XCTAssertTrue(TranslationSettingsModel.isValidModelIdentifier(String(repeating: "a", count: 100), for: .openAI))
        XCTAssertTrue(TranslationSettingsModel.isValidModelIdentifier("a", for: .openAI))
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
        let fakeCatalog = FakeModelCatalog()
        let model = TranslationSettingsModel(
            settingsStore: settingsStore,
            platformCapability: TranslationPlatformCapability(supportsAppleTranslation: false),
            credentialStore: spy,
            credentialValidator: validator,
            modelCatalog: fakeCatalog
        )

        XCTAssertTrue(model.saveCredential("secret", for: .gemini))
        let readCountAfterSave = spy.credentialReadCount
        let validated = await model.validateCredential("replacement", for: .gemini)
        XCTAssertTrue(validated)
        model.cancelModelCatalogLoad(for: .gemini)
        XCTAssertEqual(spy.credentialReadCount, readCountAfterSave)
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
            + TranslationSettingsModel.cloudProviders.map(TranslationSettingsAccessibility.providerRow)
            + TranslationSettingsModel.cloudProviders.map(TranslationSettingsAccessibility.providerDisclosure)
            + [
                TranslationSettingsAccessibility.enableToggle,
                TranslationSettingsAccessibility.providerRow(.automatic),
                TranslationSettingsAccessibility.providerSelection(.automatic),
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

    func testSaveCredential_TriggersModelCatalogLoad_ForOfficialProvider() {
        let model = makeModel()
        model.saveCredential("test-key", for: .openAI)
        XCTAssertEqual(model.modelCatalogStates[.openAI], .loading)
    }

    func testSaveCredential_DoesNotTriggerCatalogLoad_ForNonOfficialProvider() {
        let model = makeModel()
        model.saveCredential("test-key", for: .deepL)
        XCTAssertNil(model.modelCatalogStates[.deepL])
        model.saveCredential("test-key", for: .google)
        XCTAssertNil(model.modelCatalogStates[.google])
    }

    func testValidateCredential_SuccessTriggersCatalogLoad() async {
        let model = makeModel()
        _ = await model.validateCredential("test-key", for: .openAI)
        XCTAssertEqual(model.modelCatalogStates[.openAI], .loading)
    }

    func testDeleteCredential_ClearsCatalogState() async {
        let model = makeModel()
        _ = await model.validateCredential("test-key", for: .openAI)
        model.deleteCredential(for: .openAI)
        XCTAssertEqual(model.modelCatalogStates[.openAI], .idle)
    }

    func testLoadModelCatalog_SetsLoadingState_WhenCredentialSaved() {
        let model = makeModel()
        model.saveCredential("test-key", for: .openAI)
        XCTAssertEqual(model.modelCatalogStates[.openAI], .loading)
    }

    func testLoadModelCatalog_SkipsWhenNoCredential() {
        let model = makeModel()
        model.loadModelCatalog(for: .openAI)
        XCTAssertNil(model.modelCatalogStates[.openAI])
    }

    func testLoadModelCatalog_SkipsWhenProviderNotOfficial() {
        let model = makeModel()
        model.saveCredential("test-key", for: .deepL)
        model.loadModelCatalog(for: .deepL)
        XCTAssertNil(model.modelCatalogStates[.deepL])
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
