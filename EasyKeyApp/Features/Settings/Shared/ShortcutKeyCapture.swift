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
        return view
    }

    func updateNSView(_ view: KeyCaptureView, context _: Context) {
        view.capture = { shortcut in
            self.shortcut = shortcut
            isRecording = false
        }
        if isRecording {
            DispatchQueue.main.async { view.window?.makeFirstResponder(view) }
        }
    }
}

final class KeyCaptureView: NSView {
    var capture: ((Shortcut) -> Void)?
    override var acceptsFirstResponder: Bool {
        true
    }

    override func keyDown(with event: NSEvent) {
        capture?(Shortcut(keyCode: UInt16(event.keyCode), modifiers: modifiers(from: event)))
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        keyDown(with: event)
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
