import AppKit
import EasyEngineCore
@testable import EasyKey
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

    func testTranslationActivationObservationTracksEnabledStateAndShortcut() {
        let settings = coordinator.settingsStore.settings
        let initial = TranslationActivationSettingsObservation(
            isEnabled: settings.translation.isEnabled,
            shortcut: settings.translation.shortcut
        )
        var disabled = settings.translation
        disabled.isEnabled = false
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
}
