import Foundation
import OSLog

/// Shared logging facility for EasyKey. Never log raw keystroke content.
public enum AppLog {
    public static let subsystem = "one.ifelse.easykey"

    public enum Category: String, CaseIterable, Sendable {
        case app
        case engine
        case keyboard
        case synth
        case smartSwitch
        case settings
        case update
        case loginItem
        case translation
    }

    private static let loggers: [Category: Logger] = {
        var map: [Category: Logger] = [:]
        for category in Category.allCases {
            map[category] = Logger(subsystem: subsystem, category: category.rawValue)
        }
        return map
    }()

    public static func logger(_ category: Category) -> Logger {
        loggers[category] ?? Logger(subsystem: subsystem, category: category.rawValue)
    }

    public static func debug(_ category: Category, _ message: String) {
        logger(category).debug("\(message, privacy: .private)")
    }

    public static func info(_ category: Category, _ message: String) {
        logger(category).info("\(message, privacy: .private)")
    }

    public static func notice(_ category: Category, _ message: String) {
        logger(category).notice("\(message, privacy: .private)")
    }

    public static func error(_ category: Category, _ message: String) {
        logger(category).error("\(message, privacy: .public)")
    }
}

/// Centralized bundle and target identifiers used across the application.
public enum AppIdentifiers {
    public static let main = "one.ifelse.easykey"
    public static var loginHelper: String {
        main + ".LoginHelper"
    }
}
