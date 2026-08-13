import Foundation

/// Named macOS virtual key codes used across the keyboard pipeline.
enum KeyboardKeyCode {
    static let returnOrEnter: UInt16 = 36
    static let tab: UInt16 = 48
    static let space: UInt16 = 49
    static let escape: UInt16 = 53
    static let p: UInt16 = 35

    static let leftShift: UInt16 = 56
    static let rightShift: UInt16 = 60

    static let backspace: UInt16 = 51
    static let forwardDelete: UInt16 = 117

    static let leftArrow: UInt16 = 123
    static let rightArrow: UInt16 = 124
    static let downArrow: UInt16 = 125
    static let upArrow: UInt16 = 126

    static let functionKeyCodes: Set<UInt16> = [
        122, 120, 99, 118, 96, 97, 98, 100, 101, 109,
        103, 111, 105, 107, 113, 106, 64, 79, 80, 90,
    ]

    static func isFunctionKey(_ keyCode: UInt16) -> Bool {
        functionKeyCodes.contains(keyCode)
    }
}
