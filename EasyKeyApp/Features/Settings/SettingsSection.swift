import EasyEngineCore
import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable {
    case typing, encoding, smartSwitch, translation, clipboard, macros, behavior, system, about

    var id: String {
        rawValue
    }

    var symbol: String {
        switch self {
        case .typing: "keyboard"
        case .encoding: "character.book.closed"
        case .translation: "character.bubble"
        case .clipboard: "doc.on.clipboard"
        case .macros: "text.badge.plus"
        case .smartSwitch: "arrow.triangle.2.circlepath"
        case .behavior: "slider.horizontal.3"
        case .system: "desktopcomputer"
        case .about: "info.circle"
        }
    }
}
