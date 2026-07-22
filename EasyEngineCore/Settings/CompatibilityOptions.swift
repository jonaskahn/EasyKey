import Foundation

public struct CompatibilityOptions: Codable, Equatable, Sendable {
    public static let defaultCompatibilityModeApplicationBundleIdentifiers = [
        "com.google.Chrome",
        "org.chromium.Chromium",
    ]

    public var otherLanguageSupport: Bool
    public var compatibilityModeApplicationBundleIdentifiers: [String]
    public var ignoredApplicationBundleIdentifiers: [String]

    public init(
        otherLanguageSupport: Bool = false,
        compatibilityModeApplicationBundleIdentifiers: [String] = defaultCompatibilityModeApplicationBundleIdentifiers,
        ignoredApplicationBundleIdentifiers: [String] = []
    ) {
        self.otherLanguageSupport = otherLanguageSupport
        self.compatibilityModeApplicationBundleIdentifiers = compatibilityModeApplicationBundleIdentifiers
        self.ignoredApplicationBundleIdentifiers = ignoredApplicationBundleIdentifiers
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
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
        case otherLanguageSupport
        case compatibilityModeApplicationBundleIdentifiers
        case legacyChromiumBrowserBundleIdentifiers = "chromiumBrowserBundleIdentifiers"
        case ignoredApplicationBundleIdentifiers
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(otherLanguageSupport, forKey: .otherLanguageSupport)
        try container.encode(
            compatibilityModeApplicationBundleIdentifiers,
            forKey: .compatibilityModeApplicationBundleIdentifiers
        )
        try container.encode(ignoredApplicationBundleIdentifiers, forKey: .ignoredApplicationBundleIdentifiers)
    }
}
