import Foundation

public struct KeyEvent: Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        case character(Character)
        case backspace
        case forwardDelete
        case leftArrow
        case rightArrow
        case upArrow
        case downArrow
        case `return`
        case tab
        case escape
        case space
        case other
    }

    public var kind: Kind
    public var shift: Bool
    public var capsLock: Bool
    public var control: Bool
    public var option: Bool
    public var command: Bool

    public init(
        kind: Kind,
        shift: Bool = false,
        capsLock: Bool = false,
        control: Bool = false,
        option: Bool = false,
        command: Bool = false
    ) {
        self.kind = kind
        self.shift = shift
        self.capsLock = capsLock
        self.control = control
        self.option = option
        self.command = command
    }

    public var isUppercase: Bool {
        shift != capsLock
    }

    public var hasModifiers: Bool {
        control || option || command
    }

    public static func char(_ character: Character, shift: Bool = false, capsLock: Bool = false) -> KeyEvent {
        KeyEvent(kind: .character(character), shift: shift, capsLock: capsLock)
    }
}
