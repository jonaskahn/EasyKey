import AppKit
import EasyEngineCore
@testable import EasyKey
import SwiftUI
import XCTest

@MainActor
private final class PanelSpeechEngine: TranslationSpeechEngine {
    var eventHandler: ((UUID, TranslationSpeechEngineEvent) -> Void)?
    var voices = ["en": "en", "vi": "vi"]

    func voiceIdentifier(for languageIdentifier: String) -> String? {
        voices[languageIdentifier]
    }

    func speak(_: String, voiceIdentifier _: String, requestID _: UUID) -> Bool {
        true
    }

    func stopSpeaking() {}
}

@MainActor
final class TranslationPanelViewTests: XCTestCase {
    private let response = TranslationResponse(
        translatedText: "Hello",
        detectedSourceLanguage: .vietnamese,
        providerID: .deepL
    )

    func testPresentationCoversBlankReadyLoadingSuccessAndError() {
        let blank = presentation(text: "", status: .idle)
        XCTAssertFalse(blank.canTranslate)
        XCTAssertEqual(blank.disclosure, .cloud(.deepL))

        let ready = presentation(text: "Xin chao", status: .idle)
        XCTAssertTrue(ready.canTranslate)

        let loading = presentation(text: "Xin chao", status: .translating)
        XCTAssertTrue(loading.isTranslating)
        XCTAssertFalse(loading.canTranslate)

        let success = presentation(text: "Xin chao", status: .succeeded(response))
        XCTAssertEqual(success.resultText, "Hello")

        let error = presentation(text: "Xin chao", status: .failed(.networkUnavailable))
        XCTAssertEqual(error.error, .networkUnavailable)
        XCTAssertTrue(error.canTranslate)
    }

    func testPresentationCoversSetupAndDisclosureStates() {
        let setup = TranslationPanelPresentation(
            sourceText: "Hello",
            sourceLanguage: .english,
            targetLanguage: .vietnamese,
            providerID: nil,
            availableProviders: [],
            status: .idle
        )
        XCTAssertTrue(setup.setupRequired)
        XCTAssertEqual(setup.disclosure, .none)

        let local = TranslationPanelPresentation(
            sourceText: "Hello",
            sourceLanguage: .english,
            targetLanguage: .vietnamese,
            providerID: .apple,
            availableProviders: [.apple],
            status: .idle
        )
        XCTAssertEqual(local.disclosure, .local)
    }

    func testPresentationRejectsOversizedEqualLanguageAndUnavailableProvider() {
        XCTAssertFalse(presentation(
            text: String(repeating: "a", count: TranslationRequest.maximumSourceTextLength + 1),
            status: .idle
        ).canTranslate)

        let equal = TranslationPanelPresentation(
            sourceText: "Hello",
            sourceLanguage: .english,
            targetLanguage: .english,
            providerID: .deepL,
            availableProviders: [.deepL],
            status: .idle
        )
        XCTAssertFalse(equal.canTranslate)

        let unavailable = TranslationPanelPresentation(
            sourceText: "Hello",
            sourceLanguage: .english,
            targetLanguage: .vietnamese,
            providerID: .google,
            availableProviders: [.deepL],
            status: .idle
        )
        XCTAssertFalse(unavailable.canTranslate)
    }

    func testAccessibilityIdentifiersAreUniqueAndNonempty() {
        let identifiers = [
            TranslationPanelAccessibility.providerPicker,
            TranslationPanelAccessibility.sourceLanguagePicker,
            TranslationPanelAccessibility.swapButton,
            TranslationPanelAccessibility.targetLanguagePicker,
            TranslationPanelAccessibility.sourceEditor,
            TranslationPanelAccessibility.sourceSpeechButton,
            TranslationPanelAccessibility.resultEditor,
            TranslationPanelAccessibility.resultSpeechButton,
            TranslationPanelAccessibility.settingsButton,
            TranslationPanelAccessibility.status,
            TranslationPanelAccessibility.disclosure,
        ]
        XCTAssertEqual(Set(identifiers).count, identifiers.count)
        XCTAssertFalse(identifiers.contains(where: \.isEmpty))
    }

    func testPronunciationPolicySupportsOnlyAppleAndGoogle() {
        XCTAssertTrue(TranslationPronunciationPolicy.supports(.apple))
        XCTAssertTrue(TranslationPronunciationPolicy.supports(.google))
        XCTAssertFalse(TranslationPronunciationPolicy.supports(.deepL))
        XCTAssertFalse(TranslationPronunciationPolicy.supports(.openAI))
        XCTAssertFalse(TranslationPronunciationPolicy.supports(.anthropic))
        XCTAssertFalse(TranslationPronunciationPolicy.supports(.gemini))
        XCTAssertFalse(TranslationPronunciationPolicy.supports(.automatic))
    }

    func testPanelCopyLocalizesShortcutDisclosureAndAnnouncement() throws {
        let suite = "one.ifelse.easykey.translation-panel.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }
        let localization = LocalizationStore(defaults: defaults, bundle: .main)

        localization.setPreference(.english)
        XCTAssertEqual(
            localization.format(.translationCloudDisclosure, "DeepL"),
            "Submitted source text is sent directly to DeepL after the configured delay or when you choose Translate."
        )
        XCTAssertTrue(localization.format(.translationInstructions, "⌥ + A").contains("⌥ + A"))
        XCTAssertEqual(
            localization.string(.translationResultAnnouncement),
            "Translation complete. Result available."
        )

        localization.setPreference(.vietnamese)
        XCTAssertTrue(localization.format(.translationInstructions, "⌥ + A").contains("⌥ + A"))
        XCTAssertEqual(localization.string(.translationTranslate), "Dịch")
    }

    func testCloudProvidersExposeOfficialDataHandlingURLsAndTrademarks() throws {
        let expectedHosts: [TranslationProviderID: String] = [
            .deepL: "www.deepl.com",
            .google: "cloud.google.com",
            .openAI: "platform.openai.com",
            .anthropic: "privacy.anthropic.com",
            .gemini: "ai.google.dev",
            .openRouter: "openrouter.ai",
            .groq: "groq.com",
            .openAICompatible: "platform.openai.com",
            .anthropicCompatible: "privacy.anthropic.com",
        ]
        for provider in TranslationProviderResolver.cloudProviderOrder {
            let url = try XCTUnwrap(provider.privacyURL)
            XCTAssertEqual(url.scheme, "https")
            XCTAssertEqual(url.host, expectedHosts[provider])
        }
        XCTAssertEqual(TranslationProviderID.google.displayName, "Google Cloud Translation")
        XCTAssertEqual(TranslationProviderID.openAI.displayName, "OpenAI")
        XCTAssertNil(TranslationProviderID.apple.privacyURL)
    }

    func testTranslationNetworkSessionHasNoPersistentStores() {
        let configuration = TranslationNetworkSession.ephemeral.configuration
        XCTAssertEqual(configuration.requestCachePolicy, .reloadIgnoringLocalCacheData)
        XCTAssertNil(configuration.urlCache)
        XCTAssertNil(configuration.httpCookieStorage)
        XCTAssertFalse(configuration.httpShouldSetCookies)
        XCTAssertNil(configuration.urlCredentialStorage)
    }

    func testPanelRendersAtNarrowWidthWithLongTextAndLargeTextSize() {
        let model = TranslationModel(
            inputLanguage: .english,
            providerID: .deepL,
            providerLookup: { _ in nil }
        )
        model.setSourceText(String(repeating: "Long source text ", count: 120))
        model.setSourceLanguage(.english)
        let localization = LocalizationStore.shared
        let view = TranslationPanelView(
            model: model,
            speech: TranslationSpeechController(engine: PanelSpeechEngine()),
            localization: localization,
            availableProviders: [.deepL],
            shortcut: Shortcut(keyCode: 0, modifiers: [.option]),
            actions: TranslationPanelActions(openSettings: {}, announceResult: { _ in })
        )
        .environment(\.dynamicTypeSize, .accessibility2)
        let host = NSHostingView(rootView: view)
        host.frame = NSRect(x: 0, y: 0, width: 420, height: 500)
        host.layoutSubtreeIfNeeded()
        XCTAssertGreaterThan(host.fittingSize.height, 0)
    }

    func testPopoverSectionOrderPlacesTranslationBeforeInputAndStatusAfterInput() {
        XCTAssertEqual(
            MenuPopoverLayout.sectionOrder(hasTranslation: true),
            [.translation, .inputControls, .inputStatus, .footer]
        )
        XCTAssertEqual(
            MenuPopoverLayout.sectionOrder(hasTranslation: false),
            [.inputControls, .inputStatus, .footer]
        )
    }

    func testPopoverConfigurationFiltersAndOrdersProvidersForSimulatedMacOS14And15() {
        let model = TranslationModel(
            inputLanguage: .english,
            providerID: .apple,
            providerLookup: { _ in nil }
        )
        var settingsOpenCount = 0
        let actions = MenuPopoverTranslationActions(openSettings: { settingsOpenCount += 1 })

        let macOS14 = MenuPopoverTranslationConfiguration(
            model: model,
            availableProviders: [.gemini, .apple, .deepL, .automatic],
            platformCapability: .init(supportsAppleTranslation: false),
            actions: actions
        )
        XCTAssertEqual(macOS14.availableProviders, [.deepL, .gemini])
        XCTAssertFalse(macOS14.availableProviders.contains(.apple))
        let hiddenApple = MenuPopoverTranslationPresentation(
            sourceText: "Hello",
            sourceLanguage: .english,
            targetLanguage: .vietnamese,
            providerID: .apple,
            availableProviders: macOS14.availableProviders,
            status: .idle
        )
        XCTAssertEqual(hiddenApple.disclosure, .none)

        let macOS15 = MenuPopoverTranslationConfiguration(
            model: model,
            availableProviders: [.gemini, .apple, .deepL, .automatic],
            platformCapability: .init(supportsAppleTranslation: true),
            actions: actions
        )
        XCTAssertEqual(macOS15.availableProviders, [.apple, .deepL, .gemini])
        macOS15.actions.openSettings()
        XCTAssertEqual(settingsOpenCount, 1)
    }

    func testPopoverPresentationCoversReadyLoadingSuccessErrorAndSetup() {
        XCTAssertTrue(popoverPresentation(text: "Hello", status: .idle).canTranslate)

        let loading = popoverPresentation(text: "Hello", status: .translating)
        XCTAssertTrue(loading.isTranslating)
        XCTAssertFalse(loading.canTranslate)

        let success = popoverPresentation(text: "Hello", status: .succeeded(response))
        XCTAssertEqual(success.resultText, "Hello")

        let error = popoverPresentation(text: "Hello", status: .failed(.networkUnavailable))
        XCTAssertEqual(error.error, .networkUnavailable)

        let setup = MenuPopoverTranslationPresentation(
            sourceText: "Hello",
            sourceLanguage: .english,
            targetLanguage: .vietnamese,
            providerID: nil,
            availableProviders: [],
            status: .idle
        )
        XCTAssertTrue(setup.setupRequired)
        XCTAssertEqual(setup.disclosure, .none)
    }

    func testPopoverAccessibilityIdentifiersAreUniqueAndNonempty() {
        let identifiers = [
            MenuPopoverTranslationAccessibility.section,
            MenuPopoverTranslationAccessibility.providerPicker,
            MenuPopoverTranslationAccessibility.sourceLanguagePicker,
            MenuPopoverTranslationAccessibility.swapButton,
            MenuPopoverTranslationAccessibility.targetLanguagePicker,
            MenuPopoverTranslationAccessibility.sourceEditor,
            MenuPopoverTranslationAccessibility.result,
            MenuPopoverTranslationAccessibility.settingsButton,
            MenuPopoverTranslationAccessibility.status,
            MenuPopoverTranslationAccessibility.disclosure,
        ]
        XCTAssertEqual(Set(identifiers).count, identifiers.count)
        XCTAssertFalse(identifiers.contains(where: \.isEmpty))
    }

    func testPopoverInstructionCopyLocalizesInEnglishAndVietnamese() throws {
        let suite = "one.ifelse.easykey.translation-popover.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }
        let localization = LocalizationStore(defaults: defaults, bundle: .main)

        localization.setPreference(.english)
        XCTAssertTrue(localization.string(.translationEditorInstructions).contains("delay"))
        localization.setPreference(.vietnamese)
        XCTAssertTrue(localization.string(.translationEditorInstructions).contains("độ trễ"))
    }

    private func presentation(text: String, status: TranslationModel.Status) -> TranslationPanelPresentation {
        TranslationPanelPresentation(
            sourceText: text,
            sourceLanguage: .vietnamese,
            targetLanguage: .english,
            providerID: .deepL,
            availableProviders: [.deepL],
            status: status
        )
    }

    private func popoverPresentation(
        text: String,
        status: TranslationModel.Status
    ) -> MenuPopoverTranslationPresentation {
        MenuPopoverTranslationPresentation(
            sourceText: text,
            sourceLanguage: .english,
            targetLanguage: .vietnamese,
            providerID: .deepL,
            availableProviders: [.deepL],
            status: status
        )
    }
}
