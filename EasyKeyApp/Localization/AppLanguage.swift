import Foundation

/// Interface language preference. Separate from typing `InputLanguage`.
enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system
    case english = "en"
    case vietnamese = "vi"

    var id: String {
        rawValue
    }

    /// Persisted UserDefaults key shared with legacy `@AppStorage("interfaceLanguage")`.
    static let storageKey = "interfaceLanguage"
    static let onboardingCompletedKey = "hasCompletedOnboarding"

    /// Language codes we ship translations for.
    static let supportedCodes: Set<String> = ["en", "vi"]

    var pickerKey: L10nKey {
        switch self {
        case .system: .languageSystem
        case .english: .languageEnglish
        case .vietnamese: .languageVietnamese
        }
    }

    /// Resolves to a concrete language code used for lookups (`en` or `vi`).
    var resolvedCode: String {
        switch self {
        case .english:
            "en"
        case .vietnamese:
            "vi"
        case .system:
            Self.systemPreferredCode
        }
    }

    static var systemPreferredCode: String {
        for preferred in Locale.preferredLanguages {
            let lowered = preferred.lowercased()
            if lowered.hasPrefix("vi") {
                return "vi"
            }
            if lowered.hasPrefix("en") {
                return "en"
            }
        }
        return "en"
    }

    static func load(from defaults: UserDefaults = .standard) -> AppLanguage {
        guard let raw = defaults.string(forKey: storageKey) else {
            return .vietnamese
        }
        return AppLanguage(rawValue: raw) ?? .vietnamese
    }

    func save(to defaults: UserDefaults = .standard) {
        defaults.set(rawValue, forKey: Self.storageKey)
    }
}
