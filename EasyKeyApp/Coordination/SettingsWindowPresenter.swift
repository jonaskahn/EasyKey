import AppKit
import EasyEngineCore
import SwiftUI

@MainActor
final class SettingsWindowPresenter {
    private let localization: LocalizationStore
    private var settingsWindow: NSWindow?

    init(localization: LocalizationStore) {
        self.localization = localization
    }

    func present(settingsStore: SettingsStore, coordinator: AppCoordinator) {
        AppMainMenuInstaller.installIfNeeded()
        if let window = settingsWindow {
            window.title = localization.string(.settingsWindowTitle)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            removeSplitViewSeparator(from: window)
            return
        }

        let contentView = ContentView(settingsStore: settingsStore, coordinator: coordinator)
        let hostingController = NSHostingController(rootView: contentView)
        hostingController.sizingOptions = []
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 520),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = hostingController
        window.title = localization.string(.settingsWindowTitle)
        window.contentMinSize = NSSize(width: 700, height: 440)
        window.contentMaxSize = NSSize(width: 700, height: 520)
        if let visibleFrame = NSScreen.main?.visibleFrame,
           window.frame.height > visibleFrame.height {
            let titleBarHeight = window.frame.height - window.contentLayoutRect.height
            window.setContentSize(NSSize(width: 700, height: max(440, visibleFrame.height - titleBarHeight)))
        }
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.toolbarStyle = .unified
        window.center()
        SettingsWindowDelegate.shared.coordinator = coordinator
        window.delegate = SettingsWindowDelegate.shared
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = window
        removeSplitViewSeparator(from: window)
    }

    private func removeSplitViewSeparator(from window: NSWindow) {
        DispatchQueue.main.async {
            guard let toolbar = window.toolbar else { return }
            for index in toolbar.items.indices.reversed()
                where toolbar.items[index].itemIdentifier.rawValue.contains("splitViewSeparator") {
                toolbar.removeItem(at: index)
            }
        }
    }

    func refreshTitle() {
        settingsWindow?.title = localization.string(.settingsWindowTitle)
    }

    func clearIfNeeded(_ window: NSWindow) {
        guard settingsWindow === window else { return }
        settingsWindow = nil
    }

    func close() {
        settingsWindow?.close()
        settingsWindow = nil
    }
}

/// Clears the presenter's settings-window retain when the user closes it,
/// so the next open recreates a live window instead of ordering a closed one.
final class SettingsWindowDelegate: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowDelegate()

    weak var coordinator: AppCoordinator?

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        coordinator?.clearSettingsWindowIfNeeded(window)
    }
}
