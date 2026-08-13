import EasyEngineCore
import Foundation

public struct AppCompatibilityRule: Equatable, Sendable {
    public enum Workaround: String, CaseIterable, Hashable, Sendable {
        case unicodeCombiningOutput
        case spotlightSelection
        case emptyCharacterInsertion
        case alternateEmptyCharacter
        case chromium
    }

    public let bundleIdentifier: String
    public let workarounds: Set<Workaround>

    public init(bundleIdentifier: String, workarounds: Set<Workaround>) {
        self.bundleIdentifier = bundleIdentifier
        self.workarounds = workarounds
    }
}

public enum AppCompatibility {
    public static let rules: [AppCompatibilityRule] = [
        .init(bundleIdentifier: "com.apple.Safari", workarounds: [.unicodeCombiningOutput]),
        .init(bundleIdentifier: "com.apple.Spotlight", workarounds: [.spotlightSelection]),
        .init(bundleIdentifier: "com.microsoft.VSCode", workarounds: [.alternateEmptyCharacter]),
    ]

    public static func rule(
        for bundleIdentifier: String?,
        compatibilityModeApplicationBundleIdentifiers: [String] = CompatibilityOptions.defaultCompatibilityModeApplicationBundleIdentifiers
    ) -> AppCompatibilityRule? {
        guard let bundleIdentifier else { return nil }
        if let fixedRule = rules.first(where: { $0.bundleIdentifier == bundleIdentifier }) {
            return fixedRule
        }
        if compatibilityModeApplicationBundleIdentifiers.contains(bundleIdentifier) {
            return AppCompatibilityRule(
                bundleIdentifier: bundleIdentifier,
                workarounds: [.emptyCharacterInsertion, .chromium]
            )
        }
        return nil
    }
}
