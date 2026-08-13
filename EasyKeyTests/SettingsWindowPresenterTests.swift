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

    func testWindowDelegates_ArePerPresenterInstances() {
        let otherPresenter = SettingsWindowPresenter(localization: localization)
        presenter.present(settingsStore: coordinator.settingsStore, coordinator: coordinator)
        otherPresenter.present(settingsStore: coordinator.settingsStore, coordinator: coordinator)

        let delegates = NSApp.windows
            .compactMap { $0.delegate as? SettingsWindowDelegate }
        XCTAssertGreaterThanOrEqual(delegates.count, 2)
        XCTAssertFalse(
            delegates[0] === delegates[1],
            "Each presenter must own its delegate; a shared instance allows another presenter to overwrite it"
        )
        presenter.close()
        otherPresenter.close()
    }

    func testWindowClose_ClearsRetain_SoNextPresentCreatesNewWindow() {
        presenter.present(settingsStore: coordinator.settingsStore, coordinator: coordinator)
        guard let window = NSApp.windows.first(where: { $0.delegate is SettingsWindowDelegate }) else {
            XCTFail("No settings window found")
            return
        }

        window.close()

        presenter.present(settingsStore: coordinator.settingsStore, coordinator: coordinator)
        guard let visibleWindow = NSApp.windows
            .first(where: { $0.delegate is SettingsWindowDelegate && $0.isVisible })
        else {
            XCTFail("No visible settings window after re-present")
            return
        }
        XCTAssertFalse(
            visibleWindow === window,
            "Presenter should recreate the window after the delegate cleared the closed one"
        )
        presenter.close()
    }
}
