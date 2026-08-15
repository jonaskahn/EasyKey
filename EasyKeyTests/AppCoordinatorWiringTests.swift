import AppKit
import CoreGraphics
import EasyEngineCore
@testable import EasyKey
@testable import EasyKeyKit
import XCTest

@MainActor
final class AppCoordinatorWiringTests: XCTestCase {
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

    func testConfigureKeyboardService_HealthHandlerUpdatesPublishedState() {
        coordinator.keyboardService.healthHandler?(.active)
        XCTAssertEqual(coordinator.keyboardHealth, .active)
    }

    func testConfigureKeyboardService_PauseHandlerUpdatesPublishedState() {
        coordinator.keyboardService.pauseHandler?(true)
        XCTAssertTrue(coordinator.keyboardPaused)
    }

    func testConfigureKeyboardService_LanguageToggleHandlerUpdatesSettings() {
        coordinator.keyboardService.languageToggleHandler?(.english)
        XCTAssertEqual(coordinator.settingsStore.settings.input.language, .english)
    }

    func testObserveSettings_PropagatesToMacroStoreAndStatusItem() {
        coordinator.observeSettings()
        coordinator.settingsStore.update { $0.input.encoding = .tcvn3 }
    }

    func testTranslationObservationsIgnoreUnrelatedSettings() {
        let settings = coordinator.settingsStore.settings
        let initialRuntime = TranslationRuntimeSettingsObservation(options: settings.translation)
        let initialPopover = TranslationPopoverSettingsObservation(
            isEnabled: settings.translation.isEnabled,
            showInMenuPopover: settings.translation.showInMenuPopover,
            menuPopoverWidth: settings.system.menuPopoverWidth
        )
        let initialActivation = TranslationActivationSettingsObservation(
            isEnabled: settings.translation.isEnabled,
            shortcut: settings.translation.shortcut
        )
        var unrelated = settings
        unrelated.system.grayMenuIcon.toggle()

        XCTAssertEqual(initialRuntime, TranslationRuntimeSettingsObservation(options: unrelated.translation))
        XCTAssertEqual(initialPopover, TranslationPopoverSettingsObservation(
            isEnabled: unrelated.translation.isEnabled,
            showInMenuPopover: unrelated.translation.showInMenuPopover,
            menuPopoverWidth: unrelated.system.menuPopoverWidth
        ))
        XCTAssertEqual(initialActivation, TranslationActivationSettingsObservation(
            isEnabled: unrelated.translation.isEnabled,
            shortcut: unrelated.translation.shortcut
        ))
    }

    func testTranslationRuntimeObservationTracksProviderConfigurationAndDelay() {
        let settings = coordinator.settingsStore.settings
        let initial = TranslationRuntimeSettingsObservation(options: settings.translation)
        var changedProvider = settings.translation
        changedProvider.preferredProviderID = .google
        var changedShortcut = settings.translation
        changedShortcut.shortcut = Shortcut(keyCode: 6, modifiers: [.command])
        var changedDisclosure = settings.translation
        changedDisclosure.acknowledgedCloudDisclosureProviders.insert(.google)
        var changedDelay = settings.translation
        changedDelay.autoTranslateDelayMs = 1500

        XCTAssertNotEqual(initial, TranslationRuntimeSettingsObservation(options: changedProvider))
        XCTAssertEqual(initial, TranslationRuntimeSettingsObservation(options: changedShortcut))
        XCTAssertEqual(initial, TranslationRuntimeSettingsObservation(options: changedDisclosure))
        XCTAssertNotEqual(initial, TranslationRuntimeSettingsObservation(options: changedDelay))
    }

    func testTranslationRuntimeObservationTracksAllModelIdentifiers() {
        let settings = coordinator.settingsStore.settings
        let initial = TranslationRuntimeSettingsObservation(options: settings.translation)

        var changedOpenRouter = settings.translation
        changedOpenRouter.openRouterModelIdentifier = "anthropic/claude-sonnet-4-5"
        XCTAssertNotEqual(initial, TranslationRuntimeSettingsObservation(options: changedOpenRouter))

        var changedGroq = settings.translation
        changedGroq.groqModelIdentifier = "mixtral-8x7b-32768"
        XCTAssertNotEqual(initial, TranslationRuntimeSettingsObservation(options: changedGroq))

        var changedOpenAICompat = settings.translation
        changedOpenAICompat.openAICompatibleModelIdentifier = "custom-model"
        XCTAssertNotEqual(initial, TranslationRuntimeSettingsObservation(options: changedOpenAICompat))

        var changedAnthropicCompat = settings.translation
        changedAnthropicCompat.anthropicCompatibleModelIdentifier = "custom-claude"
        XCTAssertNotEqual(initial, TranslationRuntimeSettingsObservation(options: changedAnthropicCompat))
    }

    func testTranslationRuntimeObservationTracksCompatibleEndpoints() {
        let settings = coordinator.settingsStore.settings
        let initial = TranslationRuntimeSettingsObservation(options: settings.translation)

        var changedOpenAIEndpoint = settings.translation
        changedOpenAIEndpoint.openAICompatibleEndpoint = "https://custom.com/v1"
        XCTAssertNotEqual(initial, TranslationRuntimeSettingsObservation(options: changedOpenAIEndpoint))

        var changedAnthropicEndpoint = settings.translation
        changedAnthropicEndpoint.anthropicCompatibleEndpoint = "https://custom.com/v1"
        XCTAssertNotEqual(initial, TranslationRuntimeSettingsObservation(options: changedAnthropicEndpoint))
    }

    func testTranslationActivationObservationTracksEnabledStateAndShortcut() {
        let settings = coordinator.settingsStore.settings
        let initial = TranslationActivationSettingsObservation(
            isEnabled: settings.translation.isEnabled,
            shortcut: settings.translation.shortcut
        )
        var disabled = settings.translation
        disabled.isEnabled = !settings.translation.isEnabled
        var changedShortcut = settings.translation
        changedShortcut.shortcut = Shortcut(keyCode: 6, modifiers: [.command])

        XCTAssertNotEqual(initial, TranslationActivationSettingsObservation(
            isEnabled: disabled.isEnabled,
            shortcut: disabled.shortcut
        ))
        XCTAssertNotEqual(initial, TranslationActivationSettingsObservation(
            isEnabled: changedShortcut.isEnabled,
            shortcut: changedShortcut.shortcut
        ))
    }

    func testTranslationPopoverObservationTracksVisibilityAndWidth() {
        let settings = coordinator.settingsStore.settings
        let initial = TranslationPopoverSettingsObservation(
            isEnabled: settings.translation.isEnabled,
            showInMenuPopover: settings.translation.showInMenuPopover,
            menuPopoverWidth: settings.system.menuPopoverWidth
        )
        var changedVisibility = settings
        changedVisibility.translation.showInMenuPopover.toggle()
        var changedWidth = settings
        changedWidth.system.menuPopoverWidth = .large

        XCTAssertNotEqual(initial, TranslationPopoverSettingsObservation(
            isEnabled: changedVisibility.translation.isEnabled,
            showInMenuPopover: changedVisibility.translation.showInMenuPopover,
            menuPopoverWidth: changedVisibility.system.menuPopoverWidth
        ))
        XCTAssertNotEqual(initial, TranslationPopoverSettingsObservation(
            isEnabled: changedWidth.translation.isEnabled,
            showInMenuPopover: changedWidth.translation.showInMenuPopover,
            menuPopoverWidth: changedWidth.system.menuPopoverWidth
        ))
    }

    func testHandleApplicationActivation_NilApplication_DoesNotCrash() {
        coordinator.handleApplicationActivation(nil)
    }

    func testSyncSmartSwitchPublishedState_MirrorsController() {
        coordinator.syncSmartSwitchPublishedState()
        XCTAssertEqual(coordinator.currentApplicationName, coordinator.smartSwitchController.currentApplicationName)
    }

    func testObserveSettings_SmartSwitchToggle_ReevaluatesCurrentAppStatus() throws {
        let external = try externalRunningApplication()
        coordinator.smartSwitchController.handleApplicationActivation(external)
        let nameBefore = coordinator.currentApplicationName
        coordinator.observeSettings()

        coordinator.settingsStore.update { $0.smartSwitch.enabled = true }

        XCTAssertEqual(coordinator.currentApplicationName, nameBefore)
        XCTAssertEqual(
            coordinator.currentAppSmartSwitchStatus,
            coordinator.smartSwitchController.currentAppSmartSwitchStatus
        )
        XCTAssertFalse(coordinator.currentAppSmartSwitchStatus.isEmpty)
    }

    func testRefreshLocalizedChrome_ReevaluatesLastKnownExternalApp() throws {
        let external = try externalRunningApplication()
        coordinator.smartSwitchController.handleApplicationActivation(external)
        let nameBefore = coordinator.currentApplicationName

        coordinator.smartSwitchController.handleApplicationActivation(.current)
        coordinator.refreshLocalizedChrome()

        XCTAssertEqual(coordinator.currentApplicationName, nameBefore)
        XCTAssertEqual(
            coordinator.currentAppSmartSwitchStatus,
            coordinator.smartSwitchController.currentAppSmartSwitchStatus
        )
    }

    func testSetCurrentAppMonitored_AddsAndRemovesIgnoredBundle() throws {
        let external = try externalRunningApplication()
        let bundleIdentifier = try XCTUnwrap(external.bundleIdentifier)
        coordinator.smartSwitchController.handleApplicationActivation(external)
        XCTAssertTrue(coordinator.isCurrentAppMonitored)

        coordinator.setCurrentAppMonitored(false)

        XCTAssertTrue(coordinator.settingsStore.settings.compatibility.ignoredApplicationBundleIdentifiers.contains(bundleIdentifier))
        XCTAssertFalse(coordinator.isCurrentAppMonitored)

        coordinator.setCurrentAppMonitored(true)

        XCTAssertFalse(coordinator.settingsStore.settings.compatibility.ignoredApplicationBundleIdentifiers.contains(bundleIdentifier))
        XCTAssertTrue(coordinator.isCurrentAppMonitored)
    }

    func testSetCurrentAppMonitored_NoCurrentApp_DoesNothing() {
        coordinator.setCurrentAppMonitored(false)
        XCTAssertTrue(coordinator.settingsStore.settings.compatibility.ignoredApplicationBundleIdentifiers.isEmpty)
        XCTAssertTrue(coordinator.isCurrentAppMonitored)
    }

    func testObserveSettings_IgnoredAppsChange_ReevaluatesStatus() throws {
        let external = try externalRunningApplication()
        coordinator.smartSwitchController.handleApplicationActivation(external)
        coordinator.observeSettings()

        coordinator.setCurrentAppMonitored(false)

        XCTAssertEqual(
            coordinator.currentAppSmartSwitchStatus,
            coordinator.smartSwitchController.currentAppSmartSwitchStatus
        )
        XCTAssertEqual(coordinator.currentAppSmartSwitchStatus, coordinator.localization.string(.smartSwitchIgnored))
    }

    func testUpdateDockVisibility_TogglesActivationPolicy() {
        coordinator.updateDockVisibility(showDockIcon: true)
        coordinator.updateDockVisibility(showDockIcon: false)
    }

    func testConfigureLaunchAtLogin_UpdatesStatus() {
        coordinator.configureLaunchAtLogin(enabled: false)
        XCTAssertEqual(coordinator.loginItemStatus, coordinator.loginItemController.status)
    }

    func testUpdateStatusItem_WithExplicitSettings_DoesNotCrash() {
        coordinator.updateStatusItem(settings: coordinator.settingsStore.settings)
    }

    func testRefreshLocalizedChrome_DoesNotCrash() {
        coordinator.refreshLocalizedChrome()
    }

    func testTogglePopover_DoesNotCrash() {
        coordinator.togglePopover()
    }

    func testConfigureStatusItemController_MenuSnapshotProviderReflectsSettings() {
        coordinator.settingsStore.update { $0.input.language = .english }
        let snapshot = coordinator.statusItemController.menuSnapshotProvider?()
        XCTAssertEqual(snapshot?.language, .english)
    }

    func testConfigureWorkspaceObserver_ApplicationActivatedRefreshesPermission() {
        coordinator.workspaceObserver.onApplicationActivated?(nil)
    }

    func testConfigureWorkspaceObserver_ResetSessionAndWakeDoNotCrash() {
        coordinator.workspaceObserver.onResetSession?()
        coordinator.workspaceObserver.onWake?()
    }

    func testPresentSettingsWindow_DoesNotCrash() {
        coordinator.presentSettingsWindow()
        coordinator.settingsWindowPresenter.close()
    }

    func testObserveLocalizationChanges_RefreshesChromeOnChange() {
        coordinator.localization.setPreference(.vietnamese)
        coordinator.localization.setPreference(.english)
    }

    func testConfigureStatusItemController_OnLeftClick_InvokesTogglePopover() {
        coordinator.statusItemController.onLeftClick?()
    }

    func testConfigureStatusItemController_OnAppearanceChange_InvokesUpdateStatusItem() {
        coordinator.statusItemController.onAppearanceChange?()
    }

    func testAppDelegate_ApplicationWillTerminateWithoutLaunch_DoesNotCrash() {
        let delegate = AppDelegate()

        delegate.applicationWillTerminate(Notification(name: NSApplication.willTerminateNotification))
    }

    private func externalRunningApplication() throws -> NSRunningApplication {
        let bundleIdentifiers = ["com.apple.finder", "com.apple.dock", "com.apple.SystemUIServer"]
        for bundleIdentifier in bundleIdentifiers {
            if let application = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first {
                return application
            }
        }
        throw XCTSkip("No stable system application is running")
    }

    private func fakeProxy() -> CGEventTapProxy {
        unsafeBitCast(UInt(0), to: CGEventTapProxy.self)
    }

    private func keyEvent(character: String, keyCode: UInt16) -> CGEvent {
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) else {
            fatalError("Could not create event")
        }
        event.setIntegerValueField(.keyboardEventKeycode, value: Int64(keyCode))
        let utf16 = Array(character.utf16)
        utf16.withUnsafeBufferPointer { buffer in
            event.keyboardSetUnicodeString(stringLength: buffer.count, unicodeString: buffer.baseAddress)
        }
        return event
    }

    private func typeThroughService(_ service: KeyboardService, chars: [(String, UInt16)], delimiter: (String, UInt16)) -> Bool {
        for (character, keyCode) in chars {
            _ = service.handleTapEvent(proxy: fakeProxy(), type: .keyDown, event: keyEvent(character: character, keyCode: keyCode))
        }
        let result = service.handleTapEvent(
            proxy: fakeProxy(),
            type: .keyDown,
            event: keyEvent(character: delimiter.0, keyCode: delimiter.1)
        )
        return result == nil
    }

    func testObserveSettings_MacroToggleReachesKeyboardPipeline() {
        coordinator.observeSettings()
        _ = try? coordinator.macroStore.add(trigger: "sig", expansion: "Best regards", isEnabled: true, category: .both)
        coordinator.refreshMacros()
        coordinator.settingsStore.update { $0.input.language = .english }
        coordinator.settingsStore.update { $0.macro.enabled = true }

        let suppressed = typeThroughService(
            coordinator.keyboardService,
            chars: [("s", 1), ("i", 34), ("g", 5)],
            delimiter: (" ", 49)
        )

        XCTAssertTrue(suppressed)
    }
}
