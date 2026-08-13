import EasyEngineCore
import Foundation

@MainActor
protocol TranslationCredentialValidating {
    func validate(
        _ credential: String,
        for provider: TranslationProviderID,
        options: TranslationOptions
    ) async throws -> Bool
}

@MainActor
struct LiveTranslationCredentialValidator: TranslationCredentialValidating {
    private let session: URLSession

    init(session: URLSession = TranslationNetworkSession.ephemeral) {
        self.session = session
    }

    func validate(
        _ credential: String,
        for provider: TranslationProviderID,
        options: TranslationOptions
    ) async throws -> Bool {
        switch provider {
        case .deepL:
            return try await DeepLTranslationProvider(
                endpoint: options.deepLEndpoint,
                credentialStore: InMemoryTranslationCredentialStore(),
                session: session
            ).validateCredential(credential)
        case .google:
            return try await GoogleTranslationProvider(
                credentialStore: InMemoryTranslationCredentialStore(),
                session: session
            ).validateCredential(credential)
        case .openAI:
            return try await validateRequest(
                url: validatedURL("https://api.openai.com/v1/models"),
                headers: ["Authorization": "Bearer \(credential)"]
            )
        case .anthropic:
            return try await validateRequest(
                url: validatedURL("https://api.anthropic.com/v1/models"),
                headers: ["x-api-key": credential, "anthropic-version": "2023-06-01"]
            )
        case .gemini:
            return try await validateRequest(
                url: validatedURL("https://generativelanguage.googleapis.com/v1beta/models?pageSize=1"),
                headers: ["x-goog-api-key": credential]
            )
        case .openRouter:
            return try await validateRequest(
                url: validatedURL("https://openrouter.ai/api/v1/models"),
                headers: ["Authorization": "Bearer \(credential)"]
            )
        case .groq:
            return try await validateRequest(
                url: validatedURL("https://api.groq.com/openai/v1/models"),
                headers: ["Authorization": "Bearer \(credential)"]
            )
        case .openAICompatible:
            guard !options.openAICompatibleEndpoint.isEmpty else { return false }
            return true
        case .anthropicCompatible:
            guard !options.anthropicCompatibleEndpoint.isEmpty else { return false }
            return true
        case .automatic, .apple:
            return false
        }
    }

    private func validateRequest(url: URL, headers: [String: String]) async throws -> Bool {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 20
        for (name, value) in headers {
            request.setValue(value, forHTTPHeaderField: name)
        }
        let (_, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        switch response.statusCode {
        case 200 ..< 300: return true
        case 400, 401, 403: return false
        default: throw URLError(.badServerResponse)
        }
    }
}
