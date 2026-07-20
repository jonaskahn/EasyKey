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
        return view
    }

    func updateNSView(_ view: KeyCaptureView, context _: Context) {
        view.capture = { shortcut in
            self.shortcut = shortcut
            isRecording = false
        }
        view.cancel = { isRecording = false }
        if isRecording {
            DispatchQueue.main.async { view.window?.makeFirstResponder(view) }
        }
    }
}

final class KeyCaptureView: NSView {
    var capture: ((Shortcut) -> Void)?
    var cancel: (() -> Void)?
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
            Shortcut(keyCode: 0, modifiers: command), // Cmd+A Select All
            Shortcut(keyCode: 8, modifiers: command), // Cmd+C Copy
            Shortcut(keyCode: 9, modifiers: command), // Cmd+V Paste
            Shortcut(keyCode: 7, modifiers: command), // Cmd+X Cut
            Shortcut(keyCode: 6, modifiers: command), // Cmd+Z Undo
            Shortcut(keyCode: 6, modifiers: commandShift), // Cmd+Shift+Z Redo
            Shortcut(keyCode: 1, modifiers: command), // Cmd+S Save
            Shortcut(keyCode: 31, modifiers: command), // Cmd+O Open
            Shortcut(keyCode: 35, modifiers: command), // Cmd+P Print
            Shortcut(keyCode: 45, modifiers: command), // Cmd+N New
            Shortcut(keyCode: 3, modifiers: command), // Cmd+F Find
            Shortcut(keyCode: 13, modifiers: command), // Cmd+W Close Window
            Shortcut(keyCode: 12, modifiers: command), // Cmd+Q Quit
            Shortcut(keyCode: 4, modifiers: command), // Cmd+H Hide
            Shortcut(keyCode: 46, modifiers: command), // Cmd+M Minimize
            Shortcut(keyCode: 43, modifiers: command), // Cmd+, Preferences
            Shortcut(keyCode: 48, modifiers: command), // Cmd+Tab App Switcher
            Shortcut(keyCode: 49, modifiers: command), // Cmd+Space Spotlight
            Shortcut(keyCode: 20, modifiers: commandShift), // Cmd+Shift+3 Screenshot
            Shortcut(keyCode: 21, modifiers: commandShift), // Cmd+Shift+4 Screenshot
            Shortcut(keyCode: 23, modifiers: commandShift), // Cmd+Shift+5 Screenshot
        ]
        return Set(reserved.map { $0 })
    }()

    override func keyDown(with event: NSEvent) {
        _ = record(event)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        record(event)
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
