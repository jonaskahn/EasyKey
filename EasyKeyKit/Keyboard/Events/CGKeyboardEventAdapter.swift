import CoreGraphics
import EasyEngineCore
import Foundation

/// Translates CGEvent tap events into engine-facing values: key codes,
/// modifiers, event masks, and normalized key events.
enum CGKeyboardEventAdapter {
    static let specialKeyKinds: [UInt16: KeyEvent.Kind] = [
        KeyboardKeyCode.backspace: .backspace,
        KeyboardKeyCode.forwardDelete: .forwardDelete,
        KeyboardKeyCode.leftArrow: .leftArrow,
        KeyboardKeyCode.rightArrow: .rightArrow,
        KeyboardKeyCode.downArrow: .downArrow,
        KeyboardKeyCode.upArrow: .upArrow,
        KeyboardKeyCode.returnOrEnter: .return,
        KeyboardKeyCode.tab: .tab,
        KeyboardKeyCode.escape: .escape,
        KeyboardKeyCode.space: .space,
    ]

    static func keyCode(from event: CGEvent) -> UInt16? {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        guard keyCode >= 0, keyCode <= Int64(UInt16.max) else { return nil }
        return UInt16(keyCode)
    }

    static func normalize(event: CGEvent, keyCode: UInt16) -> KeyEvent {
        let modifiers = modifiers(from: event)
        return KeyEvent(
            kind: keyKind(for: keyCode, event: event),
            shift: modifiers.contains(.shift),
            capsLock: event.flags.contains(.maskAlphaShift),
            control: modifiers.contains(.control),
            option: modifiers.contains(.option),
            command: modifiers.contains(.command)
        )
    }

    static func modifiers(from event: CGEvent) -> Shortcut.ModifierFlags {
        var modifiers: Shortcut.ModifierFlags = []
        if event.flags.contains(.maskShift) {
            modifiers.insert(.shift)
        }
        if event.flags.contains(.maskControl) {
            modifiers.insert(.control)
        }
        if event.flags.contains(.maskAlternate) {
            modifiers.insert(.option)
        }
        if event.flags.contains(.maskCommand) {
            modifiers.insert(.command)
        }
        return modifiers
    }

    static func isMouseEvent(_ type: CGEventType) -> Bool {
        switch type {
        case .leftMouseDown, .rightMouseDown, .otherMouseDown,
             .leftMouseDragged, .rightMouseDragged, .otherMouseDragged:
            true
        default:
            false
        }
    }

    static func makeEventMask() -> CGEventMask {
        let types: [CGEventType] = [
            .keyDown, .keyUp, .flagsChanged,
            .leftMouseDown, .rightMouseDown, .otherMouseDown,
            .leftMouseDragged, .rightMouseDragged, .otherMouseDragged,
        ]
        return types.reduce(0) { $0 | (CGEventMask(1) << $1.rawValue) }
    }

    static func character(from event: CGEvent) -> Character? {
        var length = 0
        var buffer = [UniChar](repeating: 0, count: 8)
        event.keyboardGetUnicodeString(
            maxStringLength: buffer.count,
            actualStringLength: &length,
            unicodeString: &buffer
        )
        guard length > 0 else { return nil }
        return String(utf16CodeUnits: buffer, count: length).first
    }

    static func keyKind(for keyCode: UInt16, event: CGEvent) -> KeyEvent.Kind {
        specialKeyKinds[keyCode] ?? character(from: event).map(KeyEvent.Kind.character) ?? .other
    }
}
