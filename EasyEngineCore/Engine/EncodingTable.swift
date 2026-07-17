import Foundation

public enum EncodingTable: String, Codable, CaseIterable, Sendable {
    case unicode
    case unicodeCombining
    case tcvn3
    case vniWindows
    case cp1258
}
