import EasyEngineCore
import Foundation

/// How one physical backspace deletes text in the receiving app. Apps that
/// edit text natively (Safari, Spotlight, Chrome's omnibox, NSTextView
/// fields) delete one extended grapheme cluster at a time; Chromium's Blink
/// web-page fields delete one UTF-16 code unit at a time, which matters when
/// the buffer renders combining diacritics ("ề" = e + U+0302 + U+0300 is one
/// grapheme but three code units). Counting backspaces in the wrong unit
/// under-deletes and leaves duplicate characters behind, or over-deletes and
/// eats the preceding space.
public enum BackspaceUnit: String, Equatable, Sendable {
    case grapheme
    case codePoint
}

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
    public let backspaceUnit: BackspaceUnit

    public init(
        bundleIdentifier: String,
        workarounds: Set<Workaround>,
        backspaceUnit: BackspaceUnit = .grapheme
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.workarounds = workarounds
        self.backspaceUnit = backspaceUnit
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
                workarounds: [.unicodeCombiningOutput, .emptyCharacterInsertion, .chromium],
                // Chromium compatibility-mode apps are Blink web-page fields,
                // whose backspace deletes one UTF-16 code unit. The omnibox
                // (a native field) overrides back to .grapheme in the
                // pipeline when the address-bar context is detected.
                backspaceUnit: .codePoint
            )
        }
        return nil
    }
}
