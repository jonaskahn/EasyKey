import AppKit
import EasyEngineCore
import EasyKeyKit
import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable {
    case typing, encoding, macros, smartSwitch, behavior, system, about

    var id: String {
        rawValue
    }

    var symbol: String {
        switch self {
        case .typing: "keyboard"
        case .encoding: "character.book.closed"
        case .macros: "text.badge.plus"
        case .smartSwitch: "arrow.triangle.2.circlepath"
        case .behavior: "slider.horizontal.3"
        case .system: "desktopcomputer"
        case .about: "info.circle"
        }
    }
}
