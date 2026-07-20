import AppKit
import EasyEngineCore
@testable import EasyKey
import XCTest

@MainActor
final class AppCoordinatorTests: XCTestCase {
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

    func testInit_SeedsDefaultDisplayState() {
        XCTAssertFalse(coordinator.currentApplicationName.isEmpty)
        XCTAssertFalse(coordinator.currentAppSmartSwitchStatus.isEmpty)
        XCTAssertEqual(coordinator.keyboardHealth, .stopped)
        XCTAssertFalse(coordinator.keyboardPaused)
    }

    func testSetLanguage_UpdatesSettings() {
        coordinator.setLanguage(.english)
        XCTAssertEqual(coordinator.settingsStore.settings.input.language, .english)
    }

    func testSetInputMethod_UpdatesSettings() {
        coordinator.setInputMethod(.vni)
        XCTAssertEqual(coordinator.settingsStore.settings.input.inputMethod, .vni)
    }

    func testSetEncoding_UpdatesSettings() {
        coordinator.setEncoding(.tcvn3)
        XCTAssertEqual(coordinator.settingsStore.settings.input.encoding, .tcvn3)
    }

    func testSetLaunchAtLogin_UpdatesSettings() {
        coordinator.setLaunchAtLogin(true)
        XCTAssertTrue(coordinator.settingsStore.settings.system.launchAtLogin)
    }

    func testCanCheckForUpdates_AlwaysReturnsTrue() {
        XCTAssertTrue(coordinator.canCheckForUpdates)
    }

    func testCheckForUpdates_DoesNotCrash() {
        coordinator.checkForUpdates()
    }

    func testRestartKeyboardService_DoesNotCrash() {
        coordinator.restartKeyboardService()
    }

    func testConvertClipboard_EmptyPasteboard_DoesNotCrash() {
        NSPasteboard.general.clearContents()
        coordinator.convertClipboard()
    }

    func testRefreshMacros_IncrementsRevision() {
        let before = coordinator.macroRevision
        coordinator.refreshMacros()
        XCTAssertEqual(coordinator.macroRevision, before &+ 1)
    }

    func testSmartSwitchPreferences_InitiallyEmpty() {
        XCTAssertTrue(coordinator.smartSwitchPreferences.isEmpty)
    }

    func testResetSmartSwitchPreference_DoesNotCrashWhenMissing() {
        let preference = SmartSwitchPreference(
            key: "missing",
            displayName: "Missing",
            choice: SmartSwitchChoice(language: .english),
            lastUsedAt: Date()
        )
        coordinator.resetSmartSwitchPreference(preference)
    }

    func testClearSmartSwitchPreferences_DoesNotCrash() {
        coordinator.clearSmartSwitchPreferences()
    }

    func testMenuBarStateTitle_IsNonEmpty() {
        XCTAssertFalse(coordinator.menuBarStateTitle.isEmpty)
    }

    func testRequestAccessibilityPermission_DoesNotCrash() {
        coordinator.requestAccessibilityPermission()
    }

    func testConvertClipboard_WithNoClipboardText_DoesNotCrash() {
        coordinator.convertClipboard()
    }

    func testIsOnlyInstanceForCurrentUser_ReturnsTrueInTestProcess() {
        XCTAssertTrue(AppCoordinator.isOnlyInstanceForCurrentUser(otherProcessIdentifiers: { _ in [] }))
    }

    func testIsOnlyInstanceForCurrentUser_ReturnsFalseWhenAnotherInstanceRunning() {
        let currentIdentifier = ProcessInfo.processInfo.processIdentifier
        XCTAssertFalse(AppCoordinator.isOnlyInstanceForCurrentUser { _ in [currentIdentifier + 1] })
    }

    func testShowSettingsThenStop_DoesNotCrash() {
        coordinator.showSettings(section: .macros)
        XCTAssertEqual(coordinator.selectedSettingsSection, .macros)
        coordinator.stop()
    }

    func testShowSettingsFromPopover_DeniedPermissionRoutesToSystem() {
        coordinator.keyboardHealth = .requestingPermission
        let initialRevision = coordinator.systemHealthNavigationRevision
        coordinator.showSettingsFromPopover(section: .clipboard)
        XCTAssertEqual(coordinator.selectedSettingsSection, .system)
        XCTAssertEqual(coordinator.systemHealthNavigationRevision, initialRevision &+ 1)
    }

    func testShowSettingsFromPopover_ActivePermissionRoutesToPreferredSection() {
        coordinator.keyboardHealth = .active
        coordinator.showSettingsFromPopover(section: .clipboard)
        XCTAssertEqual(coordinator.selectedSettingsSection, .clipboard)
    }

    func testShowSettingsFromPopover_ActivePermission_NilPreferredKeepsCurrent() {
        coordinator.selectedSettingsSection = .about
        coordinator.keyboardHealth = .active
        coordinator.showSettingsFromPopover()
        XCTAssertEqual(coordinator.selectedSettingsSection, .about)
    }

    func testShowSettingsFromPopover_DeniedPermission_NilPreferredRoutesToSystem() {
        coordinator.keyboardHealth = .requestingPermission
        coordinator.showSettingsFromPopover()
        XCTAssertEqual(coordinator.selectedSettingsSection, .system)
    }

    func testShowSettingsFromPopover_RepeatedDeniedRoutesIncrementsRevision() {
        coordinator.keyboardHealth = .requestingPermission
        let first = coordinator.systemHealthNavigationRevision
        coordinator.showSettingsFromPopover()
        let second = coordinator.systemHealthNavigationRevision
        XCTAssertEqual(second, first &+ 1)
        coordinator.showSettingsFromPopover()
        XCTAssertEqual(coordinator.systemHealthNavigationRevision, second &+ 1)
    }

    func testStart_InvokesFullLifecycle() {
        coordinator.start()
        coordinator.stop()
    }

    func testStart_WithoutCloudCredentialKeepsKeyboardAndClipboardRunning() async {
        coordinator.settingsStore.update { $0.clipboard.isCaptureEnabled = true }
        coordinator.start()
        coordinator.translation.model.setSourceText("hello")
        coordinator.translation.model.translate()
        await Task.yield()

        XCTAssertEqual(coordinator.translation.model.status, .failed(.noProviderConfigured))
        XCTAssertNotEqual(coordinator.keyboardHealth, .stopped)
        XCTAssertTrue(coordinator.clipboard.monitor.isRunning)
        coordinator.stop()
    }

    func testStart_WithShowSettingsAtLaunch_OpensSettings() {
        coordinator.settingsStore.update { $0.system.showSettingsAtLaunch = true }
        coordinator.start()
        coordinator.stop()
    }

    func testClearSettingsWindowIfNeeded_DoesNotCrash() {
        let window = NSWindow()
        coordinator.clearSettingsWindowIfNeeded(window)
    }

    func testRestartKeyboardService_WhenNotPaused_RefreshesPermission() {
        coordinator.restartKeyboardService()
    }

    func testRestartKeyboardService_WhenPaused_ResumesPaused() {
        coordinator.keyboardService.setPaused(true)
        coordinator.keyboardPaused = true
        coordinator.restartKeyboardService()
    }

    func testPresentUpdateResult_UpdateAvailable_OpensWindow() {
        coordinator.presentUpdateResult(
            .updateAvailable(
                currentVersion: "1.0.0",
                latestVersion: "1.1.0",
                releaseNotes: "Notes",
                downloadURL: "https://github.com/jonaskahn/EasyKey/releases/tag/v1.1.0"
            )
        )
        coordinator.stop()
    }

    func testPresentUpdateResult_UpToDate_OpensWindow() {
        coordinator.presentUpdateResult(.upToDate(currentVersion: "1.0.0"))
        coordinator.stop()
    }

    func testPresentUpdateResult_Failure_OpensErrorWindow() {
        coordinator.presentUpdateResult(.failure(.networkError))
        coordinator.stop()
    }

    func testPerformStartupUpdateCheck_WhenDisabled_DoesNothing() {
        coordinator.settingsStore.update { $0.system.checkForUpdates = false }
        coordinator.performStartupUpdateCheck()
    }

    func testShowLogs_DoesNotCrash() {
        coordinator.showLogs()
    }

    func testShowSettings_WhenPopoverAlreadyShown_ClosesThenOpens() {
        coordinator.statusItemController.install(coordinator: coordinator)
        coordinator.statusItemController.togglePopover {}
        coordinator.showSettings()
        coordinator.stop()
    }

    func testConvertClipboard_WithTextOnPasteboard_ConvertsAndReappliesHTML() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString("Viet", forType: .string)
        let html = Data("<b>Viet</b>".utf8)
        pasteboard.setData(html, forType: .html)
        coordinator.convertClipboard()
        XCTAssertNotNil(pasteboard.string(forType: .string))
    }

    func testUpdateWindowDelegate_WindowWillClose_ClearsMatchingWindow() {
        coordinator.presentUpdateResult(.upToDate(currentVersion: "1.0.0"))
        if let window = coordinator.updateWindow {
            UpdateWindowDelegate.shared.windowWillClose(
                Notification(name: NSWindow.willCloseNotification, object: window)
            )
        }
        coordinator.stop()
    }

    func testUpdateWindowDelegate_WindowWillClose_IgnoresUnrelatedWindow() {
        let unrelated = NSWindow()
        UpdateWindowDelegate.shared.windowWillClose(
            Notification(name: NSWindow.willCloseNotification, object: unrelated)
        )
        coordinator.stop()
    }

    func testUpdateWindowDelegate_WindowWillClose_IgnoresNonWindowObject() {
        UpdateWindowDelegate.shared.windowWillClose(
            Notification(name: NSWindow.willCloseNotification, object: NSString(string: "not a window"))
        )
        coordinator.stop()
    }

    func testHandleUpdateDownload_TrustedURL_OpensInWorkspace() {
        let trusted = "https://github.com/jonaskahn/EasyKey/releases/tag/v1.1.0"
        coordinator.handleUpdateDownload(url: trusted)
    }

    func testHandleUpdateDownload_UntrustedURL_LogsError() {
        let untrusted = "https://evil.example.com/malware"
        coordinator.handleUpdateDownload(url: untrusted)
    }

    func testHandleUpdateDownload_InvalidURLString_LogsError() {
        let invalid = "not a url"
        coordinator.handleUpdateDownload(url: invalid)
    }

    func testCloseUpdateWindow_AfterPresenting_ClearsWindow() {
        coordinator.presentUpdateResult(.upToDate(currentVersion: "1.0.0"))
        coordinator.closeUpdateWindow()
        coordinator.stop()
    }
}
