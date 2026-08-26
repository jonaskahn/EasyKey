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

/// Removes an installed `NSEvent` monitor when invalidated or deallocated.
final class PopoverMonitorRegistration {
    private var removeAction: (() -> Void)?

    init(removeAction: @escaping () -> Void) {
        self.removeAction = removeAction
    }

    deinit {
        invalidate()
    }

    func invalidate() {
        removeAction?()
        removeAction = nil
    }
}

/// Abstraction over outside-click event monitoring so tests can inject a stub.
@MainActor
protocol StatusPopoverClickMonitoring: AnyObject {
    func addLocalClickMonitor(handler: @escaping (NSEvent) -> Void) -> PopoverMonitorRegistration?
    func addGlobalClickMonitor(handler: @escaping () -> Void) -> PopoverMonitorRegistration?
}

@MainActor
final class SystemStatusPopoverClickMonitor: StatusPopoverClickMonitoring {
    func addLocalClickMonitor(handler: @escaping (NSEvent) -> Void) -> PopoverMonitorRegistration? {
        guard let monitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown],
            handler: { event in
                handler(event)
                return event
            }
        )
        else {
            return nil
        }
        return PopoverMonitorRegistration { NSEvent.removeMonitor(monitor) }
    }

    func addGlobalClickMonitor(handler: @escaping () -> Void) -> PopoverMonitorRegistration? {
        guard let monitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown],
            handler: { _ in handler() }
        )
        else {
            return nil
        }
        return PopoverMonitorRegistration { NSEvent.removeMonitor(monitor) }
    }
}

/// Decides whether a mouse-down event should dismiss the popover. Kept as a
/// pure decision so the tricky window classification is unit-testable.
@MainActor
enum PopoverOutsideClickDecision {
    static func shouldClose(
        clickWindow: NSWindow?,
        popoverWindow: NSWindow?,
        statusButtonWindow: NSWindow?,
        appOwnedWindows: [NSWindow]
    ) -> Bool {
        guard let clickWindow else { return false }
        if let popoverWindow, clickWindow === popoverWindow {
            return false
        }
        if let statusButtonWindow, clickWindow === statusButtonWindow {
            return false
        }
        // An open NSMenu (SwiftUI Menu) is a child window of the popover;
        // its item clicks must reach the menu, not dismiss the popover.
        if let popoverWindow, clickWindow.parent === popoverWindow {
            return false
        }
        return appOwnedWindows.contains { $0 === clickWindow }
    }
}

@MainActor
final class StatusItemController {
    static let popoverBehavior: NSPopover.Behavior = .transient

    private let localization: LocalizationStore
    private let clickMonitoring: StatusPopoverClickMonitoring
    private let menuActionTarget = StatusMenuActionTarget()
    private var statusItem: NSStatusItem?
    private var statusPopover: NSPopover?
    private let popoverCloseObserver = PopoverCloseObserver()
    private var appAppearanceObservation: NSKeyValueObservation?
    private var localClickRegistration: PopoverMonitorRegistration?
    private var globalClickRegistration: PopoverMonitorRegistration?
    private var externalPopoverCloseHandler: (() -> Void)?
    private var lastIconKey: StatusIconKey?
    private var lastIconImage: NSImage?

    /// Inputs that determine the rendered status-bar icon. Used to skip
    /// redundant redraws when nothing visible changed.
    private struct StatusIconKey: Equatable {
        var style: SystemOptions.MenuBarIconStyle
        var language: InputLanguage
        var health: KeyboardService.Health
        var paused: Bool
        var grayIcon: Bool
        var scale: SystemOptions.MenuBarIconScale
        var appearanceName: String
    }

    /// Test seam: substitutes the popover close action so dismissal can be
    /// observed without a live popover window.
    var popoverCloseAction: (() -> Void)?

    var onLeftClick: (() -> Void)?
    var onAppearanceChange: (() -> Void)?
    var onPopoverClosed: (() -> Void)? {
        get { externalPopoverCloseHandler }
        set { externalPopoverCloseHandler = newValue }
    }

    var translationConfigurationProvider: (() -> MenuPopoverTranslationConfiguration?)?

    init(
        localization: LocalizationStore,
        clickMonitoring: StatusPopoverClickMonitoring? = nil
    ) {
        self.localization = localization
        self.clickMonitoring = clickMonitoring ?? SystemStatusPopoverClickMonitor()
        popoverCloseObserver.onClose = { [weak self] in
            self?.popoverDidClose()
        }
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
        item.button?.imagePosition = .imageOnly
        item.button?.title = ""
        observeStatusItemAppearance()

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
            startOutsideClickMonitoring()
        }
    }

    /// AppKit's transient dismissal is not reliably restored after an NSMenu
    /// inside the popover is tracked, so outside clicks are also handled
    /// explicitly while the popover is shown. Monitors are armed on show and
    /// disarmed on close, which also gates the handlers below.
    private func startOutsideClickMonitoring() {
        guard localClickRegistration == nil else { return }
        localClickRegistration = clickMonitoring.addLocalClickMonitor { [weak self] event in
            self?.handleLocalOutsideClick(event)
        }
        globalClickRegistration = clickMonitoring.addGlobalClickMonitor { [weak self] in
            self?.dismissPopover()
        }
    }

    /// Invoked by the popover delegate on close; also a test seam for
    /// simulating a dismissal.
    func popoverDidClose() {
        stopOutsideClickMonitoring()
        externalPopoverCloseHandler?()
    }

    private func handleLocalOutsideClick(_ event: NSEvent) {
        guard let popover = statusPopover else { return }
        if PopoverOutsideClickDecision.shouldClose(
            clickWindow: event.window,
            popoverWindow: popover.contentViewController?.view.window,
            statusButtonWindow: statusItem?.button?.window,
            appOwnedWindows: NSApp.windows
        ) {
            dismissPopover()
        }
    }

    private func dismissPopover() {
        if let popoverCloseAction {
            popoverCloseAction()
        } else {
            statusPopover?.performClose(nil)
        }
    }

    private func stopOutsideClickMonitoring() {
        localClickRegistration?.invalidate()
        globalClickRegistration?.invalidate()
        localClickRegistration = nil
        globalClickRegistration = nil
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
        let iconKey = StatusIconKey(
            style: settings.system.menuBarIconStyle,
            language: language,
            health: keyboardHealth,
            paused: keyboardPaused,
            grayIcon: grayIcon,
            scale: settings.system.menuBarIconScale,
            appearanceName: appearance.name.rawValue
        )
        if iconKey == lastIconKey {
            if let cached = lastIconImage, button.image !== cached {
                button.image = cached
            }
            return
        }
        lastIconKey = iconKey

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
        button.contentTintColor = tintColor
        button.setAccessibilityLabel(
            localization.format(.a11yMenuBarState, menuBarStateTitle(
                for: language,
                keyboardHealth: keyboardHealth,
                keyboardPaused: keyboardPaused
            ))
        )
        lastIconImage = image
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
        stopOutsideClickMonitoring()
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

    private func observeStatusItemAppearance() {
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
