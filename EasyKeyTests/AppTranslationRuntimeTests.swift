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
    private var events: [String]!

    override func setUpWithError() throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppTranslationRuntimeTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        settingsStore = SettingsStore(fileURL: tempDirectory.appendingPathComponent("settings.json"))
        let defaults = UserDefaults(suiteName: "AppTranslationRuntimeTests-\(UUID().uuidString)")!
        localization = LocalizationStore(defaults: defaults, bundle: .main)
        credentials = InMemoryTranslationCredentialStore()
        capture = TestTranslationCapture()
        registrar = TestTranslationHotKeyRegistrar()
        panelWindow = RuntimePanelWindow()
        panelMonitor = RuntimePanelMonitor()
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

    func testPopoverAndPanelUseSameModel() {
        let runtime = makeRuntime()
        let configuration = runtime.makePopoverConfiguration {}

        XCTAssertTrue(configuration.model === runtime.model)
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

    func testSetupActionRoutesToTranslationSettings() {
        let runtime = makeRuntime()
        var opened = false
        runtime.onOpenSettings = { opened = true }
        let configuration = runtime.makePopoverConfiguration { runtime.onOpenSettings?() }

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
                speech: nil
            )
        )
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
}

@MainActor
private final class RuntimePanelMonitor: TranslationPanelEventMonitoring {
    private(set) var removedMonitorCount = 0

    func addLocalMonitor(
        panelWindowNumber _: @escaping () -> Int?,
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
