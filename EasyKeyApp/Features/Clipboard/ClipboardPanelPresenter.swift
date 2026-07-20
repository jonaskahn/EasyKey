import AppKit
import SwiftUI

/// A panel that can become key so its search field accepts keyboard focus while
/// the app runs as an accessory.
final class ClipboardPanel: NSPanel {
    override var canBecomeKey: Bool {
        true
    }
}

/// Owns the transient clipboard panel: one reusable window positioned beside the
/// pointer, dismissed on Escape or outside click. Captures the previously active
/// application before activation so paste can restore focus.
@MainActor
final class ClipboardPanelPresenter {
    static let panelSize = CGSize(width: 420, height: 500)

    private var panel: ClipboardPanel?
    private var globalClickMonitor: Any?
    private var localKeyMonitor: Any?
    private var keepOnTop = false
    private(set) var previousApplication: NSRunningApplication?

    /// Supplies the SwiftUI content. Set by the coordinator once the history model
    /// and action commands exist.
    var makeContent: () -> AnyView = { AnyView(EmptyView()) }

    var isShown: Bool {
        panel?.isVisible ?? false
    }

    func toggle(previousApplication: NSRunningApplication?) {
        if isShown {
            close()
        } else {
            show(previousApplication: previousApplication)
        }
    }

    func show(previousApplication: NSRunningApplication?) {
        self.previousApplication = previousApplication ?? NSWorkspace.shared.frontmostApplication

        let panel = existingOrNewPanel()
        panel.contentView = NSHostingView(rootView: makeContent())
        panel.setFrameOrigin(originForCurrentPointer())

        keepOnTop = false
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        installMonitors()
    }

    func close() {
        removeMonitors()
        panel?.orderOut(nil)
    }

    /// Toggles "keep on top": when on, the panel stays open on outside clicks
    /// (the global click monitor is suppressed); Escape still closes it.
    func setKeepOnTop(_ on: Bool) {
        keepOnTop = on
        if on {
            removeGlobalClickMonitor()
        } else {
            installGlobalClickMonitor()
        }
    }

    private func existingOrNewPanel() -> ClipboardPanel {
        if let panel {
            return panel
        }
        let panel = ClipboardPanel(
            contentRect: NSRect(origin: .zero, size: Self.panelSize),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        self.panel = panel
        return panel
    }

    private func originForCurrentPointer() -> CGPoint {
        let mouse = NSEvent.mouseLocation
        let screen = screenContaining(mouse) ?? NSScreen.main
        let visibleFrame = screen?.visibleFrame ?? CGRect(origin: .zero, size: Self.panelSize)
        return clipboardPanelOrigin(mouseLocation: mouse, panelSize: Self.panelSize, visibleFrame: visibleFrame)
    }

    private func screenContaining(_ point: CGPoint) -> NSScreen? {
        NSScreen.screens.first { NSMouseInRect(point, $0.frame, false) }
    }

    private func installMonitors() {
        removeMonitors()
        if !keepOnTop {
            installGlobalClickMonitor()
        }
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            if event.keyCode == 53 {
                MainActor.assumeIsolated { self?.close() }
                return nil
            }
            return event
        }
    }

    private func installGlobalClickMonitor() {
        guard globalClickMonitor == nil else { return }
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            MainActor.assumeIsolated { self?.close() }
        }
    }

    private func removeGlobalClickMonitor() {
        if let globalClickMonitor {
            NSEvent.removeMonitor(globalClickMonitor)
            self.globalClickMonitor = nil
        }
    }

    private func removeMonitors() {
        removeGlobalClickMonitor()
        if let localKeyMonitor {
            NSEvent.removeMonitor(localKeyMonitor)
            self.localKeyMonitor = nil
        }
    }
}
