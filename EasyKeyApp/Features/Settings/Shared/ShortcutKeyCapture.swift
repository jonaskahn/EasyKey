import AppKit
import EasyEngineCore
import EasyKeyKit
import SwiftUI

struct ShortcutKeyCapture: NSViewRepresentable {
    @Binding var isRecording: Bool
    @Binding var shortcut: Shortcut

    func makeNSView(context _: Context) -> KeyCaptureView {
        let view = KeyCaptureView()
        view.capture = { shortcut in
            self.shortcut = shortcut
            isRecording = false
        }
        view.cancel = { isRecording = false }
        view.isRecording = isRecording
        return view
    }

    func updateNSView(_ view: KeyCaptureView, context _: Context) {
        view.capture = { shortcut in
            self.shortcut = shortcut
            isRecording = false
        }
        view.cancel = { isRecording = false }
        view.isRecording = isRecording
        if isRecording {
            DispatchQueue.main.async { view.becomeFirstResponderIfPossible() }
        } else {
            DispatchQueue.main.async { view.resignIfFirstResponder() }
        }
    }
}

final class KeyCaptureView: NSView {
    var capture: ((Shortcut) -> Void)?
    var cancel: (() -> Void)?
    /// Whether the user pressed Record. Key events must be ignored otherwise —
    /// AppKit sends `performKeyEquivalent` to every view in the key window's
    /// hierarchy, so without this gate any Cmd+combo would silently reassign
    /// shortcuts on the current settings tab.
    var isRecording = false
    override var acceptsFirstResponder: Bool {
        true
    }

    private static let escapeKeyCode: UInt16 = 53

    /// macOS system shortcuts that must never be reassigned (copy/paste/undo/etc.,
    /// app switching, Spotlight, screenshots). Matched by exact keyCode + modifier
    /// set so unrelated combos sharing a letter (e.g. Option+V) stay unaffected.
    private static let reservedSystemShortcuts: Set<Shortcut> = {
        let command: Shortcut.ModifierFlags = [.command]
        let commandShift: Shortcut.ModifierFlags = [.command, .shift]
        let reserved: [Shortcut] = [
            Shortcut(keyCode: 0, modifiers: command),
            Shortcut(keyCode: 8, modifiers: command),
            Shortcut(keyCode: 9, modifiers: command),
            Shortcut(keyCode: 7, modifiers: command),
            Shortcut(keyCode: 6, modifiers: command),
            Shortcut(keyCode: 6, modifiers: commandShift),
            Shortcut(keyCode: 1, modifiers: command),
            Shortcut(keyCode: 31, modifiers: command),
            Shortcut(keyCode: 35, modifiers: command),
            Shortcut(keyCode: 45, modifiers: command),
            Shortcut(keyCode: 3, modifiers: command),
            Shortcut(keyCode: 13, modifiers: command),
            Shortcut(keyCode: 12, modifiers: command),
            Shortcut(keyCode: 4, modifiers: command),
            Shortcut(keyCode: 46, modifiers: command),
            Shortcut(keyCode: 43, modifiers: command),
            Shortcut(keyCode: 48, modifiers: command),
            Shortcut(keyCode: 49, modifiers: command),
            Shortcut(keyCode: 20, modifiers: commandShift),
            Shortcut(keyCode: 21, modifiers: commandShift),
            Shortcut(keyCode: 23, modifiers: commandShift),
        ]
        return Set(reserved)
    }()

    override func keyDown(with event: NSEvent) {
        guard isRecording else { return }
        _ = record(event)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard isRecording else { return false }
        return record(event)
    }

    /// Window key status changed (focus switched to another app/surface). Treat as
    /// implicit cancel so SwiftUI state stays in sync with what the user can see.
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        observeWindowActivity()
    }

    private var lifecycleObservers: [NSObjectProtocol] = []

    private func observeWindowActivity() {
        lifecycleObservers.forEach(NotificationCenter.default.removeObserver)
        lifecycleObservers.removeAll()
        guard let window else { return }
        let center = NotificationCenter.default
        lifecycleObservers = [
            center.addObserver(
                forName: NSWindow.didResignKeyNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                self?.handleDeactivation()
            },
            center.addObserver(
                forName: NSWindow.willCloseNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                self?.handleDeactivation()
            },
        ]
    }

    private func handleDeactivation() {
        cancel?()
    }

    deinit {
        lifecycleObservers.forEach(NotificationCenter.default.removeObserver)
    }

    func becomeFirstResponderIfPossible() {
        guard let window, window.firstResponder !== self else { return }
        window.makeFirstResponder(self)
    }

    func resignIfFirstResponder() {
        guard let window, window.firstResponder === self else { return }
        window.makeFirstResponder(nil)
    }

    /// Records a shortcut from a key event. A valid shortcut requires at least one
    /// modifier, so bare key presses are rejected to prevent accidental assignment.
    /// Reserved macOS system shortcuts (Cmd+V, Cmd+C, Spotlight, etc.) are refused
    /// with a beep instead of being captured. Escape cancels recording. Returns
    /// whether the event was consumed.
    @discardableResult
    private func record(_ event: NSEvent) -> Bool {
        let modifiers = modifiers(from: event)
        if event.keyCode == Self.escapeKeyCode, modifiers.isEmpty {
            cancel?()
            return true
        }
        guard !modifiers.isEmpty else { return false }
        let candidate = Shortcut(keyCode: UInt16(event.keyCode), modifiers: modifiers)
        guard !Self.reservedSystemShortcuts.contains(candidate) else {
            NSSound.beep()
            return true
        }
        capture?(candidate)
        return true
    }

    private func modifiers(from event: NSEvent) -> Shortcut.ModifierFlags {
        var result: Shortcut.ModifierFlags = []
        if event.modifierFlags.contains(.shift) {
            result.insert(.shift)
        }
        if event.modifierFlags.contains(.control) {
            result.insert(.control)
        }
        if event.modifierFlags.contains(.option) {
            result.insert(.option)
        }
        if event.modifierFlags.contains(.command) {
            result.insert(.command)
        }
        return result
    }
}
