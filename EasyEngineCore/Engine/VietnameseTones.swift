import Foundation

public enum Tone: Int, Codable, CaseIterable, Equatable, Sendable {
    case none = 0
    case acute = 1
    case grave = 2
    case hook = 3
    case tilde = 4
    case dotBelow = 5
}

public enum DiacriticalMark: Int, Codable, CaseIterable, Equatable, Sendable {
    case none = 0
    case circumflex = 1
    case breve = 2
    case horn = 3
    case stroke = 4
}
