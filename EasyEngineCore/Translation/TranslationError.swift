import Foundation

/// Normalized, recoverable translation failure categories. Cases carry only
/// diagnostic metadata safe to display or log — never source text,
/// translated text, prompts, or credentials.
public enum TranslationError: Error, Equatable, Sendable {
    case noProviderConfigured
    case missingCredentials(provider: TranslationProviderID)
    case unsupportedLanguagePair(source: TranslationLanguage, target: TranslationLanguage)
    case appleLanguageDownloadRequired
    case networkUnavailable
    case requestTimedOut
    case rateLimitExceeded(provider: TranslationProviderID)
    case requestTooLarge
    case providerUnavailable(provider: TranslationProviderID, httpStatus: Int?)
    case invalidResponse(provider: TranslationProviderID)
    case cancelled
}
