import Foundation

/// Centralized bundle and target identifiers used across the application.
public enum AppIdentifiers {
    public static let main = "one.ifelse.easykey"
    public static var loginHelper: String {
        main + ".LoginHelper"
    }
}
