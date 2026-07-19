import Foundation

/// User-configurable translation policy. Never carries secrets or
/// translation content: API keys stay in Keychain, and source/translated
/// text are never persisted.
public struct TranslationOptions: Codable, Equatable, Sendable {
    public static let defaultOpenAIModelIdentifier = "gpt-4o-mini"
    public static let defaultAnthropicModelIdentifier = "claude-haiku-4-5"
    public static let defaultGeminiModelIdentifier = "gemini-2.0-flash"

    public enum DeepLEndpoint: String, Codable, Equatable, Sendable, CaseIterable {
        case free
        case pro
    }

    /// `nil` represents the Automatic provider preference. A non-nil value
    /// is always a concrete provider, never `TranslationProviderID.automatic`.
    public var preferredProviderID: TranslationProviderID?
    public var shortcut: Shortcut
    /// `nil` represents automatic source-language detection.
    public var defaultSourceLanguage: TranslationLanguage?
    public var openAIModelIdentifier: String
    public var anthropicModelIdentifier: String
    public var geminiModelIdentifier: String
    public var deepLEndpoint: DeepLEndpoint
    /// Providers whose cloud-transmission disclosure the user has
    /// acknowledged. Tracks acknowledgement only, never request content.
    public var acknowledgedCloudDisclosureProviders: Set<TranslationProviderID>

    public init(
        preferredProviderID: TranslationProviderID? = nil,
        shortcut: Shortcut = Shortcut(keyCode: 0, modifiers: [.option]),
        defaultSourceLanguage: TranslationLanguage? = nil,
        openAIModelIdentifier: String = TranslationOptions.defaultOpenAIModelIdentifier,
        anthropicModelIdentifier: String = TranslationOptions.defaultAnthropicModelIdentifier,
        geminiModelIdentifier: String = TranslationOptions.defaultGeminiModelIdentifier,
        deepLEndpoint: DeepLEndpoint = .free,
        acknowledgedCloudDisclosureProviders: Set<TranslationProviderID> = []
    ) {
        self.preferredProviderID = preferredProviderID
        self.shortcut = shortcut
        self.defaultSourceLanguage = defaultSourceLanguage
        self.openAIModelIdentifier = openAIModelIdentifier
        self.anthropicModelIdentifier = anthropicModelIdentifier
        self.geminiModelIdentifier = geminiModelIdentifier
        self.deepLEndpoint = deepLEndpoint
        self.acknowledgedCloudDisclosureProviders = acknowledgedCloudDisclosureProviders
    }
}
