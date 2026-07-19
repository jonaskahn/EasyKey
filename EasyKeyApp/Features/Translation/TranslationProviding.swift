import EasyEngineCore
import Foundation

/// Narrow contract every translation provider adapter implements: submit a
/// validated request, return a response, or throw a `TranslationError`.
/// Networking, Keychain, and platform frameworks stay behind the concrete
/// adapter; `TranslationModel` only ever sees this seam.
protocol TranslationProviding: Sendable {
    func translate(_ request: TranslationRequest) async throws -> TranslationResponse
}

/// Resolves a provider identifier to a live adapter, or `nil` when the
/// provider is not currently constructible (e.g. missing credentials).
typealias TranslationProviderLookup = @Sendable (TranslationProviderID) -> TranslationProviding?

/// Asks whether a cloud request to `providerID` may proceed. Returns `false`
/// when the user declines or cancels a disclosure prompt. Non-cloud
/// providers may resolve immediately with `true`.
typealias TranslationDisclosureDecision = @MainActor @Sendable (TranslationProviderID) async -> Bool

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
        case .automatic, .apple:
            return nil
        }
        return URL(string: value)
    }
}
