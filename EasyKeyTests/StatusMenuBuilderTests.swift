import AppKit
import EasyEngineCore
@testable import EasyKey
import XCTest

@MainActor
final class StatusMenuBuilderTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var localization: LocalizationStore!
    private var target: StatusMenuActionTarget!
    private var coordinator: AppCoordinator!
    private var tempDirectory: URL!

    override func setUpWithError() throws {
        suiteName = "one.ifelse.easykey.status-menu-tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        localization = LocalizationStore(defaults: defaults, bundle: .main)
        target = StatusMenuActionTarget()

        let made = TestCoordinatorFactory.make()
        coordinator = made.coordinator
        tempDirectory = made.tempDirectory
        target.coordinator = coordinator
    }

    override func tearDownWithError() throws {
        defaults.removePersistentDomain(forName: suiteName)
        try? FileManager.default.removeItem(at: tempDirectory)
        coordinator = nil
        target = nil
    }

    private var actions: StatusMenuBuilder.Actions {
        .init(
            selectVietnamese: #selector(StatusMenuActionTarget.selectVietnamese(_:)),
            selectEnglish: #selector(StatusMenuActionTarget.selectEnglish(_:)),
            selectInputMethod: #selector(StatusMenuActionTarget.selectInputMethod(_:)),
            selectEncoding: #selector(StatusMenuActionTarget.selectEncoding(_:)),
            toggleKeyboardPause: #selector(StatusMenuActionTarget.toggleKeyboardPause(_:)),
            restartKeyboardService: #selector(StatusMenuActionTarget.restartKeyboardService(_:)),
            convertClipboard: #selector(StatusMenuActionTarget.convertClipboardAction(_:)),
            openSettings: #selector(StatusMenuActionTarget.openSettings(_:)),
            openMacros: #selector(StatusMenuActionTarget.openMacros(_:)),
            showAbout: #selector(StatusMenuActionTarget.showAbout(_:)),
            showLogs: #selector(StatusMenuActionTarget.showLogs(_:)),
            quit: #selector(StatusMenuActionTarget.quit(_:))
        )
    }

    func testMakeMenu_VietnamesePaused_BuildsExpectedStructure() {
        let snapshot = StatusMenuBuilder.Snapshot(
            language: .vietnamese,
            inputMethod: .telex,
            encoding: .unicode,
            currentApplicationName: "Safari",
            currentAppSmartSwitchStatus: "On",
            keyboardPaused: true
        )
        let menu = StatusMenuBuilder.makeMenu(snapshot: snapshot, localization: localization, target: target, actions: actions)
        XCTAssertFalse(menu.items.isEmpty)
        XCTAssertTrue(menu.items.contains { $0.submenu?.title == localization.string(.menuInputMethod) })
        XCTAssertTrue(menu.items.contains { $0.submenu?.title == localization.string(.menuEncoding) })
        XCTAssertTrue(menu.items.contains { $0.title == localization.string(.menuShowLogs) })
        assertAllItemsHaveIcons(in: menu)
    }

    func testMakeMenu_EnglishNotPaused_BuildsExpectedStructure() {
        let snapshot = StatusMenuBuilder.Snapshot(
            language: .english,
            inputMethod: .vni,
            encoding: .tcvn3,
            currentApplicationName: "Xcode",
            currentAppSmartSwitchStatus: "Off",
            keyboardPaused: false
        )
        let menu = StatusMenuBuilder.makeMenu(snapshot: snapshot, localization: localization, target: target, actions: actions)
        XCTAssertFalse(menu.items.isEmpty)
        assertAllItemsHaveIcons(in: menu)
    }

    func testStatusMenuActionTarget_SelectLanguage_UpdatesCoordinator() {
        target.selectVietnamese(nil)
        XCTAssertEqual(coordinator.settingsStore.settings.input.language, .vietnamese)
        target.selectEnglish(nil)
        XCTAssertEqual(coordinator.settingsStore.settings.input.language, .english)
    }

    func testStatusMenuActionTarget_SelectInputMethod_UpdatesCoordinator() {
        let item = NSMenuItem()
        item.representedObject = InputMethod.vni.rawValue
        target.selectInputMethod(item)
        XCTAssertEqual(coordinator.settingsStore.settings.input.inputMethod, .vni)
    }

    func testStatusMenuActionTarget_SelectInputMethod_InvalidRawValue_DoesNotCrash() {
        let item = NSMenuItem()
        item.representedObject = "not-a-method"
        target.selectInputMethod(item)
    }

    func testStatusMenuActionTarget_SelectEncoding_UpdatesCoordinator() {
        let item = NSMenuItem()
        item.representedObject = EncodingTable.tcvn3.rawValue
        target.selectEncoding(item)
        XCTAssertEqual(coordinator.settingsStore.settings.input.encoding, .tcvn3)
    }

    func testStatusMenuActionTarget_SelectEncoding_InvalidRawValue_DoesNotCrash() {
        let item = NSMenuItem()
        item.representedObject = "not-an-encoding"
        target.selectEncoding(item)
    }

    func testStatusMenuActionTarget_ToggleAndRestartKeyboard_DoesNotCrash() {
        target.toggleKeyboardPause(nil)
        target.restartKeyboardService(nil)
    }

    func testStatusMenuActionTarget_ConvertClipboardAction_DoesNotCrash() {
        target.convertClipboardAction(nil)
    }

    func testStatusMenuActionTarget_OpenSettingsAndMacros_DoesNotCrash() {
        target.openSettings(nil)
        target.openMacros(nil)
    }

    func testStatusMenuActionTarget_ShowAbout_PresentsAboutPanel() {
        let windowsBefore = Set(NSApp.windows.map(ObjectIdentifier.init))

        target.showAbout(nil)

        let aboutPanel = NSApp.windows.first { !windowsBefore.contains(ObjectIdentifier($0)) }
        XCTAssertNotNil(aboutPanel)
        aboutPanel?.close()
    }

    func testStatusMenuActionTarget_NilCoordinator_AllActionsNoOp() {
        let orphanTarget = StatusMenuActionTarget()
        orphanTarget.selectVietnamese(nil)
        orphanTarget.selectEnglish(nil)
        orphanTarget.toggleKeyboardPause(nil)
        orphanTarget.restartKeyboardService(nil)
        orphanTarget.convertClipboardAction(nil)
        orphanTarget.openSettings(nil)
        orphanTarget.openMacros(nil)
        orphanTarget.showLogs(nil)
    }

    private func assertAllItemsHaveIcons(in menu: NSMenu, file: StaticString = #filePath, line: UInt = #line) {
        for item in menu.items where !item.isSeparatorItem {
            XCTAssertNotNil(item.image, "Missing icon for menu item: \(item.title)", file: file, line: line)
            if let submenu = item.submenu {
                assertAllItemsHaveIcons(in: submenu, file: file, line: line)
            }
        }
    }
}
