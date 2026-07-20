import Foundation

/// Identifies a translation provider a user can select or configure.
/// `automatic` is a preference value resolved to a concrete provider by
/// platform capability and configuration; it never appears on a request
/// sent to an adapter.
public enum TranslationProviderID: String, Codable, CaseIterable, Sendable {
    case automatic
    case apple
    case deepL
    case google
    case openAI
    case anthropic
    case gemini
    case openRouter
    case groq
    case openAICompatible
    case anthropicCompatible
}
