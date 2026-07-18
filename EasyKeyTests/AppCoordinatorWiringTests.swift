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
