import EasyEngineCore
import Foundation

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
