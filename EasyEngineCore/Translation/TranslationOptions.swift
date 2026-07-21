import CoreGraphics
import Foundation

/// User-configurable translation policy. Never carries secrets or
/// translation content: API keys stay in Keychain, and source/translated
/// text are never persisted.
public struct TranslationOptions: Codable, Equatable, Sendable {
    public static let defaultOpenAIModelIdentifier = "gpt-4o-mini"
    public static let defaultAnthropicModelIdentifier = "claude-haiku-4-5"
    public static let defaultGeminiModelIdentifier = "gemini-2.0-flash"
    public static let defaultOpenRouterModelIdentifier = "openai/gpt-4o-mini"
    public static let defaultGroqModelIdentifier = "llama-3.1-8b-instant"
    public static let defaultOpenAICompatibleModelIdentifier = "gpt-4o-mini"
    public static let defaultAnthropicCompatibleModelIdentifier = "claude-haiku-4-5"

    public enum DeepLEndpoint: String, Codable, Equatable, Sendable, CaseIterable {
        case free
        case pro
    }

    /// Size of the floating translate panel opened by the translate shortcut.
    public enum PanelSize: String, Codable, Equatable, Sendable, CaseIterable {
        case compact
        case small
        case medium
        case large
        case extraLarge

        public var cgSize: CGSize {
            switch self {
            case .compact: CGSize(width: 440, height: 500)
            case .small: CGSize(width: 480, height: 530)
            case .medium: CGSize(width: 520, height: 560)
            case .large: CGSize(width: 620, height: 660)
            case .extraLarge: CGSize(width: 720, height: 780)
            }
        }
    }

    /// Whether translate session state (source text, result) survives closing
    /// the panel/popover, or is cleared each time the surface closes.
    public enum SessionPersistence: String, Codable, Equatable, Sendable, CaseIterable {
        case clearOnClose
        case keepUntilRestart
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
    public var openRouterModelIdentifier: String
    public var groqModelIdentifier: String
    public var openAICompatibleModelIdentifier: String
    public var openAICompatibleEndpoint: String
    public var anthropicCompatibleModelIdentifier: String
    public var anthropicCompatibleEndpoint: String
    /// Providers whose cloud-transmission disclosure the user has
    /// acknowledged. Tracks acknowledgement only, never request content.
    public var acknowledgedCloudDisclosureProviders: Set<TranslationProviderID>
    public var isEnabled: Bool
    public var showInMenuPopover: Bool
    public var autoCaptureSelectedText: Bool
    public var autoTranslateDelayMs: Int
    public var panelSize: PanelSize
    public var sessionPersistence: SessionPersistence

    public enum AutoTranslateDelayPreset: Int, CaseIterable {
        case ms250 = 250
        case ms500 = 500
        case ms750 = 750
        case ms1000 = 1000
        case ms1500 = 1500

        public var timeInterval: TimeInterval {
            TimeInterval(rawValue) / 1000.0
        }
    }

    private enum CodingKeys: String, CodingKey {
        case preferredProviderID
        case shortcut
        case defaultSourceLanguage
        case openAIModelIdentifier
        case anthropicModelIdentifier
        case geminiModelIdentifier
        case deepLEndpoint
        case openRouterModelIdentifier
        case groqModelIdentifier
        case openAICompatibleModelIdentifier
        case openAICompatibleEndpoint
        case anthropicCompatibleModelIdentifier
        case anthropicCompatibleEndpoint
        case acknowledgedCloudDisclosureProviders
        case isEnabled
        case showInMenuPopover
        case autoCaptureSelectedText
        case autoTranslateDelayMs
        case panelSize
        case sessionPersistence
    }

    public init(
        preferredProviderID: TranslationProviderID? = nil,
        shortcut: Shortcut = Shortcut(keyCode: 8, modifiers: [.option]),
        defaultSourceLanguage: TranslationLanguage? = nil,
        openAIModelIdentifier: String = TranslationOptions.defaultOpenAIModelIdentifier,
        anthropicModelIdentifier: String = TranslationOptions.defaultAnthropicModelIdentifier,
        geminiModelIdentifier: String = TranslationOptions.defaultGeminiModelIdentifier,
        deepLEndpoint: DeepLEndpoint = .free,
        openRouterModelIdentifier: String = TranslationOptions.defaultOpenRouterModelIdentifier,
        groqModelIdentifier: String = TranslationOptions.defaultGroqModelIdentifier,
        openAICompatibleModelIdentifier: String = TranslationOptions.defaultOpenAICompatibleModelIdentifier,
        openAICompatibleEndpoint: String = "",
        anthropicCompatibleModelIdentifier: String = TranslationOptions.defaultAnthropicCompatibleModelIdentifier,
        anthropicCompatibleEndpoint: String = "",
        acknowledgedCloudDisclosureProviders: Set<TranslationProviderID> = [],
        isEnabled: Bool = false,
        showInMenuPopover: Bool = false,
        autoCaptureSelectedText: Bool = true,
        autoTranslateDelayMs: Int = AutoTranslateDelayPreset.ms500.rawValue,
        panelSize: PanelSize = .medium,
        sessionPersistence: SessionPersistence = .keepUntilRestart
    ) {
        self.preferredProviderID = preferredProviderID
        self.shortcut = shortcut
        self.defaultSourceLanguage = defaultSourceLanguage
        self.openAIModelIdentifier = openAIModelIdentifier
        self.anthropicModelIdentifier = anthropicModelIdentifier
        self.geminiModelIdentifier = geminiModelIdentifier
        self.deepLEndpoint = deepLEndpoint
        self.openRouterModelIdentifier = openRouterModelIdentifier
        self.groqModelIdentifier = groqModelIdentifier
        self.openAICompatibleModelIdentifier = openAICompatibleModelIdentifier
        self.openAICompatibleEndpoint = openAICompatibleEndpoint
        self.anthropicCompatibleModelIdentifier = anthropicCompatibleModelIdentifier
        self.anthropicCompatibleEndpoint = anthropicCompatibleEndpoint
        self.acknowledgedCloudDisclosureProviders = acknowledgedCloudDisclosureProviders
        self.isEnabled = isEnabled
        self.showInMenuPopover = showInMenuPopover
        self.autoCaptureSelectedText = autoCaptureSelectedText
        self.autoTranslateDelayMs = autoTranslateDelayMs
        self.panelSize = panelSize
        self.sessionPersistence = sessionPersistence
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        preferredProviderID = try container.decodeIfPresent(TranslationProviderID.self, forKey: .preferredProviderID)
        shortcut = try container.decodeIfPresent(Shortcut.self, forKey: .shortcut) ?? Shortcut(keyCode: 8, modifiers: [.option])
        defaultSourceLanguage = try container.decodeIfPresent(TranslationLanguage.self, forKey: .defaultSourceLanguage)
        openAIModelIdentifier = try container.decodeIfPresent(String.self, forKey: .openAIModelIdentifier)
            ?? Self.defaultOpenAIModelIdentifier
        anthropicModelIdentifier = try container.decodeIfPresent(String.self, forKey: .anthropicModelIdentifier)
            ?? Self.defaultAnthropicModelIdentifier
        geminiModelIdentifier = try container.decodeIfPresent(String.self, forKey: .geminiModelIdentifier)
            ?? Self.defaultGeminiModelIdentifier
        deepLEndpoint = try container.decodeIfPresent(DeepLEndpoint.self, forKey: .deepLEndpoint) ?? .free
        openRouterModelIdentifier = try container.decodeIfPresent(String.self, forKey: .openRouterModelIdentifier)
            ?? Self.defaultOpenRouterModelIdentifier
        groqModelIdentifier = try container.decodeIfPresent(String.self, forKey: .groqModelIdentifier)
            ?? Self.defaultGroqModelIdentifier
        openAICompatibleModelIdentifier = try container.decodeIfPresent(String.self, forKey: .openAICompatibleModelIdentifier)
            ?? Self.defaultOpenAICompatibleModelIdentifier
        openAICompatibleEndpoint = try container.decodeIfPresent(String.self, forKey: .openAICompatibleEndpoint) ?? ""
        anthropicCompatibleModelIdentifier = try container.decodeIfPresent(String.self, forKey: .anthropicCompatibleModelIdentifier)
            ?? Self.defaultAnthropicCompatibleModelIdentifier
        anthropicCompatibleEndpoint = try container.decodeIfPresent(String.self, forKey: .anthropicCompatibleEndpoint) ?? ""
        acknowledgedCloudDisclosureProviders = try container.decodeIfPresent(
            Set<TranslationProviderID>.self,
            forKey: .acknowledgedCloudDisclosureProviders
        )
            ?? []
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? false
        showInMenuPopover = try container.decodeIfPresent(Bool.self, forKey: .showInMenuPopover) ?? false
        autoCaptureSelectedText = try container.decodeIfPresent(Bool.self, forKey: .autoCaptureSelectedText) ?? true
        autoTranslateDelayMs = try container.decodeIfPresent(Int.self, forKey: .autoTranslateDelayMs) ?? AutoTranslateDelayPreset.ms500
            .rawValue
        panelSize = try container.decodeIfPresent(PanelSize.self, forKey: .panelSize) ?? .medium
        sessionPersistence = try container.decodeIfPresent(SessionPersistence.self, forKey: .sessionPersistence) ?? .keepUntilRestart
    }
}
