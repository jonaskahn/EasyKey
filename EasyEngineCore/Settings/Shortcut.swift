import Foundation

public struct Shortcut: Codable, Equatable, Sendable {
    public var keyCode: UInt16
    public var modifiers: ModifierFlags

    public struct ModifierFlags: OptionSet, Codable, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let shift = ModifierFlags(rawValue: 1 << 0)
        public static let control = ModifierFlags(rawValue: 1 << 1)
        public static let option = ModifierFlags(rawValue: 1 << 2)
        public static let command = ModifierFlags(rawValue: 1 << 3)
    }

    public init(keyCode: UInt16, modifiers: ModifierFlags = []) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    public static let none = Shortcut(keyCode: 0, modifiers: [])

    public var isActive: Bool {
        keyCode != 0 || !modifiers.isEmpty
    }

    public var displayLabel: String {
        guard isActive else { return "" }
        var parts: [String] = []
        if modifiers.contains(.control) {
            parts.append("^")
        }
        if modifiers.contains(.option) {
            parts.append("\u{2325}")
        }
        if modifiers.contains(.shift) {
            parts.append("\u{21E7}")
        }
        if modifiers.contains(.command) {
            parts.append("\u{2318}")
        }
        parts.append(Self.keyNames[keyCode] ?? "Key \(keyCode)")
        return parts.joined(separator: " + ")
    }

    private static let keyNames: [UInt16: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
        8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y",
        17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6", 23: "5", 24: "=",
        25: "9", 26: "7", 27: "-", 28: "8", 29: "0", 30: "]", 31: "O", 32: "U",
        33: "[", 34: "I", 35: "P", 36: "Return", 37: "L", 38: "J", 39: "'", 40: "K",
        41: ";", 42: "\\", 43: ",", 44: "/", 45: "N", 46: "M", 47: ".", 48: "Tab",
        49: "Space", 50: "`", 51: "Delete", 53: "Escape", 54: "Right Command",
        55: "Left Command", 56: "Left Shift", 57: "Caps Lock", 58: "Left Option",
        59: "Left Control", 60: "Right Shift", 61: "Right Option", 62: "Right Control",
        63: "Fn", 64: "F17", 65: "Keypad .", 67: "Keypad *", 69: "Keypad +",
        71: "Keypad Clear", 75: "Keypad /", 76: "Keypad Enter", 78: "Keypad -",
        79: "F18", 80: "F19", 81: "Keypad =", 82: "Keypad 0", 83: "Keypad 1",
        84: "Keypad 2", 85: "Keypad 3", 86: "Keypad 4", 87: "Keypad 5",
        88: "Keypad 6", 89: "Keypad 7", 91: "Keypad 8", 92: "Keypad 9",
        96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8", 101: "F9", 103: "F11",
        105: "F13", 106: "F16", 107: "F14", 109: "F10", 111: "F12", 113: "F15",
        114: "Help", 115: "Home", 116: "Page Up", 117: "Forward Delete", 118: "F4",
        119: "End", 120: "F2", 121: "Page Down", 122: "F1", 123: "\u{2190}",
        124: "\u{2192}", 125: "\u{2193}", 126: "\u{2191}",
    ]
}
