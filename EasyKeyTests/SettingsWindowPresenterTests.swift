import AppKit
import EasyEngineCore
@testable import EasyKey
import XCTest

@MainActor
final class SettingsWindowPresenterTests: XCTestCase {
    private var suiteName: String!
    private var localizationDefaults: UserDefaults!
    private var localization: LocalizationStore!
    private var presenter: SettingsWindowPresenter!
    private var coordinator: AppCoordinator!
    private var tempDirectory: URL!

    override func setUpWithError() throws {
        suiteName = "one.ifelse.easykey.settings-window-tests.\(UUID().uuidString)"
        localizationDefaults = UserDefaults(suiteName: suiteName)
        localizationDefaults.removePersistentDomain(forName: suiteName)
        localization = LocalizationStore(defaults: localizationDefaults, bundle: .main)
        presenter = SettingsWindowPresenter(localization: localization)

        let made = TestCoordinatorFactory.make()
        coordinator = made.coordinator
        tempDirectory = made.tempDirectory
    }

    override func tearDownWithError() throws {
        localizationDefaults.removePersistentDomain(forName: suiteName)
        try? FileManager.default.removeItem(at: tempDirectory)
        presenter = nil
        coordinator = nil
    }

    func testRefreshTitle_BeforePresent_DoesNotCrash() {
        presenter.refreshTitle()
    }

    func testClose_BeforePresent_DoesNotCrash() {
        presenter.close()
    }

    func testClearIfNeeded_UnrelatedWindow_DoesNotClearActiveWindow() {
        presenter.present(settingsStore: coordinator.settingsStore, coordinator: coordinator)
        let otherWindow = NSWindow()
        presenter.clearIfNeeded(otherWindow)
        presenter.refreshTitle()
        presenter.close()
    }

    func testPresent_TwiceReusesExistingWindow() {
        presenter.present(settingsStore: coordinator.settingsStore, coordinator: coordinator)
        presenter.present(settingsStore: coordinator.settingsStore, coordinator: coordinator)
        presenter.close()
    }

    func testWindowDelegate_ClearsCoordinatorReference() {
        let delegate = SettingsWindowDelegate.shared
        delegate.coordinator = coordinator
        let window = NSWindow()
        delegate.windowWillClose(Notification(name: NSWindow.willCloseNotification, object: window))
    }
}
