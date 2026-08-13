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
}
