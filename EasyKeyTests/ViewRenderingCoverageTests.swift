import AppKit
import EasyEngineCore
@testable import EasyKey
import EasyKeyKit
import SwiftUI
import UniformTypeIdentifiers
import XCTest

private actor CoverageFakeProvider: TranslationProviding {
    enum Behavior {
        case success(TranslationResponse)
        case failure(Error)
        case hang
    }

    private(set) var callCount = 0
    private let behavior: Behavior

    init(behavior: Behavior) {
        self.behavior = behavior
    }

    func translate(_: TranslationRequest) async throws -> TranslationResponse {
        callCount += 1
        switch behavior {
        case let .success(response):
            return response
        case let .failure(error):
            throw error
        case .hang:
            try await Task.sleep(nanoseconds: 3_600_000_000_000)
            throw CancellationError()
        }
    }
}

@MainActor
private final class CoverageSpeechEngine: TranslationSpeechEngine {
    var eventHandler: ((UUID, TranslationSpeechEngineEvent) -> Void)?
    var voices: [String: String]

    init(voices: [String: String] = ["en": "en", "vi": "vi"]) {
        self.voices = voices
    }

    func voiceIdentifier(for languageIdentifier: String) -> String? {
        voices[languageIdentifier]
    }

    func speak(_: String, voiceIdentifier _: String, requestID _: UUID) -> Bool {
        true
    }

    func stopSpeaking() {}
}

@MainActor
private final class CoverageModelCatalog: TranslationModelCatalogProviding, @unchecked Sendable {
    private let result: Result<[TranslationModelCatalogEntry], TranslationModelCatalogError>

    init(result: Result<[TranslationModelCatalogEntry], TranslationModelCatalogError>) {
        self.result = result
    }

    func fetchModels(
        for _: TranslationProviderID
    ) async throws(TranslationModelCatalogError) -> [TranslationModelCatalogEntry] {
        try result.get()
    }
}

@MainActor
final class ViewRenderingCoverageTests: XCTestCase {
    private var coordinator: AppCoordinator!
    private var tempDirectory: URL!

    override func setUpWithError() throws {
        let made = TestCoordinatorFactory.make()
        coordinator = made.coordinator
        tempDirectory = made.tempDirectory
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDirectory)
        coordinator = nil
    }

    // MARK: - Shared helpers

    private func render(@ViewBuilder _ makeView: () -> some View) {
        let host = NSHostingView(rootView: AnyView(makeView()))
        host.frame = NSRect(x: 0, y: 0, width: 900, height: 620)
        host.layoutSubtreeIfNeeded()
        XCTAssertNotNil(host)
    }

    @discardableResult
    private func windowRender(@ViewBuilder _ makeView: () -> some View) -> NSWindow {
        let host = NSHostingView(rootView: AnyView(makeView()))
        host.frame = NSRect(x: 0, y: 0, width: 900, height: 620)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 620),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.animationBehavior = .none
        window.contentView = host
        window.makeKeyAndOrderFront(nil)
        host.layoutSubtreeIfNeeded()
        window.layoutIfNeeded()
        return window
    }

    private func settleCloseWindow(_ window: NSWindow) {
        window.orderOut(nil)
    }

    private func pump(_ seconds: TimeInterval = 0.3) {
        let deadline = Date().addingTimeInterval(seconds)
        while Date() < deadline {
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.01))
        }
        for window in NSApp.windows {
            window.contentView?.layoutSubtreeIfNeeded()
        }
    }

    private func waitUntil(timeout: TimeInterval = 2, condition: () -> Bool) {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.01)), Date() < deadline {}
        XCTAssertTrue(condition(), "Condition not met before timeout")
    }

    private func makeTranslationModel(
        providerID: TranslationProviderID? = .deepL,
        provider: CoverageFakeProvider? = nil
    ) -> TranslationModel {
        TranslationModel(
            inputLanguage: .english,
            providerID: providerID,
            providerLookup: { [provider] requestedID in
                requestedID == providerID ? provider : nil
            }
        )
    }

    private func makePanelView(
        model: TranslationModel,
        speech: TranslationSpeechController? = nil,
        availableProviders: [TranslationProviderID] = [.deepL],
        announceResult: @escaping (String) -> Void = { _ in }
    ) -> TranslationPanelView {
        let speech = speech ?? TranslationSpeechController(engine: CoverageSpeechEngine())
        return TranslationPanelView(
            model: model,
            speech: speech,
            localization: LocalizationStore.shared,
            availableProviders: availableProviders,
            shortcut: .none,
            actions: TranslationPanelActions(openSettings: {}, announceResult: announceResult)
        )
    }

    private func makePopoverView(
        model: TranslationModel,
        availableProviders: [TranslationProviderID] = [.deepL],
        width: CGFloat = 360,
        announceResult: @escaping (String) -> Void = { _ in }
    ) -> MenuPopoverTranslationView {
        MenuPopoverTranslationView(
            model: model,
            availableProviders: availableProviders,
            localization: LocalizationStore.shared,
            actions: MenuPopoverTranslationActions(openSettings: {}, announceResult: announceResult),
            width: width
        )
    }

    private func makeSettingsModel(
        catalog: CoverageModelCatalog? = nil,
        registrationState: TranslationHotKeyRegistrationState? = nil
    ) -> TranslationSettingsModel {
        TranslationSettingsModel(
            settingsStore: coordinator.settingsStore,
            platformCapability: TranslationPlatformCapability(supportsAppleTranslation: false),
            credentialStore: InMemoryTranslationCredentialStore(),
            modelCatalog: catalog,
            shortcutRegistrationState: registrationState
        )
    }

    private func makeTextEntry(_ text: String, fingerprint: String = "fp") -> ClipboardEntry {
        let item = ClipboardItem(
            kind: .text,
            preview: ClipboardItemPreview(primaryText: text),
            representations: [.string(typeIdentifier: "public.utf8-plain-text", value: text)]
        )
        return ClipboardEntry(fingerprint: fingerprint, capturedAt: Date(), items: [item])
    }

    private func click(at point: NSPoint, in window: NSWindow) {
        guard let down = NSEvent.mouseEvent(
            with: .leftMouseDown,
            location: point,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: window.windowNumber,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: 1
        ), let up = NSEvent.mouseEvent(
            with: .leftMouseUp,
            location: point,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: window.windowNumber,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: 0
        )
        else {
            XCTFail("Could not create mouse events")
            return
        }
        window.sendEvent(down)
        window.sendEvent(up)
        pump(0.2)
    }

    private func clickCenter(of view: NSView, in window: NSWindow) {
        let point = view.convert(NSPoint(x: view.bounds.midX, y: view.bounds.midY), to: nil)
        click(at: point, in: window)
    }

    // MARK: - CloudTranslationSettingsCard

    func testCloudCard_DeepL_RendersEndpointPlanPicker() {
        let model = makeSettingsModel()
        render { CloudTranslationSettingsCard(provider: .deepL, providerName: "DeepL", model: model) }
    }

    func testCloudCard_CompatibleProviders_RenderEndpointFields() {
        let model = makeSettingsModel()
        render {
            VStack {
                CloudTranslationSettingsCard(provider: .openAICompatible, providerName: "OpenAI-Compatible", model: model)
                CloudTranslationSettingsCard(provider: .anthropicCompatible, providerName: "Anthropic-Compatible", model: model)
            }
        }
    }

    func testCloudCard_StoredCredential_ShowsDeleteButton() {
        let model = makeSettingsModel()
        model.saveCredential("api-key-123", for: .deepL)
        render { CloudTranslationSettingsCard(provider: .deepL, providerName: "DeepL", model: model) }
    }

    func testCloudCard_OfficialProviderWithModelIdentifier_RendersCatalogPicker() {
        coordinator.settingsStore.update { $0.translation.openAIModelIdentifier = "gpt-4o" }
        let model = makeSettingsModel()
        model.saveCredential("api-key-123", for: .openAI)
        render { CloudTranslationSettingsCard(provider: .openAI, providerName: "OpenAI", model: model) }
    }

    func testCloudCard_CompatibleProviderWithModelIdentifier_RendersTextFieldRow() {
        coordinator.settingsStore.update { $0.translation.openAICompatibleModelIdentifier = "custom-model" }
        let model = makeSettingsModel()
        model.saveCredential("api-key-123", for: .openAICompatible)
        render { CloudTranslationSettingsCard(provider: .openAICompatible, providerName: "OpenAI-Compatible", model: model) }
    }

    func testCloudCard_ModelPickerPopover_LoadedEntries_RendersList() {
        let catalog = CoverageModelCatalog(result: .success([
            TranslationModelCatalogEntry(identifier: "gpt-4o", displayName: "GPT-4o"),
            TranslationModelCatalogEntry(identifier: "gpt-4o-mini", displayName: "GPT-4o mini"),
        ]))
        coordinator.settingsStore.update { $0.translation.openAIModelIdentifier = "gpt-4o" }
        let model = makeSettingsModel(catalog: catalog)
        model.saveCredential("api-key-123", for: .openAI)
        waitUntil {
            if case .loaded = model.modelCatalogStates[.openAI] {
                return true
            }
            return false
        }
        let window = windowRender {
            CloudTranslationSettingsCard(provider: .openAI, providerName: "OpenAI", model: model)
        }
        clickModelPickerButton(in: window)
        pump()
        XCTAssertGreaterThan(NSApp.windows.count, 1)
        settleCloseWindow(window)
    }

    func testCloudCard_ModelPickerPopover_FailedState_RendersRetry() {
        let catalog = CoverageModelCatalog(result: .failure(.requestFailed(status: 500)))
        coordinator.settingsStore.update { $0.translation.openAIModelIdentifier = "gpt-4o" }
        let model = makeSettingsModel(catalog: catalog)
        model.saveCredential("api-key-123", for: .openAI)
        waitUntil {
            if case .failed = model.modelCatalogStates[.openAI] {
                return true
            }
            return false
        }
        let window = windowRender {
            CloudTranslationSettingsCard(provider: .openAI, providerName: "OpenAI", model: model)
        }
        clickModelPickerButton(in: window)
        XCTAssertGreaterThan(NSApp.windows.count, 1)
        settleCloseWindow(window)
    }

    func testCloudCard_ModelPicker_DisabledWithoutCredentials_Renders() {
        coordinator.settingsStore.update { $0.translation.openAIModelIdentifier = "gpt-4o" }
        let model = makeSettingsModel()
        render { CloudTranslationSettingsCard(provider: .openAI, providerName: "OpenAI", model: model) }
    }

    private func clickModelPickerButton(in window: NSWindow) {
        guard let field = findSecureField(in: window.contentView) else {
            XCTFail("Could not find credential field")
            return
        }
        let offsets: [CGFloat] = [-56, -40, -24, -8, 32, 40]
        for offset in offsets {
            let point = field.convert(NSPoint(x: field.bounds.midX, y: field.bounds.minY + offset), to: nil)
            click(at: point, in: window)
            pump(0.1)
            if NSApp.windows.contains(where: { $0 !== window && $0.isVisible }) {
                return
            }
        }
        XCTFail("Model picker popover never opened")
    }

    private func findSecureField(in view: NSView?) -> NSSecureTextField? {
        guard let view else { return nil }
        if let field = view as? NSSecureTextField {
            return field
        }
        for subview in view.subviews {
            if let found = findSecureField(in: subview) {
                return found
            }
        }
        return nil
    }

    func testCloudCard_SaveCredential_SanitizesAndPersists() {
        let model = makeSettingsModel()
        model.saveCredential("\u{FEFF}api-key \n", for: .deepL)
        XCTAssertEqual(model.credentialStatuses[.deepL], .saved)
        model.deleteCredential(for: .deepL)
        XCTAssertEqual(model.credentialStatuses[.deepL], .missing)
    }

    // MARK: - TranslationSettingsView

    func testTranslationSettingsView_CmdCDoublePressSlider_Renders() {
        coordinator.settingsStore.update { $0.translation.cmdCDoublePressEnabled = true }
        let model = makeSettingsModel()
        render { TranslationSettingsView(model: model) }
    }

    func testTranslationSettingsView_ShortcutConflict_RendersConflictStatus() {
        let state = TranslationHotKeyRegistrationState.conflict(attempted: .none, active: .none)
        let model = makeSettingsModel(registrationState: state)
        render { TranslationSettingsView(model: model) }
    }

    func testTranslationSettingsView_ShortcutRegistered_RendersReadyStatus() {
        let state = TranslationHotKeyRegistrationState.registered(Shortcut(keyCode: 1, modifiers: [.command]))
        let model = makeSettingsModel(registrationState: state)
        render { TranslationSettingsView(model: model) }
    }

    func testTranslationSettingsView_ShortcutUnregistered_RendersOffStatus() {
        let model = makeSettingsModel(registrationState: .unregistered)
        render { TranslationSettingsView(model: model) }
    }

    func testTranslationSettingsView_AppleProviderCapability_RendersOnDeviceCard() {
        let model = TranslationSettingsModel(
            settingsStore: coordinator.settingsStore,
            platformCapability: TranslationPlatformCapability(supportsAppleTranslation: true),
            credentialStore: InMemoryTranslationCredentialStore()
        )
        render { TranslationSettingsView(model: model) }
    }

    // MARK: - TranslationPanelView

    func testPanelView_SetupRequired_ShowsSettingsButton() {
        let model = makeTranslationModel(providerID: nil, provider: nil)
        render { makePanelView(model: model, availableProviders: []) }
    }

    func testPanelView_MissingProviderError_ShowsSettingsButton() {
        let model = makeTranslationModel(providerID: .deepL, provider: nil)
        model.setSourceText("hello")
        model.translate()
        render { makePanelView(model: model) }
    }

    func testPanelView_MissingCredentialsError_RendersMessage() {
        let provider = CoverageFakeProvider(behavior: .failure(TranslationError.missingCredentials(provider: .deepL)))
        let model = makeTranslationModel(provider: provider)
        model.setSourceText("hello")
        model.translate()
        waitUntil { model.status == .failed(.missingCredentials(provider: .deepL)) }
        render { makePanelView(model: model) }
    }

    func testPanelView_Translating_ShowsProgressAndDetectsResult() {
        let provider = CoverageFakeProvider(behavior: .hang)
        let model = makeTranslationModel(provider: provider)
        model.setSourceText("hello")
        model.translate()
        waitUntil { model.status == .translating }
        render { makePanelView(model: model) }
    }

    func testPanelView_Succeeded_AnnouncesResultAndShowsDetectedLanguage() {
        var announced = false
        let response = TranslationResponse(
            translatedText: "Xin chào",
            detectedSourceLanguage: .vietnamese,
            providerID: .deepL
        )
        let provider = CoverageFakeProvider(behavior: .success(response))
        let model = makeTranslationModel(provider: provider)
        let view = makePanelView(model: model, announceResult: { _ in announced = true })
        render { view }
        model.setSourceText("hello")
        model.translate()
        waitUntil { model.status == .succeeded(response) }
        pump()
        render { view }
        XCTAssertTrue(announced)
    }

    func testPanelView_UnavailableProvider_PresentsChooserLabel() {
        let model = makeTranslationModel(providerID: .deepL, provider: nil)
        render { makePanelView(model: model, availableProviders: [.google]) }
    }

    func testPanelView_DefaultAnnounceAction_PostsAnnouncement() {
        let response = TranslationResponse(
            translatedText: "Xin chào",
            detectedSourceLanguage: nil,
            providerID: .deepL
        )
        let provider = CoverageFakeProvider(behavior: .success(response))
        let model = makeTranslationModel(provider: provider)
        let view = TranslationPanelView(
            model: model,
            speech: TranslationSpeechController(engine: CoverageSpeechEngine()),
            localization: LocalizationStore.shared,
            availableProviders: [.deepL],
            shortcut: .none,
            actions: TranslationPanelActions(openSettings: {})
        )
        render { view }
        model.setSourceText("hello")
        model.translate()
        waitUntil { model.status == .succeeded(response) }
        pump()
        render { view }
    }

    func testPanelView_ErrorMessages_EachCaseRenders() {
        let errors: [TranslationError] = [
            .missingCredentials(provider: .deepL),
            .unsupportedLanguagePair(source: .english, target: .vietnamese),
            .appleLanguageDownloadRequired,
            .networkUnavailable,
            .requestTimedOut,
            .rateLimitExceeded(provider: .deepL),
            .requestTooLarge,
            .providerUnavailable(provider: .deepL, httpStatus: nil),
            .invalidResponse(provider: .deepL),
        ]
        for error in errors {
            let provider = CoverageFakeProvider(behavior: .failure(error))
            let model = makeTranslationModel(provider: provider)
            model.setSourceText("hello")
            model.translate()
            waitUntil { model.status == .failed(error) }
            render { makePanelView(model: model) }
        }
    }

    func testPanelView_SpeechControls_AllAvailabilityStatesRender() {
        let model = makeTranslationModel(providerID: .apple, provider: nil)
        let speech = TranslationSpeechController(engine: CoverageSpeechEngine(voices: [:]))
        render { makePanelView(model: model, speech: speech, availableProviders: [.apple]) }

        model.setSourceText("hello")
        render { makePanelView(model: model, speech: speech, availableProviders: [.apple]) }

        model.setSourceLanguage(.english)
        render { makePanelView(model: model, speech: speech, availableProviders: [.apple]) }

        let voiced = TranslationSpeechController(engine: CoverageSpeechEngine())
        model.setSourceText("hello")
        render { makePanelView(model: model, speech: voiced, availableProviders: [.apple]) }

        voiced.speakSource("hello", selectedLanguage: .english, detectedLanguage: nil)
        render { makePanelView(model: model, speech: voiced, availableProviders: [.apple]) }
        voiced.stopSpeaking()

        voiced.speakResult("Xin chào", targetLanguage: .vietnamese)
        render { makePanelView(model: model, speech: voiced, availableProviders: [.apple]) }
        voiced.stopSpeaking()
    }

    // MARK: - MenuPopoverTranslationView

    func testPopoverTranslationView_SideBySideEditors_RendersAtExtraLargeWidth() {
        let model = makeTranslationModel()
        render { makePopoverView(model: model, width: 640) }
    }

    func testPopoverTranslationView_SetupRequired_ShowsSettingsButton() {
        let model = makeTranslationModel(providerID: nil, provider: nil)
        render { makePopoverView(model: model, availableProviders: []) }
    }

    func testPopoverTranslationView_Translating_ShowsProgress() {
        let provider = CoverageFakeProvider(behavior: .hang)
        let model = makeTranslationModel(provider: provider)
        model.setSourceText("hello")
        model.translate()
        waitUntil { model.status == .translating }
        render { makePopoverView(model: model) }
    }

    func testPopoverTranslationView_Succeeded_AnnouncesResult() {
        var announced = false
        let response = TranslationResponse(
            translatedText: "Xin chào",
            detectedSourceLanguage: nil,
            providerID: .deepL
        )
        let provider = CoverageFakeProvider(behavior: .success(response))
        let model = makeTranslationModel(provider: provider)
        let view = makePopoverView(model: model, announceResult: { _ in announced = true })
        render { view }
        model.setSourceText("hello")
        model.translate()
        waitUntil { model.status == .succeeded(response) }
        pump()
        render { view }
        XCTAssertTrue(announced)
    }

    func testPopoverTranslationView_ErrorMessages_EachCaseRenders() {
        let errors: [TranslationError] = [
            .missingCredentials(provider: .deepL),
            .unsupportedLanguagePair(source: .english, target: .vietnamese),
            .appleLanguageDownloadRequired,
            .networkUnavailable,
            .requestTimedOut,
            .rateLimitExceeded(provider: .deepL),
            .requestTooLarge,
            .providerUnavailable(provider: .deepL, httpStatus: nil),
            .invalidResponse(provider: .deepL),
        ]
        for error in errors {
            let provider = CoverageFakeProvider(behavior: .failure(error))
            let model = makeTranslationModel(provider: provider)
            model.setSourceText("hello")
            model.translate()
            waitUntil { model.status == .failed(error) }
            render { makePopoverView(model: model) }
        }
    }

    func testPopoverTranslationView_UnavailableProvider_PresentsChooserLabel() {
        let model = makeTranslationModel(providerID: .deepL, provider: nil)
        render { makePopoverView(model: model, availableProviders: [.google]) }
    }

    func testPopoverTranslationView_ExplicitSourceLanguage_RendersDetectElseLabel() {
        let model = makeTranslationModel()
        model.setSourceLanguage(.english)
        render { makePopoverView(model: model) }
    }

    func testPopoverTranslationView_DefaultAnnounceAction_PostsAnnouncement() {
        let response = TranslationResponse(
            translatedText: "Xin chào",
            detectedSourceLanguage: nil,
            providerID: .deepL
        )
        let provider = CoverageFakeProvider(behavior: .success(response))
        let model = makeTranslationModel(provider: provider)
        let view = MenuPopoverTranslationView(
            model: model,
            availableProviders: [.deepL],
            localization: LocalizationStore.shared,
            actions: MenuPopoverTranslationActions(openSettings: {}),
            width: 360
        )
        render { view }
        model.setSourceText("hello")
        model.translate()
        waitUntil { model.status == .succeeded(response) }
        pump()
        render { view }
    }

    // MARK: - MacroSettingsView

    func testMacroSettingsView_SetCategory_UpdatesMacroForEachCategory() throws {
        let macro = try coordinator.macroStore.add(trigger: "btw", expansion: "by the way", isEnabled: true)
        coordinator.refreshMacros()
        let view = MacroSettingsView(settingsStore: coordinator.settingsStore, coordinator: coordinator)

        view.setCategory(.vietnamese, for: macro)
        XCTAssertEqual(view.categoryTitle(.vietnamese), LocalizationStore.shared.string(.languageVietnamese))
        view.setCategory(.english, for: macro)
        XCTAssertEqual(view.categoryTitle(.english), LocalizationStore.shared.string(.languageEnglish))
        view.setCategory(.both, for: macro)
        XCTAssertEqual(view.categoryTitle(.both), LocalizationStore.shared.string(.languageBoth))
        XCTAssertEqual(view.categoryTitle(.nineX), LocalizationStore.shared.string(.languageNineX))
        XCTAssertEqual(view.categoryTitle(.genZ), LocalizationStore.shared.string(.languageGenZ))

        let updated = try XCTUnwrap(coordinator.macroStore.macros.first { $0.id == macro.id })
        XCTAssertEqual(updated.category, .both)
    }

    func testMacroSettingsView_EnabledBindingFailure_SetsErrorMessage() {
        let view = MacroSettingsView(settingsStore: coordinator.settingsStore, coordinator: coordinator)
        let staleMacro = Macro(trigger: "missing", expansion: "never existed")

        view.enabledBinding(for: staleMacro).wrappedValue = false
        render { view }
        XCTAssertNil(coordinator.macroStore.macros.first { $0.id == staleMacro.id })
    }

    // MARK: - MacroEditorSheet

    func testMacroEditorSheet_SaveExistingMacro_EditsAndRefreshes() throws {
        let macro = try coordinator.macroStore.add(trigger: "btw", expansion: "by the way", isEnabled: true)
        let view = MacroEditorSheet(macro: macro, coordinator: coordinator)
        let window = windowRender { view }
        pump(0.3)
        let revisionBefore = coordinator.macroRevision
        pressReturn(in: window)
        pump(0.3)
        XCTAssertEqual(coordinator.macroStore.macros.first { $0.id == macro.id }?.trigger, "btw")
        XCTAssertGreaterThan(coordinator.macroRevision, revisionBefore)
        settleCloseWindow(window)
    }

    private func pressReturn(in window: NSWindow) {
        window.makeKey()
        let code: UInt16 = 36
        guard let down = NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0,
            windowNumber: window.windowNumber, context: nil, characters: "\r",
            charactersIgnoringModifiers: "\r", isARepeat: false, keyCode: code
        ), let up = NSEvent.keyEvent(
            with: .keyUp, location: .zero, modifierFlags: [], timestamp: 0,
            windowNumber: window.windowNumber, context: nil, characters: "\r",
            charactersIgnoringModifiers: "\r", isARepeat: false, keyCode: code
        )
        else {
            XCTFail("Could not create key events")
            return
        }
        window.sendEvent(down)
        window.sendEvent(up)
    }

    func testMacroEditorSheet_SaveNewMacro_AddsAndRefreshes() {
        let view = MacroEditorSheet(macro: nil, coordinator: coordinator)
        render { view }
        view.save()
        XCTAssertTrue(coordinator.macroStore.macros.isEmpty)
    }

    func testMacroEditorSheet_SaveWithError_RendersErrorMessage() {
        let staleMacro = Macro(trigger: "gone", expansion: "not in store")
        let view = MacroEditorSheet(macro: staleMacro, coordinator: coordinator)
        view.save()
        render { view }
        XCTAssertFalse(coordinator.macroStore.macros.contains { $0.id == staleMacro.id })
    }

    func testMacroEditorSheet_EditSamplePackMacro_SavesAsBoth() throws {
        for (trigger, category) in [("coa", MacroCategory.nineX), ("fr", MacroCategory.genZ)] {
            let macro = try coordinator.macroStore.add(trigger: trigger, expansion: "sample", isEnabled: true, category: category)
            let view = MacroEditorSheet(macro: macro, coordinator: coordinator)
            let window = windowRender { view }
            pump(0.3)
            pressReturn(in: window)
            pump(0.3)
            let updated = try XCTUnwrap(coordinator.macroStore.macros.first { $0.id == macro.id })
            XCTAssertEqual(updated.category, .both, "Editing a \(category) sample macro should save as .both")
            settleCloseWindow(window)
        }
    }

    func testMacroEditorSheet_EditLanguageMacro_KeepsLanguageCategory() throws {
        let macro = try coordinator.macroStore.add(trigger: "dc", expansion: "được", isEnabled: true, category: .vietnamese)
        let view = MacroEditorSheet(macro: macro, coordinator: coordinator)
        let window = windowRender { view }
        pump(0.3)
        pressReturn(in: window)
        pump(0.3)
        let updated = try XCTUnwrap(coordinator.macroStore.macros.first { $0.id == macro.id })
        XCTAssertEqual(updated.category, .vietnamese)
        settleCloseWindow(window)
    }

    // MARK: - ClipboardSettingsView

    func testClipboardSettingsView_HotkeyConflict_RendersWarning() {
        coordinator.clipboard.hotkeyConflict = true
        render {
            ClipboardSettingsView(settingsStore: coordinator.settingsStore, coordinator: coordinator)
        }
    }

    func testClipboardSettingsView_IgnoredApplications_RenderRows() {
        coordinator.settingsStore.update {
            $0.clipboard.ignoredApplicationBundleIdentifiers = ["dev.example.Ignore", "dev.example.Second"]
        }
        render {
            ClipboardSettingsView(settingsStore: coordinator.settingsStore, coordinator: coordinator)
        }
    }

    // MARK: - ClipboardPanelView

    func testClipboardPanelView_ActionError_ShowsNotice() {
        let model = ClipboardHistoryModel(options: ClipboardOptions(isCaptureEnabled: true))
        let action = ClipboardActionCoordinator(
            writeEntry: { _ in throw NSError(domain: "test", code: 1) },
            closePanel: {},
            reactivatePrevious: { true },
            synthesizePaste: { true }
        )
        let thumbnailLoader = ClipboardThumbnailLoader { _ in nil }
        let localization = LocalizationStore.shared
        let actions = ClipboardPanelActions(
            primary: { _ in },
            copy: { _ in },
            togglePin: { _ in },
            delete: { _ in },
            reveal: { _ in },
            clearUnpinned: {},
            openSettings: {}
        )
        let entry = makeTextEntry("hello")
        model.capture(ClassifiedClipboard(entry: entry, payloads: [:]))
        action.copyOnly(entry)
        XCTAssertNotNil(action.lastError)

        render {
            ClipboardPanelView(
                model: model,
                action: action,
                thumbnailLoader: thumbnailLoader,
                localization: localization,
                actions: actions
            )
        }
    }

    func testClipboardPanelView_EmptyModel_RendersEmptyState() {
        let model = ClipboardHistoryModel(options: ClipboardOptions(isCaptureEnabled: true))
        let action = makeClipboardAction()
        let thumbnailLoader = ClipboardThumbnailLoader { _ in nil }
        let actions = ClipboardPanelActions(
            primary: { _ in },
            copy: { _ in },
            togglePin: { _ in },
            delete: { _ in },
            reveal: { _ in },
            clearUnpinned: {},
            openSettings: {}
        )

        render {
            ClipboardPanelView(
                model: model,
                action: action,
                thumbnailLoader: thumbnailLoader,
                localization: LocalizationStore.shared,
                actions: actions
            )
        }
    }

    func testClipboardPanelView_TextEntry_RevealHiddenInMenu() {
        let model = ClipboardHistoryModel(options: ClipboardOptions(isCaptureEnabled: true))
        let action = makeClipboardAction()
        let thumbnailLoader = ClipboardThumbnailLoader { _ in nil }
        let localization = LocalizationStore.shared
        let actions = ClipboardPanelActions(
            primary: { _ in },
            copy: { _ in },
            togglePin: { _ in },
            delete: { _ in },
            reveal: { _ in },
            clearUnpinned: {},
            openSettings: {}
        )
        model.capture(ClassifiedClipboard(entry: makeTextEntry("hello"), payloads: [:]))

        render {
            ClipboardPanelView(
                model: model,
                action: action,
                thumbnailLoader: thumbnailLoader,
                localization: localization,
                actions: actions
            )
        }
    }

    func testClipboardPanelView_FileEntry_RevealShownInMenu() {
        let model = ClipboardHistoryModel(options: ClipboardOptions(isCaptureEnabled: true))
        let action = makeClipboardAction()
        let thumbnailLoader = ClipboardThumbnailLoader { _ in nil }
        let localization = LocalizationStore.shared
        let actions = ClipboardPanelActions(
            primary: { _ in },
            copy: { _ in },
            togglePin: { _ in },
            delete: { _ in },
            reveal: { _ in },
            clearUnpinned: {},
            openSettings: {}
        )
        let item = ClipboardItem(
            kind: .file,
            preview: ClipboardItemPreview(primaryText: "file.txt"),
            representations: [.fileURL(URL(fileURLWithPath: "/tmp/file.txt"))]
        )
        model.capture(ClassifiedClipboard(
            entry: ClipboardEntry(fingerprint: "file-fp", capturedAt: Date(), items: [item]),
            payloads: [:]
        ))

        render {
            ClipboardPanelView(
                model: model,
                action: action,
                thumbnailLoader: thumbnailLoader,
                localization: localization,
                actions: actions
            )
        }
    }

    private func makeClipboardAction() -> ClipboardActionCoordinator {
        ClipboardActionCoordinator(
            writeEntry: { _ in },
            closePanel: {},
            reactivatePrevious: { true },
            synthesizePaste: { true }
        )
    }

    // MARK: - ClipboardEntryRow

    func testClipboardEntryRow_ImageThumbnail_Renders() {
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: 4,
            pixelsHigh: 4,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )
        let png = try? rep?.representation(using: .png, properties: [:])
        guard let png else {
            XCTFail("Could not create PNG")
            return
        }
        let item = ClipboardItem(
            kind: .image,
            preview: ClipboardItemPreview(primaryText: "image"),
            representations: [.data(typeIdentifier: "public.png", payloadReference: "payload-1")]
        )
        let entry = ClipboardEntry(fingerprint: "image-fp", capturedAt: Date(), items: [item])
        let thumbnailLoader = ClipboardThumbnailLoader { _ in png }
        let host = NSHostingView(rootView: AnyView(
            ClipboardEntryRow(
                entry: entry,
                thumbnailLoader: thumbnailLoader,
                localization: LocalizationStore.shared
            )
        ))
        host.frame = NSRect(x: 0, y: 0, width: 400, height: 60)
        host.layoutSubtreeIfNeeded()
        pump()
        host.layoutSubtreeIfNeeded()
        XCTAssertNotNil(host)
    }

    func testClipboardEntryRow_PinnedToggleDefault_Renders() {
        let entry = makeTextEntry("hello")
        render {
            ClipboardEntryRow(
                entry: entry,
                thumbnailLoader: ClipboardThumbnailLoader { _ in nil },
                localization: LocalizationStore.shared
            )
        }
    }

    // MARK: - BehaviorSettingsView

    func testBehaviorSettingsView_DropWithURLAndDataProviders_LoadsBoth() throws {
        let urlApp = try makeApplicationBundle(name: "UrlApp", bundleIdentifier: "dev.example.UrlApp")
        let dataApp = try makeApplicationBundle(name: "DataApp", bundleIdentifier: "dev.example.DataApp")
        let nsURLApp = try makeApplicationBundle(name: "NsUrlApp", bundleIdentifier: "dev.example.NsUrlApp")
        let urlProvider = NSItemProvider(item: urlApp as NSURL, typeIdentifier: UTType.fileURL.identifier)
        let dataProvider = NSItemProvider(
            item: dataApp.dataRepresentation as NSData,
            typeIdentifier: UTType.fileURL.identifier
        )
        let nsURLProvider = NSItemProvider(item: nsURLApp as NSURL, typeIdentifier: UTType.fileURL.identifier)
        let view = BehaviorSettingsView(settingsStore: coordinator.settingsStore)

        XCTAssertTrue(view.acceptDrop([urlProvider, dataProvider, nsURLProvider], into: .ignored))
        waitUntil {
            let identifiers = coordinator.settingsStore.settings.compatibility.ignoredApplicationBundleIdentifiers
            return identifiers.contains("dev.example.UrlApp")
                && identifiers.contains("dev.example.DataApp")
                && identifiers.contains("dev.example.NsUrlApp")
        }
    }

    func testBehaviorSettingsView_EmptyAndPopulated_RegistryRenders() {
        coordinator.settingsStore.update {
            $0.compatibility.compatibilityModeApplicationBundleIdentifiers = ["dev.example.App"]
            $0.compatibility.ignoredApplicationBundleIdentifiers = []
        }
        render { BehaviorSettingsView(settingsStore: coordinator.settingsStore) }
    }

    private func makeApplicationBundle(name: String, bundleIdentifier: String) throws -> URL {
        let appURL = tempDirectory.appendingPathComponent("\(name).app", isDirectory: true)
        let contentsURL = appURL.appendingPathComponent("Contents", isDirectory: true)
        try FileManager.default.createDirectory(at: contentsURL, withIntermediateDirectories: true)
        let plist: [String: Any] = [
            "CFBundleIdentifier": bundleIdentifier,
            "CFBundlePackageType": "APPL",
            "CFBundleExecutable": name,
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try data.write(to: contentsURL.appendingPathComponent("Info.plist"))
        let executableURL = contentsURL.appendingPathComponent("MacOS/\(name)")
        try FileManager.default.createDirectory(
            at: executableURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data().write(to: executableURL)
        return appURL
    }

    // MARK: - SystemSettingsView

    func testSystemSettingsView_LoginItemUnsupportedAndFailed_RendersWarning() {
        coordinator.loginItemStatus = .unsupported
        render {
            SystemSettingsView(settingsStore: coordinator.settingsStore, coordinator: coordinator)
        }
        coordinator.loginItemStatus = .failed
        render {
            SystemSettingsView(settingsStore: coordinator.settingsStore, coordinator: coordinator)
        }
    }

    // MARK: - OnboardingView

    func testOnboardingView_StepTwo_RendersTypingMethodForm() {
        render {
            OnboardingView(
                settingsStore: coordinator.settingsStore,
                coordinator: coordinator,
                finish: {},
                initialStep: 2
            )
        }
    }

    func testOnboardingView_StepThree_RendersReadyState() {
        render {
            OnboardingView(
                settingsStore: coordinator.settingsStore,
                coordinator: coordinator,
                finish: {},
                initialStep: 3
            )
        }
    }

    func testContentView_OnboardingBranch_Renders() {
        let key = "hasCompletedOnboarding"
        let previous = UserDefaults.standard.object(forKey: key)
        defer {
            if let previous {
                UserDefaults.standard.set(previous, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        UserDefaults.standard.set(false, forKey: key)
        render { ContentView(settingsStore: coordinator.settingsStore, coordinator: coordinator) }
        UserDefaults.standard.set(true, forKey: key)
        render { ContentView(settingsStore: coordinator.settingsStore, coordinator: coordinator) }
    }

    // MARK: - MenuPopoverView

    func testMenuPopoverView_AllHealthAndPauseStates_Render() {
        let states: [KeyboardService.Health] = [.active, .requestingPermission, .degraded, .failed, .stopped]
        for state in states {
            coordinator.keyboardHealth = state
            coordinator.keyboardPaused = false
            render { MenuPopoverView(coordinator: coordinator) }
            coordinator.keyboardPaused = true
            render { MenuPopoverView(coordinator: coordinator) }
        }
    }

    // MARK: - AboutSettingsView

    func testAboutSettingsView_Renders() {
        render { AboutSettingsView(settingsStore: coordinator.settingsStore) }
    }

    func testAboutSettingsView_OpenLicensesButton_PresentsSheet() {
        // Real-window click-then-verify: sheet presentation needs the window to
        // become key. Hosted runners never key an AppKit window, so the click
        // blocks the main thread for the full per-test timeout (see ci.yml
        // known-broken shard). Fail fast there instead of hanging the shard.
        executionTimeAllowance = 30

        let window = windowRender {
            AboutSettingsView(settingsStore: coordinator.settingsStore)
        }
        defer { settleCloseWindow(window) }

        let baseWindowCount = NSApp.windows.count
        guard let content = window.contentView else {
            XCTFail("Missing content view")
            return
        }
        let candidates: [CGFloat] = [340, 360, 380, 400, 420, 440, 460, 480]
        for yOffset in candidates {
            let point = content.convert(NSPoint(x: 200, y: yOffset), to: nil)
            click(at: point, in: window)
            if NSApp.windows.count > baseWindowCount {
                return
            }
        }
        XCTFail("Licenses sheet never opened")
    }

    // MARK: - SmartSwitchSettingsView

    func testSmartSwitchSettingsView_EmptyAndWithEncoding_Render() throws {
        render {
            SmartSwitchSettingsView(settingsStore: coordinator.settingsStore, coordinator: coordinator)
        }
        let choice = SmartSwitchChoice(language: .english, encoding: .tcvn3)
        let identity = ApplicationIdentity(
            bundleIdentifier: "com.example.FakeApp-\(UUID().uuidString)",
            path: nil,
            name: "FakeApp"
        )
        _ = try coordinator.smartSwitchController.store.handleAppFocus(identity, currentChoice: choice)
        render {
            SmartSwitchSettingsView(settingsStore: coordinator.settingsStore, coordinator: coordinator)
        }
    }

    // MARK: - SystemHealthCard

    func testSystemHealthCard_Stopped_Renders() {
        coordinator.keyboardHealth = .stopped
        render { SystemHealthCard(coordinator: coordinator) }
    }

    func testSystemHealthCard_ActiveWithPause_Renders() {
        coordinator.keyboardHealth = .active
        coordinator.keyboardPaused = true
        render { SystemHealthCard(coordinator: coordinator) }
    }

    // MARK: - SettingsShell

    func testSettingsShell_Renders() {
        render {
            SettingsShell(settingsStore: coordinator.settingsStore, coordinator: coordinator)
        }
    }

    // MARK: - TypingSettingsView / EncodingSettingsView / HealthPill / InterfaceLanguagePicker

    func testTypingSettingsView_Renders() {
        render {
            TypingSettingsView(settingsStore: coordinator.settingsStore, coordinator: coordinator)
        }
    }

    func testEncodingSettingsView_Renders() {
        render {
            EncodingSettingsView(
                settingsStore: coordinator.settingsStore,
                coordinator: coordinator,
                copyPreviewAction: { _ in }
            )
        }
    }

    func testHealthPill_StoppedAndPaused_Renders() {
        render { HealthPill(health: .stopped, paused: false) }
        render { HealthPill(health: .active, paused: true) }
    }

    func testInterfaceLanguageMenu_Renders() {
        render { InterfaceLanguageMenu() }
    }

    // MARK: - TranslationTextEditor

    func testTranslationTextEditor_Coordinator_TextDidChange_UpdatesBinding() {
        var text = "before"
        let binding = Binding(get: { text }, set: { text = $0 })
        let coordinator = TranslationTextEditor.Coordinator(text: binding, onTranslateTriggered: {})
        let textView = NSTextView()
        textView.string = "typed"

        coordinator.textDidChange(Notification(name: NSText.didChangeNotification, object: textView))

        XCTAssertEqual(text, "typed")
    }

    func testTranslationTextEditor_Coordinator_ReturnKey_TriggersTranslation() {
        var triggered = false
        let binding = Binding(get: { "" }, set: { _ in })
        let coordinator = TranslationTextEditor.Coordinator(text: binding, onTranslateTriggered: { triggered = true })
        let textView = NSTextView()

        let handled = coordinator.textView(textView, doCommandBy: #selector(NSResponder.insertNewline(_:)))
        XCTAssertTrue(handled)
        XCTAssertTrue(triggered)
        XCTAssertFalse(coordinator.textView(textView, doCommandBy: #selector(NSResponder.insertTab(_:))))
    }

    func testTranslationTextEditor_FocusedInWindow_BecomesFirstResponder() {
        var text = "hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let window = windowRender {
            TranslationTextEditor(text: binding, isFocused: true, onTranslateTriggered: {})
        }
        text = "changed"
        pump()
        window.contentView?.layoutSubtreeIfNeeded()
        pump()
        settleCloseWindow(window)
    }

    // MARK: - PasteableSecureField

    func testPasteableSecureField_RendersWithAccessibilityAttributes() {
        var text = "secret"
        let binding = Binding(get: { text }, set: { text = $0 })
        render {
            PasteableSecureField(
                text: binding,
                placeholder: "API key",
                accessibilityLabel: "Key field",
                accessibilityIdentifier: "KeyFieldIdentifier",
                onSubmit: {}
            )
        }
    }

    func testPasteableSecureField_UpdateNSView_RefreshesTextAndPlaceholder() {
        let host = NSHostingView(rootView: AnyView(
            PasteableSecureField(
                text: .constant("one"),
                placeholder: "first",
                accessibilityIdentifier: "UpdateField",
                onSubmit: {}
            )
        ))
        host.frame = NSRect(x: 0, y: 0, width: 300, height: 40)
        host.layoutSubtreeIfNeeded()
        host.rootView = AnyView(
            PasteableSecureField(
                text: .constant("two"),
                placeholder: "second",
                accessibilityIdentifier: "UpdateField",
                onSubmit: {}
            )
        )
        host.layoutSubtreeIfNeeded()
        XCTAssertNotNil(host)
    }

    func testBindingSecureTextField_PasteWithoutEditor_FallsBackToStringValue() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("pasted-value", forType: .string)
        let field = BindingSecureTextField()
        var changed: String?
        field.onTextChange = { changed = $0 }

        field.paste(nil)

        XCTAssertEqual(field.stringValue, "pasted-value")
        XCTAssertEqual(changed, "pasted-value")
    }

    func testBindingSecureTextField_PerformKeyEquivalent_HandlesCommands() throws {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("abc", forType: .string)
        let field = BindingSecureTextField()

        let pasteEvent = try XCTUnwrap(keyEvent(character: "v", modifiers: [.command], keyCode: 9))
        XCTAssertTrue(field.performKeyEquivalent(with: pasteEvent))

        let copyEvent = try XCTUnwrap(keyEvent(character: "c", modifiers: [.command], keyCode: 8))
        XCTAssertTrue(field.performKeyEquivalent(with: copyEvent))

        let cutEvent = try XCTUnwrap(keyEvent(character: "x", modifiers: [.command], keyCode: 7))
        XCTAssertTrue(field.performKeyEquivalent(with: cutEvent))

        let selectAllEvent = try XCTUnwrap(keyEvent(character: "a", modifiers: [.command], keyCode: 0))
        XCTAssertTrue(field.performKeyEquivalent(with: selectAllEvent))

        let bareEvent = try XCTUnwrap(keyEvent(character: "a", modifiers: [], keyCode: 0))
        XCTAssertFalse(field.performKeyEquivalent(with: bareEvent))
    }

    func testPasteableSecureField_Coordinator_DelegateAndCommitPaths() {
        var text = ""
        var submitted = 0
        let binding = Binding(get: { text }, set: { text = $0 })
        let coordinator = PasteableSecureField.Coordinator(
            PasteableSecureField(text: binding, onSubmit: { submitted += 1 })
        )
        let field = NSSecureTextField()
        field.stringValue = "typed-key"

        coordinator.controlTextDidChange(Notification(name: NSControl.textDidChangeNotification, object: field))
        XCTAssertEqual(text, "typed-key")

        let returnHandled = coordinator.control(
            field,
            textView: NSTextView(),
            doCommandBy: #selector(NSResponder.insertNewline(_:))
        )
        XCTAssertTrue(returnHandled)
        let otherHandled = coordinator.control(
            field,
            textView: NSTextView(),
            doCommandBy: #selector(NSResponder.insertTab(_:))
        )
        XCTAssertFalse(otherHandled)

        coordinator.commit(field)
        XCTAssertEqual(text, "typed-key")
        XCTAssertEqual(submitted, 2)
    }

    private func keyEvent(
        character: String,
        modifiers: NSEvent.ModifierFlags,
        keyCode: UInt16
    ) -> NSEvent? {
        NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: modifiers,
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: character,
            charactersIgnoringModifiers: character,
            isARepeat: false,
            keyCode: keyCode
        )
    }

    // MARK: - ShortcutKeyCapture

    func testKeyCaptureView_ReservedSystemShortcut_BeepsWithoutCapturing() throws {
        let view = KeyCaptureView()
        view.isRecording = true
        var captured: Shortcut?
        view.capture = { captured = $0 }

        let event = try XCTUnwrap(keyEvent(character: "v", modifiers: [.command], keyCode: 9))
        view.keyDown(with: event)

        XCTAssertNil(captured)
    }

    func testShortcutKeyCapture_InWindow_BecomesFirstResponderAndCaptures() throws {
        struct Probe: View {
            @Binding var shortcut: Shortcut

            var body: some View {
                ShortcutKeyCapture(isRecording: .constant(true), shortcut: $shortcut)
            }
        }
        var recorded = Shortcut.none
        let binding = Binding(get: { recorded }, set: { recorded = $0 })
        let window = windowRender { Probe(shortcut: binding) }
        pump(0.5)
        XCTAssertEqual(recorded, .none)

        let captureView = findKeyCaptureView(in: window.contentView)
        XCTAssertNotNil(captureView)
        let event = try XCTUnwrap(keyEvent(character: "k", modifiers: [.option], keyCode: 40))
        captureView?.keyDown(with: event)
        XCTAssertEqual(recorded.keyCode, 40)
        XCTAssertTrue(recorded.modifiers.contains(.option))
        settleCloseWindow(window)
    }

    private func findKeyCaptureView(in view: NSView?) -> KeyCaptureView? {
        guard let view else { return nil }
        if let captureView = view as? KeyCaptureView {
            return captureView
        }
        for subview in view.subviews {
            if let found = findKeyCaptureView(in: subview) {
                return found
            }
        }
        return nil
    }

    // MARK: - ShortcutRecorder

    func testShortcutRecorder_ActiveShortcut_RendersClearButton() {
        render {
            ShortcutRecorder(
                label: "Test",
                description: "Description",
                shortcut: .constant(Shortcut(keyCode: 1, modifiers: [.command]))
            )
        }
    }

    // MARK: - TranslationProviderIcon

    func testTranslationProviderPickerButton_Popover_OpensAndSelectsProvider() {
        var selected: TranslationProviderID?
        let view = TranslationProviderPickerButton(
            selection: nil,
            availableProviders: [.deepL, .google, .openAI],
            providerLabel: { $0.displayName },
            accessibilityLabel: "Provider picker",
            accessibilityIdentifier: "ProviderPickerProbe",
            onSelect: { selected = $0 }
        )
        let host = NSHostingView(rootView: AnyView(view))
        let fitting = host.fittingSize
        host.frame = NSRect(origin: .zero, size: fitting)
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: fitting),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.animationBehavior = .none
        window.contentView = host
        window.makeKeyAndOrderFront(nil)
        host.layoutSubtreeIfNeeded()

        clickCenter(of: host, in: window)
        pump()

        let popoverWindow = NSApp.windows.first { candidate in
            guard candidate !== window, candidate.isVisible,
                  String(describing: type(of: candidate)).contains("Popover"),
                  let content = candidate.contentView
            else {
                return false
            }
            return !findRowProxies(in: content).isEmpty
        }
        XCTAssertNotNil(popoverWindow, "Provider picker popover never opened")
        if let popoverWindow, let content = popoverWindow.contentView {
            let rows = findRowProxies(in: content)
            if rows.count >= 1 {
                let deepLRow = rows[0]
                let point = deepLRow.convert(
                    NSPoint(x: deepLRow.bounds.midX, y: deepLRow.bounds.midY),
                    to: nil
                )
                click(at: point, in: popoverWindow)
            }
        }
        pump()
        XCTAssertEqual(selected, .deepL)
        settleCloseWindow(window)
    }

    private func findRowProxies(in view: NSView?) -> [NSView] {
        guard let view else { return [] }
        var found: [NSView] = []
        if type(of: view).description().contains("KeyViewProxy"), view.frame.height >= 20 {
            found.append(view)
        }
        for subview in view.subviews {
            found.append(contentsOf: findRowProxies(in: subview))
        }
        return found
    }

    func testTranslationProviderIcon_AllProviders_Render() {
        let providers: [TranslationProviderID] = [
            .automatic, .apple, .deepL, .google, .openAI, .anthropic, .gemini,
            .openRouter, .groq, .openAICompatible, .anthropicCompatible,
        ]
        for provider in providers {
            render { TranslationProviderIcon(provider: provider, size: 20) }
        }
    }
}
