import Foundation

public enum EncodingTable: String, Codable, CaseIterable, Sendable {
    case unicode
    case unicodeCombining
    case tcvn3
    case vniWindows
    case cp1258

    /// Whether typed output for this encoding is Unicode text that should be
    /// canonically composed (NFC) before it hits the wire. Legacy code-page
    /// outputs are exempt: CP1258 in particular is deliberately
    /// combining-based and normalizing it would corrupt the stream.
    public var isUnicodeTypingOutput: Bool {
        switch self {
        case .unicode, .unicodeCombining:
            return true
        case .tcvn3, .vniWindows, .cp1258:
            return false
        }
    }
}
