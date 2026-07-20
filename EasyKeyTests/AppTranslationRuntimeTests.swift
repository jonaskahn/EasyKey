import AppKit
import EasyEngineCore
@testable import EasyKey
import SwiftUI
import XCTest

@MainActor
final class AppTranslationRuntimeTests: XCTestCase {
    private var tempDirectory: URL!
    private var settingsStore: SettingsStore!
    private var localization: LocalizationStore!
    private var credentials: InMemoryTranslationCredentialStore!
    private var capture: TestTranslationCapture!
    private var registrar: TestTranslationHotKeyRegistrar!
    private var panelWindow: RuntimePanelWindow!
    private var panelMonitor: RuntimePanelMonitor!
    private var speechEngine: RuntimeSpeechEngine!
    private var events: [String]!

    override func setUpWithError() throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppTranslationRuntimeTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        settingsStore = SettingsStore(fileURL: tempDirectory.appendingPathComponent("settings.json"))
        settingsStore.update {
            $0.translation.isEnabled = true
            $0.translation.showInMenuPopover = true
        }
        let defaults = UserDefaults(suiteName: "AppTranslationRuntimeTests-\(UUID().uuidString)")!
        localization = LocalizationStore(defaults: defaults, bundle: .main)
        credentials = InMemoryTranslationCredentialStore()
        capture = TestTranslationCapture()
        registrar = TestTranslationHotKeyRegistrar()
        panelWindow = RuntimePanelWindow()
        panelMonitor = RuntimePanelMonitor()
        speechEngine = RuntimeSpeechEngine()
        events = []
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    func testNoCloudCredentialOnMacOS14StartsInSetupState() {
        let runtime = makeRuntime()

        runtime.start()

        XCTAssertNil(runtime.model.providerID)
        XCTAssertTrue(runtime.availableProviders.isEmpty)
        XCTAssertEqual(runtime.hotKeyRegistrationState, .registered(settingsStore.settings.translation.shortcut))
    }

    func testStartupPublishesRegisteredShortcutToSettingsModel() {
        let runtime = makeRuntime()

        runtime.start()

        XCTAssertEqual(
            runtime.settingsModel.shortcutRegistrationState,
            .registered(settingsStore.settings.translation.shortcut)
        )
    }

    func testDisabledStartupDoesNotRegisterHotKey() {
        settingsStore.update { $0.translation.isEnabled = false }
        let runtime = makeRuntime()

        runtime.start()

        XCTAssertEqual(registrar.registerCount, 0)
        XCTAssertEqual(runtime.hotKeyRegistrationState, .unregistered)
        XCTAssertEqual(runtime.settingsModel.shortcutRegistrationState, .unregistered)
    }

    func testDisablingUnregistersCancelsSpeechAndClosesPanel() throws {
        try credentials.save("key", for: .google)
        let runtime = makeRuntime()
        runtime.start()
        registrar.handler?()
        runtime.model.setSourceText("hello")
        runtime.model.translate()
        XCTAssertEqual(runtime.model.status, .translating)
        XCTAssertTrue(panelWindow.isVisible)

        runtime.settingsModel.setIsEnabled(false)

        XCTAssertEqual(runtime.hotKeyRegistrationState, .unregistered)
        XCTAssertEqual(runtime.settingsModel.shortcutRegistrationState, .unregistered)
        XCTAssertEqual(runtime.model.status, .idle)
        XCTAssertGreaterThanOrEqual(speechEngine.stopCount, 1)
        XCTAssertFalse(panelWindow.isVisible)
        XCTAssertNil(runtime.makePopoverConfiguration {})
    }

    func testReEnablingRegistersLatestShortcut() {
        let runtime = makeRuntime()
        runtime.start()
        runtime.settingsModel.setIsEnabled(false)
        let latest = Shortcut(keyCode: 6, modifiers: [.command, .option])
        runtime.settingsModel.setShortcut(latest)

        runtime.settingsModel.setIsEnabled(true)

        XCTAssertEqual(runtime.hotKeyRegistrationState, .registered(latest))
        XCTAssertEqual(runtime.settingsModel.shortcutRegistrationState, .registered(latest))
    }

    func testStaleHotKeyCallbackCannotActivateDisabledTranslation() {
        let runtime = makeRuntime()
        runtime.start()
        let staleHandler = registrar.handler
        var captureCount = 0
        capture.onCapture = { captureCount += 1 }
        runtime.settingsModel.setIsEnabled(false)

        staleHandler?()

        XCTAssertEqual(captureCount, 0)
        XCTAssertFalse(panelWindow.isVisible)
    }

    func testShortcutConflictIsPublishedToSettingsModel() {
        let runtime = makeRuntime()
        runtime.start()
        registrar.shouldRegister = false
        let replacement = Shortcut(keyCode: 1, modifiers: [.command, .shift])
        let original = settingsStore.settings.translation.shortcut

        runtime.settingsModel.setShortcut(replacement)

        XCTAssertEqual(
            runtime.settingsModel.shortcutRegistrationState,
            .conflict(attempted: replacement, active: original)
        )
    }

    func testCloudCredentialResolvesFallbackAndCredentialDeletionReturnsToSetup() throws {
        try credentials.save("key", for: .google)
        let runtime = makeRuntime()
        XCTAssertEqual(runtime.model.providerID, .google)

        runtime.settingsModel.deleteCredential(for: .google)

        XCTAssertNil(runtime.model.providerID)
        XCTAssertTrue(runtime.availableProviders.isEmpty)
    }

    func testCredentialChangesNotifySurfacesToRefreshProviderChoices() {
        let runtime = makeRuntime()
        var refreshCount = 0
        runtime.onConfigurationChange = { refreshCount += 1 }

        XCTAssertTrue(runtime.settingsModel.saveCredential("key", for: .google))

        XCTAssertEqual(refreshCount, 1)
        XCTAssertEqual(runtime.availableProviders, [.google])
        XCTAssertEqual(runtime.model.providerID, .google)
    }

    func testSettingsUpdatesProviderSourceAndProviderConfiguration() throws {
        try credentials.save("key", for: .deepL)
        try credentials.save("key", for: .openAI)
        let runtime = makeRuntime()
        runtime.start()
        let initialRevision = runtime.providerRevision

        settingsStore.update {
            $0.translation.preferredProviderID = .openAI
            $0.translation.defaultSourceLanguage = TranslationLanguage(bcp47: "fr")
            $0.translation.deepLEndpoint = .pro
            $0.translation.openAIModelIdentifier = "gpt-4.1-mini"
        }
        runtime.apply(settingsStore.settings)

        XCTAssertEqual(runtime.model.providerID, .openAI)
        XCTAssertEqual(runtime.model.sourceLanguage, TranslationLanguage(bcp47: "fr"))
        XCTAssertGreaterThan(runtime.providerRevision, initialRevision)
    }

    func testUnsupportedProviderResolutionStopsSpeech() throws {
        try credentials.save("key", for: .openAI)
        let runtime = makeRuntime()
        let initialStopCount = speechEngine.stopCount

        runtime.apply(settingsStore.settings)

        XCTAssertEqual(runtime.model.providerID, .openAI)
        XCTAssertGreaterThan(speechEngine.stopCount, initialStopCount)
    }

    func testPopoverAndPanelUseSameModel() throws {
        let runtime = makeRuntime()
        let configuration = try XCTUnwrap(runtime.makePopoverConfiguration {})

        XCTAssertTrue(configuration.model === runtime.model)
    }

    func testPopoverConfigurationReturnsNilWhenMenuPopoverDisabled() {
        let runtime = makeRuntime()
        runtime.settingsModel.setShowInMenuPopover(false)

        XCTAssertNil(runtime.makePopoverConfiguration {})
    }

    func testPopoverConfiguration_SnapshotStoredTrueExplicitFalse_ReturnsNil() {
        let runtime = makeRuntime()
        runtime.settingsModel.setShowInMenuPopover(true)

        var options = settingsStore.settings.translation
        options.showInMenuPopover = false

        XCTAssertNil(runtime.makePopoverConfiguration(options: options) {})
    }

    func testPopoverConfiguration_SnapshotStoredFalseExplicitTrue_ReturnsConfig() {
        let runtime = makeRuntime()
        runtime.settingsModel.setShowInMenuPopover(false)

        var options = settingsStore.settings.translation
        options.showInMenuPopover = true
        options.isEnabled = true

        let config = runtime.makePopoverConfiguration(options: options) {}
        XCTAssertNotNil(config)
    }

    func testPopoverConfiguration_DisabledTranslationAlwaysReturnsNil() {
        let runtime = makeRuntime()

        var options = settingsStore.settings.translation
        options.isEnabled = false
        options.showInMenuPopover = true

        XCTAssertNil(runtime.makePopoverConfiguration(options: options) {})
    }

    func testPopoverConfiguration_EnabledAndVisible_ReturnsSharedModelConfiguration() {
        let runtime = makeRuntime()
        var options = settingsStore.settings.translation
        options.isEnabled = true
        options.showInMenuPopover = true

        let config = runtime.makePopoverConfiguration(options: options) {}
        XCTAssertNotNil(config)
        XCTAssertTrue(config?.model === runtime.model)
    }

    func testShortcutCapturesAndSeedsBeforePanelPresentation() {
        capture.result = SelectedTextCaptureResult(
            text: "selected",
            source: .accessibility,
            accessibilityResult: .text("selected")
        )
        capture.onCapture = { [weak self] in self?.events.append("capture") }
        panelWindow.onReplaceContent = { [weak self] in
            self?.events.append("panel")
            XCTAssertEqual(self?.makeCurrentRuntime?.model.sourceText, "selected")
        }
        let runtime = makeRuntime()
        makeCurrentRuntime = runtime
        runtime.start()

        registrar.handler?()

        XCTAssertEqual(events, ["capture", "panel"])
        XCTAssertEqual(runtime.model.sourceText, "selected")
        XCTAssertTrue(panelWindow.isVisible)
    }

    func testShortcutReplacementConflictKeepsWorkingBinding() {
        let runtime = makeRuntime()
        runtime.start()
        registrar.shouldRegister = false
        let replacement = Shortcut(keyCode: 1, modifiers: [.command, .shift])

        runtime.settingsModel.setShortcut(replacement)

        XCTAssertEqual(
            runtime.hotKeyRegistrationState,
            .conflict(attempted: replacement, active: Shortcut(keyCode: 0, modifiers: [.option]))
        )
        XCTAssertEqual(registrar.unregisterCount, 0)
    }

    func testRepeatedStartStopDoesNotDuplicateRegistrationAndTeardownRemovesResources() {
        let runtime = makeRuntime()

        runtime.start()
        runtime.start()
        XCTAssertEqual(registrar.registerCount, 1)

        registrar.handler?()
        runtime.stop()
        runtime.stop()
        XCTAssertEqual(registrar.unregisterCount, 1)
        XCTAssertEqual(panelWindow.orderOutCount, 1)
        XCTAssertEqual(panelMonitor.removedMonitorCount, 2)

        runtime.start()
        XCTAssertEqual(registrar.registerCount, 2)
        runtime.stop()
        XCTAssertEqual(registrar.unregisterCount, 2)
    }

    func testFirstCloudDisclosurePersistsAndPromptsOnce() throws {
        try credentials.save("key", for: .deepL)
        var promptCount = 0
        let runtime = makeRuntime(disclosurePrompt: { _ in
            promptCount += 1
            return true
        })
        runtime.model.setSourceText("hello")
        runtime.model.translate()

        let first = expectation(description: "first request")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { first.fulfill() }
        wait(for: [first], timeout: 1)
        runtime.model.translate()
        let second = expectation(description: "second request")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { second.fulfill() }
        wait(for: [second], timeout: 1)

        XCTAssertEqual(promptCount, 1)
        XCTAssertTrue(settingsStore.settings.translation.acknowledgedCloudDisclosureProviders.contains(.deepL))
    }

    func testSetupActionRoutesToTranslationSettings() throws {
        let runtime = makeRuntime()
        var opened = false
        runtime.onOpenSettings = { opened = true }
        let configuration = try XCTUnwrap(runtime.makePopoverConfiguration { runtime.onOpenSettings?() })

        configuration.actions.openSettings()

        XCTAssertTrue(opened)
    }

    private var makeCurrentRuntime: AppTranslationRuntime?

    private func makeRuntime(
        disclosurePrompt: TranslationDisclosureController.Prompt? = { _ in true }
    ) -> AppTranslationRuntime {
        AppTranslationRuntime(
            settingsStore: settingsStore,
            localization: localization,
            dependencies: AppTranslationRuntime.Dependencies(
                credentialStore: credentials,
                platformCapability: TranslationPlatformCapability(supportsAppleTranslation: false),
                capture: capture,
                hotKeyRegistrar: registrar,
                disclosurePrompt: disclosurePrompt,
                panelPresenter: { [panelWindow, panelMonitor] model, speech in
                    TranslationPanelPresenter(
                        translation: model,
                        speech: speech,
                        eventMonitor: panelMonitor,
                        panelFactory: { panelWindow },
                        activateEasyKey: {},
                        pointerLocation: { .zero },
                        screenGeometries: { [] }
                    )
                },
                speech: TranslationSpeechController(engine: speechEngine)
            )
        )
    }
}

@MainActor
private final class RuntimeSpeechEngine: TranslationSpeechEngine {
    var eventHandler: ((UUID, TranslationSpeechEngineEvent) -> Void)?
    private(set) var stopCount = 0

    func voiceIdentifier(for _: String) -> String? {
        "voice"
    }

    func speak(_: String, voiceIdentifier _: String, requestID _: UUID) -> Bool {
        true
    }

    func stopSpeaking() {
        stopCount += 1
    }
}

@MainActor
private final class RuntimePanelWindow: TranslationPanelWindow {
    var isVisible = false
    let windowNumber = 42
    var orderOutCount = 0
    var onReplaceContent: (() -> Void)?
    private var closeHandler: (() -> Void)?

    func replaceContent(_: AnyView) {
        onReplaceContent?()
    }

    func setFrameOrigin(_: CGPoint) {}

    func makeKeyAndOrderFront() {
        isVisible = true
    }

    func orderOut() {
        isVisible = false
        orderOutCount += 1
    }

    func setCloseHandler(_ handler: @escaping () -> Void) {
        closeHandler = handler
    }

    func containsWindowNumber(_ windowNumber: Int) -> Bool {
        windowNumber == self.windowNumber
    }
}

@MainActor
private final class RuntimePanelMonitor: TranslationPanelEventMonitoring {
    private(set) var removedMonitorCount = 0

    func addLocalMonitor(
        isPanelOwnedWindow _: @escaping (Int) -> Bool,
        handler _: @escaping (TranslationPanelLocalEvent) -> Bool
    ) -> TranslationPanelMonitorRegistration? {
        registration()
    }

    func addGlobalClickMonitor(handler _: @escaping () -> Void) -> TranslationPanelMonitorRegistration? {
        registration()
    }

    private func registration() -> TranslationPanelMonitorRegistration {
        TranslationPanelMonitorRegistration { [weak self] in self?.removedMonitorCount += 1 }
    }
}
