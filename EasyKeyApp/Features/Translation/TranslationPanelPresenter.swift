import AppKit
import SwiftUI

@MainActor
protocol TranslationCancelling: AnyObject {
    func cancelActiveTranslation()
}

@MainActor
protocol TranslationSpeechStopping: AnyObject {
    func stopSpeaking()
}

extension TranslationModel: TranslationCancelling {}

@MainActor
protocol TranslationPanelWindow: AnyObject {
    var isVisible: Bool { get }
    var windowNumber: Int { get }
    func replaceContent(_ content: AnyView)
    func setFrameOrigin(_ point: CGPoint)
    func setContentSize(_ size: CGSize)
    func makeKeyAndOrderFront()
    func orderOut()
    func setCloseHandler(_ handler: @escaping () -> Void)
    func containsWindowNumber(_ windowNumber: Int) -> Bool
    func addTitlebarAccessory(_ viewController: NSTitlebarAccessoryViewController)
}

final class TranslationPanel: NSPanel, TranslationPanelWindow {
    private var closeHandler: (() -> Void)?

    init(size: CGSize) {
        super.init(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isFloatingPanel = true
        level = .floating
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        becomesKeyOnlyIfNeeded = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
    }

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }

    override func close() {
        if let closeHandler {
            closeHandler()
        } else {
            super.close()
        }
    }

    func replaceContent(_ content: AnyView) {
        contentView = NSHostingView(rootView: content)
    }

    func makeKeyAndOrderFront() {
        makeKeyAndOrderFront(nil)
    }

    func orderOut() {
        orderOut(nil)
    }

    func setCloseHandler(_ handler: @escaping () -> Void) {
        closeHandler = handler
    }

    func containsWindowNumber(_ windowNumber: Int) -> Bool {
        guard let eventWindow = NSApp.window(withWindowNumber: windowNumber) else {
            return windowNumber == self.windowNumber
        }

        var candidate: NSWindow? = eventWindow
        while let window = candidate {
            if window === self {
                return true
            }
            candidate = window.parent
        }
        return false
    }

    func addTitlebarAccessory(_ viewController: NSTitlebarAccessoryViewController) {
        addTitlebarAccessoryViewController(viewController)
    }
}

enum TranslationPanelLocalEvent: Equatable {
    case escape
    case keyDown
    case mouseDownInsidePanel
    case mouseDownOutsidePanel
}

final class TranslationPanelMonitorRegistration {
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

@MainActor
protocol TranslationPanelEventMonitoring: AnyObject {
    func addLocalMonitor(
        isPanelOwnedWindow: @escaping (Int) -> Bool,
        handler: @escaping (TranslationPanelLocalEvent) -> Bool
    ) -> TranslationPanelMonitorRegistration?
    func addGlobalClickMonitor(handler: @escaping () -> Void) -> TranslationPanelMonitorRegistration?
}

@MainActor
final class SystemTranslationPanelEventMonitor: TranslationPanelEventMonitoring {
    func addLocalMonitor(
        isPanelOwnedWindow: @escaping (Int) -> Bool,
        handler: @escaping (TranslationPanelLocalEvent) -> Bool
    ) -> TranslationPanelMonitorRegistration? {
        guard let monitor = NSEvent.addLocalMonitorForEvents(
            matching: [.keyDown, .leftMouseDown, .rightMouseDown],
            handler: { event in
                let localEvent: TranslationPanelLocalEvent
                switch event.type {
                case .keyDown:
                    localEvent = event.keyCode == 53 ? .escape : .keyDown
                case .leftMouseDown, .rightMouseDown:
                    localEvent = isPanelOwnedWindow(event.windowNumber)
                        ? .mouseDownInsidePanel
                        : .mouseDownOutsidePanel
                default:
                    return event
                }
                return handler(localEvent) ? nil : event
            }
        )
        else {
            return nil
        }
        return TranslationPanelMonitorRegistration { NSEvent.removeMonitor(monitor) }
    }

    func addGlobalClickMonitor(handler: @escaping () -> Void) -> TranslationPanelMonitorRegistration? {
        guard let monitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown],
            handler: { _ in handler() }
        )
        else {
            return nil
        }
        return TranslationPanelMonitorRegistration { NSEvent.removeMonitor(monitor) }
    }
}

@MainActor
final class TranslationPanelPresenter {
    static let panelSize = CGSize(width: 520, height: 560)
    private static let keepOnTopDefaultsKey = "panel.translation.keepOnTop"

    var makeContent: () -> AnyView = { AnyView(EmptyView()) }
    var panelSizeProvider: () -> CGSize = { TranslationPanelPresenter.panelSize }
    /// Invoked after the panel closes for any reason (Escape, outside click,
    /// close button). Callers use this to apply session-persistence policy.
    var onClose: (() -> Void)?

    private let translation: TranslationCancelling
    private let speech: TranslationSpeechStopping?
    private let eventMonitor: TranslationPanelEventMonitoring
    private let panelFactory: () -> TranslationPanelWindow
    private let frontmostApplication: () -> NSRunningApplication?
    private let activateEasyKey: () -> Void
    private let pointerLocation: () -> CGPoint
    private let screenGeometries: () -> [TranslationPanelScreenGeometry]
    private let isFrontmostAppExemptFromOutsideClickDismissal: () -> Bool
    private let userDefaults: UserDefaults
    private var panel: TranslationPanelWindow?
    private var titlebarAccessory: KeepOnTopTitlebarAccessory?
    private var localMonitor: TranslationPanelMonitorRegistration?
    private var globalClickMonitor: TranslationPanelMonitorRegistration?
    private var keepOnTop: Bool

    private(set) var previousApplication: NSRunningApplication?

    var isShown: Bool {
        panel?.isVisible ?? false
    }

    init(
        translation: TranslationCancelling,
        speech: TranslationSpeechStopping? = nil,
        eventMonitor: TranslationPanelEventMonitoring? = nil,
        panelFactory: (() -> TranslationPanelWindow)? = nil,
        frontmostApplication: @escaping () -> NSRunningApplication? = { NSWorkspace.shared.frontmostApplication },
        activateEasyKey: (() -> Void)? = nil,
        pointerLocation: @escaping () -> CGPoint = { NSEvent.mouseLocation },
        screenGeometries: @escaping () -> [TranslationPanelScreenGeometry] = {
            NSScreen.screens.map { TranslationPanelScreenGeometry(frame: $0.frame, visibleFrame: $0.visibleFrame) }
        },
        isFrontmostAppExemptFromOutsideClickDismissal: @escaping () -> Bool = {
            TranslationPanelPresenter.frontmostAppIsSystemTranslationService()
        },
        userDefaults: UserDefaults = .standard
    ) {
        self.translation = translation
        self.speech = speech
        self.eventMonitor = eventMonitor ?? SystemTranslationPanelEventMonitor()
        self.panelFactory = panelFactory ?? { TranslationPanel(size: Self.panelSize) }
        self.frontmostApplication = frontmostApplication
        self.activateEasyKey = activateEasyKey ?? { NSApp.activate(ignoringOtherApps: true) }
        self.pointerLocation = pointerLocation
        self.screenGeometries = screenGeometries
        self.isFrontmostAppExemptFromOutsideClickDismissal = isFrontmostAppExemptFromOutsideClickDismissal
        self.userDefaults = userDefaults
        keepOnTop = userDefaults.bool(forKey: Self.keepOnTopDefaultsKey)
    }

    func show() {
        show(previousApplication: frontmostApplication())
    }

    func show(previousApplication: NSRunningApplication?) {
        self.previousApplication = previousApplication
        let panel = existingOrNewPanel()
        let size = panelSizeProvider()
        panel.replaceContent(makeContent())
        panel.setContentSize(size)
        panel.setFrameOrigin(translationPanelOrigin(
            pointerLocation: pointerLocation(),
            panelSize: size,
            screens: screenGeometries()
        ))
        activateEasyKey()
        panel.makeKeyAndOrderFront()
        installMonitors()
    }

    func toggle() {
        if isShown {
            close()
        } else {
            show()
        }
    }

    func toggle(previousApplication: NSRunningApplication?) {
        if isShown {
            close()
        } else {
            show(previousApplication: previousApplication)
        }
    }

    func close() {
        removeMonitors()
        panel?.orderOut()
        translation.cancelActiveTranslation()
        speech?.stopSpeaking()
        previousApplication = nil
        onClose?()
    }

    /// Toggles "keep on top": when on, the panel stays open on outside clicks
    /// (both monitors are suppressed); Escape still closes it.
    func setKeepOnTop(_ on: Bool) {
        keepOnTop = on
        userDefaults.set(on, forKey: Self.keepOnTopDefaultsKey)
        titlebarAccessory?.isOn = on
        if isShown {
            installMonitors()
        }
    }

    private func existingOrNewPanel() -> TranslationPanelWindow {
        if let panel {
            return panel
        }
        let panel = panelFactory()
        panel.setCloseHandler { [weak self] in
            self?.close()
        }
        let accessory = KeepOnTopTitlebarAccessory(isOn: keepOnTop) { on in
            on
                ? LocalizationStore.shared.string(.commonUnkeepOnTop)
                : LocalizationStore.shared.string(.commonKeepOnTop)
        }
        accessory.onToggle = { [weak self] on in self?.setKeepOnTop(on) }
        panel.addTitlebarAccessory(accessory)
        titlebarAccessory = accessory
        self.panel = panel
        return panel
    }

    private func installMonitors() {
        removeMonitors()
        localMonitor = eventMonitor.addLocalMonitor(
            isPanelOwnedWindow: { [weak self] in self?.panel?.containsWindowNumber($0) == true },
            handler: { [weak self] event in self?.handle(event) ?? false }
        )
        if !keepOnTop {
            globalClickMonitor = eventMonitor.addGlobalClickMonitor { [weak self] in
                self?.handleGlobalClick()
            }
        }
    }

    /// Apple's on-device Translation framework can hand off to a system
    /// helper process (language-download or consent UI) while resolving a
    /// `.translationTask` session for the Apple provider. That helper briefly
    /// becomes the frontmost app, which a plain outside-click check would
    /// read as "the user switched apps" and close the panel the instant they
    /// interact with it. Skip the close in that specific case; any other
    /// foreign app still dismisses normally.
    private func handleGlobalClick() {
        guard !isFrontmostAppExemptFromOutsideClickDismissal() else { return }
        close()
    }

    private nonisolated static func frontmostAppIsSystemTranslationService() -> Bool {
        guard let bundleIdentifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else { return false }
        return bundleIdentifier.hasPrefix("com.apple.") && bundleIdentifier.localizedCaseInsensitiveContains("translat")
    }

    private func handle(_ event: TranslationPanelLocalEvent) -> Bool {
        switch event {
        case .escape:
            close()
            return true
        case .mouseDownOutsidePanel:
            // Local monitors only ever see this app's own events, so an
            // "outside the panel" click here is a transient in-app popover or
            // NSMenu (the source/target language pickers), not a dismissal
            // gesture. Closing here would tear the panel down the instant the
            // user picks a language from a Menu popup. Real outside-click
            // dismissal (clicks into other apps) is the global monitor's job.
            return false
        case .keyDown, .mouseDownInsidePanel:
            return false
        }
    }

    private func removeMonitors() {
        localMonitor?.invalidate()
        localMonitor = nil
        globalClickMonitor?.invalidate()
        globalClickMonitor = nil
    }
}
