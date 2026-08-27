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

    static func logger(_ category: Category) -> Logger {
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

    /// Opt-in keyboard diagnostics. Off by default; enable with the
    /// EASYKEY_KEYBOARD_DEBUG environment variable (1/true) or the
    /// "EASYKEY_KEYBOARD_DEBUG" UserDefaults boolean. Cached on first access
    /// so the per-keystroke hot path pays one boolean check when disabled.
    public static let isKeyboardDebugEnabled: Bool = {
        if let environment = ProcessInfo.processInfo.environment["EASYKEY_KEYBOARD_DEBUG"] {
            return !environment.isEmpty
                && environment != "0"
                && environment.lowercased() != "false"
        }
        return UserDefaults.standard.bool(forKey: "EASYKEY_KEYBOARD_DEBUG")
    }()

    /// Logs a keyboard-diagnostic message at info level with public privacy.
    /// Callers must pre-format payloads with hexDump so raw keystroke content
    /// never reaches the log.
    public static func keyboardDebug(_ message: String) {
        guard isKeyboardDebugEnabled else { return }
        logger(.keyboard).info("\(message, privacy: .public)")
    }

    /// Hex dumps a string's UTF-16 code units ("t" -> "U+0074", "ề" ->
    /// "U+0065 U+0302 U+0300"). Used by the keyboard debug facility to make
    /// posted event payloads and field state inspectable without logging raw
    /// keystroke content.
    public static func hexDump(_ text: String) -> String {
        text.utf16.map { String(format: "U+%04X", $0) }.joined(separator: " ")
    }
}
