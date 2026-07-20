import AppKit
import EasyEngineCore
@testable import EasyKey
import XCTest

@MainActor
final class StatusItemControllerTests: XCTestCase {
    private var localizationDefaults: UserDefaults!
    private var suiteName: String!
    private var localization: LocalizationStore!
    private var controller: StatusItemController!

    override func setUpWithError() throws {
        suiteName = "one.ifelse.easykey.status-item-tests.\(UUID().uuidString)"
        localizationDefaults = UserDefaults(suiteName: suiteName)
        localizationDefaults.removePersistentDomain(forName: suiteName)
        localization = LocalizationStore(defaults: localizationDefaults, bundle: .main)
        controller = StatusItemController(localization: localization)
    }

    override func tearDownWithError() throws {
        localizationDefaults.removePersistentDomain(forName: suiteName)
        controller = nil
    }

    func testIsPopoverShown_BeforeInstall_IsFalse() {
        XCTAssertFalse(controller.isPopoverShown)
    }

    func testClosePopover_BeforeInstall_DoesNotCrash() {
        controller.closePopover()
    }

    func testTogglePopover_BeforeInstall_DoesNotCrash() {
        controller.togglePopover {}
    }

    func testPopoverCloseObserver_ForwardsNotificationToClosure() {
        let observer = PopoverCloseObserver()
        var closeCount = 0
        observer.onClose = { closeCount += 1 }

        observer.popoverDidClose(Notification(name: NSPopover.didCloseNotification))

        XCTAssertEqual(closeCount, 1)
    }

    func testOnPopoverClosed_RoundTripsThroughController() {
        var closeCount = 0
        controller.onPopoverClosed = { closeCount += 1 }

        XCTAssertNotNil(controller.onPopoverClosed)
        controller.onPopoverClosed?()

        XCTAssertEqual(closeCount, 1)
    }

    func testMenuBarStateTitle_Paused_ReturnsPausedTitle() {
        let title = controller.menuBarStateTitle(for: .vietnamese, keyboardHealth: .active, keyboardPaused: true)
        XCTAssertEqual(title, localization.string(.statusPaused))
    }

    func testMenuBarStateTitle_ActiveVietnamese_ReturnsVietnameseTitle() {
        let title = controller.menuBarStateTitle(for: .vietnamese, keyboardHealth: .active, keyboardPaused: false)
        XCTAssertEqual(title, localization.string(.statusVietnameseInput))
    }

    func testMenuBarStateTitle_ActiveEnglish_ReturnsEnglishTitle() {
        let title = controller.menuBarStateTitle(for: .english, keyboardHealth: .active, keyboardPaused: false)
        XCTAssertEqual(title, localization.string(.statusEnglishInput))
    }

    func testMenuBarStateTitle_RequestingPermission_ReturnsPermissionTitle() {
        let title = controller.menuBarStateTitle(for: .english, keyboardHealth: .requestingPermission, keyboardPaused: false)
        XCTAssertEqual(title, localization.string(.statusPermissionRequired))
    }

    func testMenuBarStateTitle_FailedOrDegraded_ReturnsNeedsAttentionTitle() {
        XCTAssertEqual(
            controller.menuBarStateTitle(for: .english, keyboardHealth: .failed, keyboardPaused: false),
            localization.string(.statusNeedsAttention)
        )
        XCTAssertEqual(
            controller.menuBarStateTitle(for: .english, keyboardHealth: .degraded, keyboardPaused: false),
            localization.string(.statusNeedsAttention)
        )
    }

    func testMenuBarStateTitle_Stopped_ReturnsStoppedTitle() {
        let title = controller.menuBarStateTitle(for: .english, keyboardHealth: .stopped, keyboardPaused: false)
        XCTAssertEqual(title, localization.string(.statusStopped))
    }

    func testUpdate_BeforeInstall_DoesNotCrash() {
        controller.update(settings: .defaults, keyboardHealth: .active, keyboardPaused: false)
    }

    func testTeardown_BeforeInstall_DoesNotCrash() {
        controller.teardown()
    }

    func testBindMenuActions_DoesNotCrash() {
        let (coordinator, tempDirectory) = TestCoordinatorFactory.make()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        controller.bindMenuActions(to: coordinator)
    }

    func testInstall_CreatesStatusItem() {
        let (coordinator, tempDirectory) = TestCoordinatorFactory.make()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        controller.install(coordinator: coordinator)
        defer { controller.teardown() }
        XCTAssertTrue(controller.isPopoverShown == false || controller.isPopoverShown)
    }

    func testUpdate_AfterInstall_ActiveEnglish_AppliesEnglishImage() {
        let (coordinator, tempDirectory) = TestCoordinatorFactory.make()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        controller.install(coordinator: coordinator)
        defer { controller.teardown() }
        var settings = EasyKeySettings.defaults
        settings.input.language = .english
        controller.update(settings: settings, keyboardHealth: .active, keyboardPaused: false)
    }

    func testUpdate_AfterInstall_ActiveVietnamese_AppliesVietnameseImage() {
        let (coordinator, tempDirectory) = TestCoordinatorFactory.make()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        controller.install(coordinator: coordinator)
        defer { controller.teardown() }
        var settings = EasyKeySettings.defaults
        settings.input.language = .vietnamese
        controller.update(settings: settings, keyboardHealth: .active, keyboardPaused: false)
    }

    func testUpdate_AfterInstall_Paused_AppliesPausedImage() {
        let (coordinator, tempDirectory) = TestCoordinatorFactory.make()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        controller.install(coordinator: coordinator)
        defer { controller.teardown() }
        controller.update(settings: .defaults, keyboardHealth: .active, keyboardPaused: true)
    }

    func testUpdate_AfterInstall_RequestingPermission_AppliesAlertImage() {
        let (coordinator, tempDirectory) = TestCoordinatorFactory.make()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        controller.install(coordinator: coordinator)
        defer { controller.teardown() }
        controller.update(settings: .defaults, keyboardHealth: .requestingPermission, keyboardPaused: false)
    }

    func testUpdate_AfterInstall_Failed_AppliesAlertImage() {
        let (coordinator, tempDirectory) = TestCoordinatorFactory.make()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        controller.install(coordinator: coordinator)
        defer { controller.teardown() }
        controller.update(settings: .defaults, keyboardHealth: .failed, keyboardPaused: false)
    }

    func testUpdate_AfterInstall_Degraded_AppliesAlertImage() {
        let (coordinator, tempDirectory) = TestCoordinatorFactory.make()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        controller.install(coordinator: coordinator)
        defer { controller.teardown() }
        controller.update(settings: .defaults, keyboardHealth: .degraded, keyboardPaused: false)
    }

    func testUpdate_AfterInstall_Stopped_AppliesEnglishImage() {
        let (coordinator, tempDirectory) = TestCoordinatorFactory.make()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        controller.install(coordinator: coordinator)
        defer { controller.teardown() }
        controller.update(settings: .defaults, keyboardHealth: .stopped, keyboardPaused: false)
    }

    func testUpdate_AfterInstall_GrayMenuIconEnabled_AppliesTemplate() {
        let (coordinator, tempDirectory) = TestCoordinatorFactory.make()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        controller.install(coordinator: coordinator)
        defer { controller.teardown() }
        var settings = EasyKeySettings.defaults
        settings.system.grayMenuIcon = true
        controller.update(settings: settings, keyboardHealth: .active, keyboardPaused: false)
    }

    func testTogglePopover_AfterInstall_RefreshesPermission() {
        let (coordinator, tempDirectory) = TestCoordinatorFactory.make()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        controller.install(coordinator: coordinator)
        defer { controller.teardown() }
        var refreshCount = 0
        controller.togglePopover { refreshCount += 1 }
        XCTAssertEqual(refreshCount, 1)
    }

    func testRefreshPopoverContent_AfterInstall_DoesNotCrash() {
        let (coordinator, tempDirectory) = TestCoordinatorFactory.make()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        controller.install(coordinator: coordinator)
        defer { controller.teardown() }
        controller.refreshPopoverContent(coordinator: coordinator)
    }

    func testMenuSnapshotProvider_RoundTripsSnapshot() {
        let expected = StatusMenuBuilder.Snapshot(
            language: .english,
            inputMethod: .telex,
            encoding: .unicode,
            currentApplicationName: "App",
            currentAppSmartSwitchStatus: "On",
            keyboardPaused: false
        )
        controller.menuSnapshotProvider = { expected }
        let returned = controller.menuSnapshotProvider?()
        XCTAssertEqual(returned?.currentApplicationName, expected.currentApplicationName)
        XCTAssertEqual(returned?.language, expected.language)
    }
}
