import AppKit
import EasyEngineCore
import EasyKeyKit
import SwiftUI

/// Forwards `NSPopover` close notifications to a plain closure. `NSPopover`
/// requires an `NSObject`-conforming delegate, so this small adapter keeps
/// `StatusItemController` itself from needing to subclass `NSObject`.
@MainActor
final class PopoverCloseObserver: NSObject, NSPopoverDelegate {
    var onClose: (() -> Void)?

    func popoverDidClose(_: Notification) {
        onClose?()
    }
}

@MainActor
final class StatusItemController {
    static let popoverBehavior: NSPopover.Behavior = .transient

    private let localization: LocalizationStore
    private let menuActionTarget = StatusMenuActionTarget()
    private var statusItem: NSStatusItem?
    private var statusPopover: NSPopover?
    private let popoverCloseObserver = PopoverCloseObserver()
    private var appAppearanceObservation: NSKeyValueObservation?
    private var statusItemAppearanceObservation: NSKeyValueObservation?

    var onLeftClick: (() -> Void)?
    var onAppearanceChange: (() -> Void)?
    var onPopoverClosed: (() -> Void)? {
        get { popoverCloseObserver.onClose }
        set { popoverCloseObserver.onClose = newValue }
    }

    var translationConfigurationProvider: (() -> MenuPopoverTranslationConfiguration?)?

    init(localization: LocalizationStore) {
        self.localization = localization
    }

    func bindMenuActions(to coordinator: AppCoordinator) {
        menuActionTarget.coordinator = coordinator
    }

    func install(coordinator: AppCoordinator) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.target = self
        item.button?.action = #selector(statusItemClicked(_:))
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        statusItem = item
        observeStatusItemAppearance(button: item.button)

        let popover = NSPopover()
        // Clipboard and translation panels explicitly close this popover before
        // opening, so normal outside-click dismissal remains enabled.
        popover.behavior = Self.popoverBehavior
        popover.delegate = popoverCloseObserver
        let hostingController = NSHostingController(rootView: popoverView(coordinator: coordinator))
        hostingController.sizingOptions = [.preferredContentSize]
        popover.contentViewController = hostingController
        statusPopover = popover
    }

    var isPopoverShown: Bool {
        statusPopover?.isShown == true
    }

    func closePopover() {
        statusPopover?.performClose(nil)
    }

    func togglePopover(refreshPermission: () -> Void) {
        guard let popover = statusPopover, let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            refreshPermission()
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    func showContextMenu(
        snapshot: StatusMenuBuilder.Snapshot,
        for event: NSEvent
    ) {
        guard let button = statusItem?.button else { return }
        let menu = StatusMenuBuilder.makeMenu(
            snapshot: snapshot,
            localization: localization,
            target: menuActionTarget,
            actions: .init(
                selectVietnamese: #selector(StatusMenuActionTarget.selectVietnamese(_:)),
                selectEnglish: #selector(StatusMenuActionTarget.selectEnglish(_:)),
                selectInputMethod: #selector(StatusMenuActionTarget.selectInputMethod(_:)),
                selectEncoding: #selector(StatusMenuActionTarget.selectEncoding(_:)),
                toggleKeyboardPause: #selector(StatusMenuActionTarget.toggleKeyboardPause(_:)),
                restartKeyboardService: #selector(StatusMenuActionTarget.restartKeyboardService(_:)),
                convertClipboard: #selector(StatusMenuActionTarget.convertClipboardAction(_:)),
                clipboardHistory: #selector(StatusMenuActionTarget.clipboardHistoryAction(_:)),
                openSettings: #selector(StatusMenuActionTarget.openSettings(_:)),
                openMacros: #selector(StatusMenuActionTarget.openMacros(_:)),
                showAbout: #selector(StatusMenuActionTarget.showAbout(_:)),
                showLogs: #selector(StatusMenuActionTarget.showLogs(_:)),
                quit: #selector(StatusMenuActionTarget.quit(_:))
            )
        )
        menu.popUp(positioning: nil, at: event.locationInWindow, in: button)
    }

    func refreshPopoverContent(coordinator: AppCoordinator) {
        guard let popover = statusPopover else { return }
        popover.contentViewController = NSHostingController(
            rootView: popoverView(coordinator: coordinator)
        )
    }

    func refreshPopoverContent(
        coordinator: AppCoordinator,
        translation: MenuPopoverTranslationConfiguration?
    ) {
        guard let popover = statusPopover else { return }
        popover.contentViewController = NSHostingController(
            rootView: MenuPopoverView(
                coordinator: coordinator,
                translation: translation
            ).localized()
        )
    }

    func update(
        settings: EasyKeySettings,
        keyboardHealth: KeyboardService.Health,
        keyboardPaused: Bool
    ) {
        guard let button = statusItem?.button else { return }
        let language = settings.input.language
        let grayIcon = settings.system.grayMenuIcon
        let scale = settings.system.menuBarIconScale.factor

        let appearance = button.effectiveAppearance
        let image: NSImage?
        let tintColor: NSColor?
        if keyboardPaused {
            image = Self.tintedSystemImage(named: "pause.circle", color: .systemOrange, appearance: appearance, scale: scale)
            tintColor = nil
        } else if keyboardHealth == .requestingPermission || keyboardHealth == .failed || keyboardHealth == .degraded {
            image = Self.tintedSystemImage(
                named: "exclamationmark.triangle",
                color: .systemRed,
                appearance: appearance,
                scale: scale
            )
            tintColor = nil
        } else {
            image = Self.menuBarImage(
                named: Self.menuBarAssetName(
                    style: settings.system.menuBarIconStyle,
                    language: language
                ),
                asTemplate: grayIcon,
                appearance: appearance,
                scale: scale
            )
            tintColor = nil
        }

        button.image = image
        button.imagePosition = .imageOnly
        button.title = ""
        button.contentTintColor = tintColor
        button.setAccessibilityLabel(
            localization.format(.a11yMenuBarState, menuBarStateTitle(
                for: language,
                keyboardHealth: keyboardHealth,
                keyboardPaused: keyboardPaused
            ))
        )
    }

    func menuBarStateTitle(
        for language: InputLanguage,
        keyboardHealth: KeyboardService.Health,
        keyboardPaused: Bool
    ) -> String {
        if keyboardPaused {
            return localization.string(.statusPaused)
        }
        switch keyboardHealth {
        case .active:
            return language == .vietnamese
                ? localization.string(.statusVietnameseInput)
                : localization.string(.statusEnglishInput)
        case .requestingPermission:
            return localization.string(.statusPermissionRequired)
        case .failed, .degraded:
            return localization.string(.statusNeedsAttention)
        case .stopped:
            return localization.string(.statusStopped)
        }
    }

    func teardown() {
        appAppearanceObservation?.invalidate()
        appAppearanceObservation = nil
        statusItemAppearanceObservation?.invalidate()
        statusItemAppearanceObservation = nil
        statusPopover?.performClose(nil)
        statusItem = nil
        statusPopover = nil
    }

    private func popoverView(coordinator: AppCoordinator) -> some View {
        MenuPopoverView(
            coordinator: coordinator,
            translation: translationConfigurationProvider?()
        ).localized()
    }

    private func observeStatusItemAppearance(button: NSStatusBarButton?) {
        if appAppearanceObservation == nil {
            appAppearanceObservation = NSApp.observe(
                \.effectiveAppearance,
                options: [.new]
            ) { [weak self] _, _ in
                Task { @MainActor [weak self] in
                    self?.onAppearanceChange?()
                }
            }
        }

        statusItemAppearanceObservation?.invalidate()
        statusItemAppearanceObservation = button?.observe(
            \.effectiveAppearance,
            options: [.new]
        ) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                self?.onAppearanceChange?()
            }
        }
    }

    var menuSnapshotProvider: (() -> StatusMenuBuilder.Snapshot)?

    @objc private func statusItemClicked(_: Any?) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            guard let snapshot = menuSnapshotProvider?() else { return }
            showContextMenu(snapshot: snapshot, for: event)
        } else {
            onLeftClick?()
        }
    }

    private static func tintedSystemImage(
        named systemName: String,
        color: NSColor,
        appearance: NSAppearance,
        scale: CGFloat
    ) -> NSImage? {
        guard let symbol = NSImage(systemSymbolName: systemName, accessibilityDescription: "EasyKey") else {
            return nil
        }
        let configured =
            symbol.withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 14 * scale, weight: .regular))
                ?? symbol
        let size = NSSize(width: 18 * scale, height: 18 * scale)

        let rendered = NSImage(size: size, flipped: false) { bounds in
            appearance.performAsCurrentDrawingAppearance {
                let drawSize = configured.size
                let drawRect = NSRect(
                    x: (bounds.width - drawSize.width) / 2,
                    y: (bounds.height - drawSize.height) / 2,
                    width: drawSize.width,
                    height: drawSize.height
                )
                configured.draw(in: drawRect)
                color.set()
                bounds.fill(using: .sourceAtop)
            }
            return true
        }
        rendered.isTemplate = false
        return rendered
    }

    static func menuBarAssetName(
        style: SystemOptions.MenuBarIconStyle,
        language: InputLanguage
    ) -> String {
        "MenuBarStyle\(style.rawValue)\(language == .vietnamese ? "V" : "E")"
    }

    private static func menuBarImage(
        named name: String,
        asTemplate: Bool,
        appearance: NSAppearance,
        scale: CGFloat
    ) -> NSImage? {
        guard let base = NSImage(named: name) else { return nil }
        let size = NSSize(width: 18 * scale, height: 18 * scale)

        if asTemplate {
            let image = base.copy() as? NSImage ?? base
            image.size = size
            image.isTemplate = true
            return image
        }

        let rendered = NSImage(size: size, flipped: false) { rect in
            appearance.performAsCurrentDrawingAppearance {
                base.draw(in: rect)
            }
            return true
        }
        rendered.isTemplate = false
        return rendered
    }
}
