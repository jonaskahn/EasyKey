import AppKit
import EasyEngineCore

@MainActor
enum StatusMenuBuilder {
    struct Snapshot {
        var language: InputLanguage
        var inputMethod: InputMethod
        var encoding: EncodingTable
        var currentApplicationName: String
        var currentAppSmartSwitchStatus: String
        var keyboardPaused: Bool
    }

    static func makeMenu(
        snapshot: Snapshot,
        localization: LocalizationStore,
        target: AnyObject,
        actions: Actions
    ) -> NSMenu {
        let menu = NSMenu()
        addLanguageItems(to: menu, snapshot: snapshot, localization: localization, target: target, actions: actions)
        addInputOptions(to: menu, snapshot: snapshot, localization: localization, target: target, actions: actions)
        addKeyboardControlItems(to: menu, snapshot: snapshot, localization: localization, target: target, actions: actions)
        addAppItems(to: menu, localization: localization, target: target, actions: actions)
        return menu
    }

    private static func addLanguageItems(
        to menu: NSMenu,
        snapshot: Snapshot,
        localization: LocalizationStore,
        target: AnyObject,
        actions: Actions
    ) {
        menu.addItem(menuItem(
            title: localization.displayName(for: InputLanguage.vietnamese),
            action: actions.selectVietnamese,
            keyEquivalent: "",
            systemImageName: "character.book.closed",
            state: snapshot.language == .vietnamese,
            target: target
        ))
        menu.addItem(menuItem(
            title: localization.displayName(for: InputLanguage.english),
            action: actions.selectEnglish,
            keyEquivalent: "",
            systemImageName: "globe",
            state: snapshot.language == .english,
            target: target
        ))
        menu.addItem(.separator())
    }

    private static func addKeyboardControlItems(
        to menu: NSMenu,
        snapshot: Snapshot,
        localization: LocalizationStore,
        target: AnyObject,
        actions: Actions
    ) {
        let smartSwitchItem = NSMenuItem(
            title: localization.format(
                .menuCurrentAppStatus,
                snapshot.currentApplicationName,
                snapshot.currentAppSmartSwitchStatus
            ),
            action: nil,
            keyEquivalent: ""
        )
        smartSwitchItem.isEnabled = false
        smartSwitchItem.image = systemImage(named: "app.badge")
        menu.addItem(smartSwitchItem)
        menu.addItem(menuItem(
            title: snapshot.keyboardPaused
                ? localization.string(.menuResumeKeyboard)
                : localization.string(.menuPauseKeyboard),
            action: actions.toggleKeyboardPause,
            keyEquivalent: "",
            systemImageName: snapshot.keyboardPaused ? "play.circle" : "pause.circle",
            target: target
        ))
        menu.addItem(menuItem(
            title: localization.string(.menuRestartKeyboard),
            action: actions.restartKeyboardService,
            keyEquivalent: "",
            systemImageName: "arrow.clockwise",
            target: target
        ))
        menu.addItem(.separator())
    }

    private static func addAppItems(
        to menu: NSMenu,
        localization: LocalizationStore,
        target: AnyObject,
        actions: Actions
    ) {
        menu.addItem(menuItem(
            title: localization.string(.menuConvertClipboard),
            action: actions.convertClipboard,
            keyEquivalent: "",
            systemImageName: "doc.on.clipboard",
            target: target
        ))
        menu.addItem(menuItem(
            title: localization.string(.menuSettings),
            action: actions.openSettings,
            keyEquivalent: ",",
            systemImageName: "gearshape",
            target: target
        ))
        menu.addItem(menuItem(
            title: localization.string(.menuMacros),
            action: actions.openMacros,
            keyEquivalent: "",
            systemImageName: "text.badge.plus",
            target: target
        ))
        menu.addItem(menuItem(
            title: localization.string(.menuShowLogs),
            action: actions.showLogs,
            keyEquivalent: "",
            systemImageName: "doc.text",
            target: target
        ))
        menu.addItem(.separator())
        let aboutItem = menuItem(
            title: localization.string(.menuAbout),
            action: actions.showAbout,
            keyEquivalent: "",
            systemImageName: "info.circle",
            target: target
        )
        menu.addItem(aboutItem)
        menu.addItem(menuItem(
            title: localization.string(.menuQuit),
            action: actions.quit,
            keyEquivalent: "q",
            systemImageName: "power",
            target: target
        ))
    }

    struct Actions {
        var selectVietnamese: Selector
        var selectEnglish: Selector
        var selectInputMethod: Selector
        var selectEncoding: Selector
        var toggleKeyboardPause: Selector
        var restartKeyboardService: Selector
        var convertClipboard: Selector
        var openSettings: Selector
        var openMacros: Selector
        var showAbout: Selector
        var showLogs: Selector
        var quit: Selector
    }

    private static func addInputOptions(
        to menu: NSMenu,
        snapshot: Snapshot,
        localization: LocalizationStore,
        target: AnyObject,
        actions: Actions
    ) {
        let inputMethodTitle = localization.string(.menuInputMethod)
        let inputMethods = NSMenu(title: inputMethodTitle)
        for inputMethod in InputMethod.allCases {
            let item = menuItem(
                title: localization.displayName(for: inputMethod),
                action: actions.selectInputMethod,
                keyEquivalent: "",
                systemImageName: "keyboard",
                state: snapshot.inputMethod == inputMethod,
                target: target
            )
            item.representedObject = inputMethod.rawValue
            inputMethods.addItem(item)
        }
        let inputMethodItem = NSMenuItem(title: inputMethodTitle, action: nil, keyEquivalent: "")
        inputMethodItem.image = systemImage(named: "keyboard")
        menu.addItem(inputMethodItem)
        menu.items.last?.submenu = inputMethods

        let encodingTitle = localization.string(.menuEncoding)
        let encodings = NSMenu(title: encodingTitle)
        for encoding in EncodingTable.allCases {
            let item = menuItem(
                title: localization.displayName(for: encoding),
                action: actions.selectEncoding,
                keyEquivalent: "",
                systemImageName: "textformat",
                state: snapshot.encoding == encoding,
                target: target
            )
            item.representedObject = encoding.rawValue
            encodings.addItem(item)
        }
        let encodingItem = NSMenuItem(title: encodingTitle, action: nil, keyEquivalent: "")
        encodingItem.image = systemImage(named: "textformat")
        menu.addItem(encodingItem)
        menu.items.last?.submenu = encodings
    }

    private static func menuItem(
        title: String,
        action: Selector?,
        keyEquivalent: String,
        systemImageName: String,
        state: Bool = false,
        target: AnyObject
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = target
        item.image = systemImage(named: systemImageName)
        item.state = state ? .on : .off
        if !keyEquivalent.isEmpty {
            item.keyEquivalentModifierMask = [.command]
        }
        return item
    }

    private static func systemImage(named name: String) -> NSImage? {
        NSImage(systemSymbolName: name, accessibilityDescription: nil)
    }
}
