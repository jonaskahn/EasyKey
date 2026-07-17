import Foundation

public struct CompatibilityOptions: Codable, Equatable, Sendable {
    public static let defaultCompatibilityModeApplicationBundleIdentifiers = [
        "com.google.Chrome",
        "org.chromium.Chromium",
    ]

    public var stepByStepSend: Bool
    public var keyboardLayoutCompatibility: Bool
    public var otherLanguageSupport: Bool
    public var compatibilityModeApplicationBundleIdentifiers: [String]
    public var ignoredApplicationBundleIdentifiers: [String]

    public init(
        stepByStepSend: Bool = false,
        keyboardLayoutCompatibility: Bool = false,
        otherLanguageSupport: Bool = false,
        compatibilityModeApplicationBundleIdentifiers: [String] = defaultCompatibilityModeApplicationBundleIdentifiers,
        ignoredApplicationBundleIdentifiers: [String] = []
    ) {
        self.stepByStepSend = stepByStepSend
        self.keyboardLayoutCompatibility = keyboardLayoutCompatibility
        self.otherLanguageSupport = otherLanguageSupport
        self.compatibilityModeApplicationBundleIdentifiers = compatibilityModeApplicationBundleIdentifiers
        self.ignoredApplicationBundleIdentifiers = ignoredApplicationBundleIdentifiers
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        stepByStepSend = try container.decodeIfPresent(Bool.self, forKey: .stepByStepSend) ?? false
        keyboardLayoutCompatibility = try container.decodeIfPresent(Bool.self, forKey: .keyboardLayoutCompatibility) ?? false
        otherLanguageSupport = try container.decodeIfPresent(Bool.self, forKey: .otherLanguageSupport) ?? false
        compatibilityModeApplicationBundleIdentifiers = try container.decodeIfPresent(
            [String].self,
            forKey: .compatibilityModeApplicationBundleIdentifiers
        ) ?? container.decodeIfPresent(
            [String].self,
            forKey: .legacyChromiumBrowserBundleIdentifiers
        ) ?? Self.defaultCompatibilityModeApplicationBundleIdentifiers
        ignoredApplicationBundleIdentifiers = try container.decodeIfPresent(
            [String].self,
            forKey: .ignoredApplicationBundleIdentifiers
        ) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case stepByStepSend
        case keyboardLayoutCompatibility
        case otherLanguageSupport
        case compatibilityModeApplicationBundleIdentifiers
        case legacyChromiumBrowserBundleIdentifiers = "chromiumBrowserBundleIdentifiers"
        case ignoredApplicationBundleIdentifiers
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(stepByStepSend, forKey: .stepByStepSend)
        try container.encode(keyboardLayoutCompatibility, forKey: .keyboardLayoutCompatibility)
        try container.encode(otherLanguageSupport, forKey: .otherLanguageSupport)
        try container.encode(
            compatibilityModeApplicationBundleIdentifiers,
            forKey: .compatibilityModeApplicationBundleIdentifiers
        )
        try container.encode(ignoredApplicationBundleIdentifiers, forKey: .ignoredApplicationBundleIdentifiers)
    }
}
