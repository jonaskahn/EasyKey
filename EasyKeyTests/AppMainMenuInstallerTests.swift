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

        let edit = NSApp.mainMenu?.items.first(where: { $0.title == "Edit" || $0.submenu?.title == "Edit" })
        XCTAssertNotNil(edit?.submenu)
        let paste = edit?.submenu?.items.first { $0.keyEquivalent == "v" }
        XCTAssertEqual(paste?.action, #selector(NSText.paste(_:)))
        XCTAssertEqual(
            edit?.submenu?.items.filter { $0.keyEquivalent == "v" }.count,
            1,
            "Second install must not duplicate Paste"
        )
    }
}
