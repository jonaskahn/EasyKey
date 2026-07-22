import EasyEngineCore
import Foundation

/// Narrow contract every translation provider adapter implements: submit a
/// validated request, return a response, or throw a `TranslationError`.
/// Networking, Keychain, and platform frameworks stay behind the concrete
/// adapter; `TranslationModel` only ever sees this seam.
protocol TranslationProviding: Sendable {
    func translate(_ request: TranslationRequest) async throws -> TranslationResponse
}

protocol TranslationEndpointDisclosing: Sendable {
    var disclosureIdentity: TranslationDisclosureIdentity { get }
}

/// Resolves a provider identifier to a live adapter, or `nil` when the
/// provider is not currently constructible (e.g. missing credentials).
typealias TranslationProviderLookup = @Sendable (TranslationProviderID) -> TranslationProviding?

/// Asks whether a cloud request to `providerID` may proceed. Returns `false`
/// when the user declines or cancels a disclosure prompt. Non-cloud
/// providers may resolve immediately with `true`.
typealias TranslationDisclosureDecision = @MainActor @Sendable (TranslationDisclosureIdentity) async -> Bool

struct TranslationDisclosureIdentity: Hashable, Sendable {
    let providerID: TranslationProviderID
    let endpointOrigin: String?

    init(providerID: TranslationProviderID, endpointOrigin: String? = nil) {
        self.providerID = providerID
        self.endpointOrigin = endpointOrigin
    }
}

struct ValidatedTranslationEndpoint: Equatable, Sendable {
    let url: URL
    let origin: String

    init?(_ url: URL) {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme?.lowercased() == "https",
              let host = components.host?.lowercased(),
              !host.isEmpty,
              components.user == nil,
              components.password == nil
        else { return nil }

        components.scheme = "https"
        components.host = host
        if components.port == 443 {
            components.port = nil
        }
        guard let normalizedURL = components.url else { return nil }

        var originComponents = URLComponents()
        originComponents.scheme = "https"
        originComponents.host = host
        originComponents.port = components.port
        guard let normalizedOrigin = originComponents.url?.absoluteString else { return nil }

        self.url = normalizedURL
        origin = normalizedOrigin
    }

    init?(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed) else { return nil }
        self.init(url)
    }
}

enum TranslationNetworkSession {
    static let ephemeral: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        configuration.urlCredentialStorage = nil
        return URLSession(configuration: configuration)
    }()
}

extension TranslationProviderID {
    var displayName: String {
        switch self {
        case .automatic: "Automatic"
        case .apple: "Apple"
        case .deepL: "DeepL"
        case .google: "Google Cloud Translation"
        case .openAI: "OpenAI"
        case .anthropic: "Anthropic"
        case .gemini: "Gemini"
        case .openRouter: "OpenRouter"
        case .groq: "Groq"
        case .openAICompatible: "OpenAI-Compatible"
        case .anthropicCompatible: "Anthropic-Compatible"
        }
    }

    var privacyURL: URL? {
        let value: String
        switch self {
        case .deepL:
            value = "https://www.deepl.com/privacy"
        case .google:
            value = "https://cloud.google.com/translate/data-usage"
        case .openAI:
            value = "https://platform.openai.com/docs/guides/your-data"
        case .anthropic:
            value = "https://privacy.anthropic.com/"
        case .gemini:
            value = "https://ai.google.dev/gemini-api/terms"
        case .openRouter:
            value = "https://openrouter.ai/privacy"
        case .groq:
            value = "https://groq.com/privacy-policy/"
        case .openAICompatible:
            value = "https://platform.openai.com/docs/guides/your-data"
        case .anthropicCompatible:
            value = "https://privacy.anthropic.com/"
        case .automatic, .apple:
            return nil
        }
        return URL(string: value)
    }
}
