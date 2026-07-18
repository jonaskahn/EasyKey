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

    override func keyDown(with event: NSEvent) {
        _ = record(event)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        record(event)
    }

    /// Records a shortcut from a key event. A valid shortcut requires at least one
    /// modifier, so bare key presses are rejected to prevent accidental assignment.
    /// Escape cancels recording. Returns whether the event was consumed.
    @discardableResult
    private func record(_ event: NSEvent) -> Bool {
        let modifiers = modifiers(from: event)
        if event.keyCode == Self.escapeKeyCode, modifiers.isEmpty {
            cancel?()
            return true
        }
        guard !modifiers.isEmpty else { return false }
        capture?(Shortcut(keyCode: UInt16(event.keyCode), modifiers: modifiers))
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
