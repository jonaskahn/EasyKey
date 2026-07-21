import AppKit

/// Accessory / menu-bar apps ship without a standard Edit menu, so Cmd+X/C/V/A
/// never reach text fields via the responder chain. Install once at launch.
enum AppMainMenuInstaller {
    private static let editMenuTitle = "Edit"

    @MainActor
    static func installIfNeeded() {
        let mainMenu = NSApp.mainMenu ?? NSMenu()
        if NSApp.mainMenu == nil {
            NSApp.mainMenu = mainMenu
        }

        if mainMenu.items.contains(where: { $0.submenu?.title == editMenuTitle || $0.title == editMenuTitle }) {
            return
        }

        if mainMenu.items.isEmpty {
            let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "EasyKey"
            let appMenu = NSMenu(title: appName)
            appMenu.addItem(
                withTitle: "Quit \(appName)",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"
            )
            let appItem = NSMenuItem()
            appItem.submenu = appMenu
            mainMenu.addItem(appItem)
        }

        let editMenu = NSMenu(title: editMenuTitle)
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        let editItem = NSMenuItem(title: editMenuTitle, action: nil, keyEquivalent: "")
        editItem.submenu = editMenu

        if mainMenu.items.count > 1 {
            mainMenu.insertItem(editItem, at: 1)
        } else {
            mainMenu.addItem(editItem)
        }
    }
}
