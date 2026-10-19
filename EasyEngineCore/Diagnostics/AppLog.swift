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
    /// "EASYKEY_KEYBOARD_DEBUG" UserDefaults boolean. The System settings toggle
    /// takes effect immediately without restarting the app.
    public static var isKeyboardDebugEnabled: Bool {
        if let environment = ProcessInfo.processInfo.environment["EASYKEY_KEYBOARD_DEBUG"] {
            return !environment.isEmpty
                && environment != "0"
                && environment.lowercased() != "false"
        }
        return UserDefaults.standard.bool(forKey: "EASYKEY_KEYBOARD_DEBUG")
    }

    /// Logs a keyboard-diagnostic message at info level with public privacy.
    /// Callers must log metadata and lengths only, never typed or expansion content.
    public static func keyboardDebug(_ message: @autoclosure () -> String) {
        guard isKeyboardDebugEnabled else { return }
        let rendered = message()
        logger(.keyboard).info("\(rendered, privacy: .public)")
    }

    /// Formats UTF-16 code units for development tools. This is reversible
    /// encoding, not redaction; never use it to log user input.
    public static func hexDump(_ text: String) -> String {
        text.utf16.map { String(format: "U+%04X", $0) }.joined(separator: " ")
    }
}
