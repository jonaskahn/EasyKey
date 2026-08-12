import AppKit

/// Accessory / menu-bar apps ship without a standard Edit menu, so Cmd+X/C/V/A
/// never reach text fields via the responder chain. Install once at launch.
enum AppMainMenuInstaller {
    private static let editMenuIdentifier = NSUserInterfaceItemIdentifier("one.ifelse.easykey.menu.edit")
    private static let appQuitMenuItemIdentifier = NSUserInterfaceItemIdentifier("one.ifelse.easykey.menu.appQuit")
    private static let undoMenuItemIdentifier = NSUserInterfaceItemIdentifier("one.ifelse.easykey.menu.undo")
    private static let redoMenuItemIdentifier = NSUserInterfaceItemIdentifier("one.ifelse.easykey.menu.redo")
    private static let cutMenuItemIdentifier = NSUserInterfaceItemIdentifier("one.ifelse.easykey.menu.cut")
    private static let copyMenuItemIdentifier = NSUserInterfaceItemIdentifier("one.ifelse.easykey.menu.copy")
    private static let pasteMenuItemIdentifier = NSUserInterfaceItemIdentifier("one.ifelse.easykey.menu.paste")
    private static let selectAllMenuItemIdentifier = NSUserInterfaceItemIdentifier("one.ifelse.easykey.menu.selectAll")

    @MainActor
    static func installIfNeeded() {
        installIfNeeded(localization: .shared)
    }

    @MainActor
    static func installIfNeeded(localization: LocalizationStore) {
        let mainMenu = NSApp.mainMenu ?? NSMenu()
        if NSApp.mainMenu == nil {
            NSApp.mainMenu = mainMenu
        }

        if mainMenu.items.contains(where: { $0.identifier == editMenuIdentifier }) {
            updateLocalizedTitles(in: mainMenu, localization: localization)
            return
        }

        if mainMenu.items.isEmpty {
            let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "EasyKey"
            let appMenu = NSMenu(title: appName)
            let quitItem = appMenu.addItem(
                withTitle: localization.string(.menuQuit),
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"
            )
            quitItem.identifier = appQuitMenuItemIdentifier
            let appItem = NSMenuItem()
            appItem.submenu = appMenu
            mainMenu.addItem(appItem)
        }

        let editTitle = localization.string(.menuEdit)
        let editMenu = NSMenu(title: editTitle)
        let undoItem = editMenu.addItem(withTitle: localization.string(.menuUndo), action: Selector(("undo:")), keyEquivalent: "z")
        undoItem.identifier = undoMenuItemIdentifier
        let redoItem = editMenu.addItem(
            withTitle: localization.string(.menuRedo),
            action: Selector(("redo:")),
            keyEquivalent: "Z"
        )
        redoItem.identifier = redoMenuItemIdentifier
        editMenu.addItem(.separator())
        let cutItem = editMenu.addItem(withTitle: localization.string(.menuCut), action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        cutItem.identifier = cutMenuItemIdentifier
        let copyItem = editMenu.addItem(withTitle: localization.string(.menuCopy), action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        copyItem.identifier = copyMenuItemIdentifier
        let pasteItem = editMenu.addItem(
            withTitle: localization.string(.menuPaste),
            action: #selector(NSText.paste(_:)),
            keyEquivalent: "v"
        )
        pasteItem.identifier = pasteMenuItemIdentifier
        let selectAllItem = editMenu.addItem(
            withTitle: localization.string(.menuSelectAll),
            action: #selector(NSText.selectAll(_:)),
            keyEquivalent: "a"
        )
        selectAllItem.identifier = selectAllMenuItemIdentifier

        let editItem = NSMenuItem(title: editTitle, action: nil, keyEquivalent: "")
        editItem.identifier = editMenuIdentifier
        editItem.submenu = editMenu

        if mainMenu.items.count > 1 {
            mainMenu.insertItem(editItem, at: 1)
        } else {
            mainMenu.addItem(editItem)
        }
    }

    @MainActor
    private static func updateLocalizedTitles(in mainMenu: NSMenu, localization: LocalizationStore) {
        menuItem(with: appQuitMenuItemIdentifier, in: mainMenu)?.title = localization.string(.menuQuit)
        guard let editItem = mainMenu.items.first(where: { $0.identifier == editMenuIdentifier }),
              let editMenu = editItem.submenu
        else { return }

        let titles: [(NSUserInterfaceItemIdentifier, L10nKey)] = [
            (undoMenuItemIdentifier, .menuUndo),
            (redoMenuItemIdentifier, .menuRedo),
            (cutMenuItemIdentifier, .menuCut),
            (copyMenuItemIdentifier, .menuCopy),
            (pasteMenuItemIdentifier, .menuPaste),
            (selectAllMenuItemIdentifier, .menuSelectAll),
        ]
        let editTitle = localization.string(.menuEdit)
        editItem.title = editTitle
        editMenu.title = editTitle
        for (identifier, key) in titles {
            menuItem(with: identifier, in: editMenu)?.title = localization.string(key)
        }
    }

    @MainActor
    private static func menuItem(with identifier: NSUserInterfaceItemIdentifier, in menu: NSMenu) -> NSMenuItem? {
        for item in menu.items {
            if item.identifier == identifier {
                return item
            }
            if let found = item.submenu.flatMap({ menuItem(with: identifier, in: $0) }) {
                return found
            }
        }
        return nil
    }
}
