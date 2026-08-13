import AppKit
import SwiftUI

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
