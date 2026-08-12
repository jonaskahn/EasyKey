import AppKit
@testable import EasyKey
import XCTest

@MainActor
final class AppMainMenuInstallerTests: XCTestCase {
    func testInstallIfNeeded_AddsEditPasteKeyEquivalent() {
        let previous = NSApp.mainMenu
        defer { NSApp.mainMenu = previous }

        NSApp.mainMenu = NSMenu()
        AppMainMenuInstaller.installIfNeeded()
        AppMainMenuInstaller.installIfNeeded()

        let edit = NSApp.mainMenu?.items.first(where: { $0.submenu?.items.contains(where: { $0.keyEquivalent == "v" }) == true })
        XCTAssertNotNil(edit?.submenu)
        let paste = edit?.submenu?.items.first { $0.keyEquivalent == "v" }
        XCTAssertEqual(paste?.action, #selector(NSText.paste(_:)))
        XCTAssertEqual(
            edit?.submenu?.items.filter { $0.keyEquivalent == "v" }.count,
            1,
            "Second install must not duplicate Paste"
        )
    }

    func testInstallIfNeeded_UpdatesExistingMenuTitlesForSelectedLanguage() {
        let previous = NSApp.mainMenu
        defer { NSApp.mainMenu = previous }

        let suite = "one.ifelse.easykey.menu-tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let localization = LocalizationStore(defaults: defaults, bundle: .main)
        localization.setPreference(.english)
        NSApp.mainMenu = NSMenu()
        AppMainMenuInstaller.installIfNeeded(localization: localization)

        localization.setPreference(.vietnamese)
        AppMainMenuInstaller.installIfNeeded(localization: localization)

        let edit = NSApp.mainMenu?.items.first(where: { $0.title == "Sửa" })
        XCTAssertEqual(edit?.submenu?.items.first(where: { $0.keyEquivalent == "v" })?.title, "Dán")
    }
}
