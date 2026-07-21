import EasyEngineCore
import Foundation

struct TranslationModelCatalogEntry: Equatable, Sendable {
    let identifier: String
    let displayName: String
}

enum TranslationModelCatalogError: Error, Equatable {
    case missingCredentials
    case requestFailed(status: Int)
    case malformedResponse
    case unsupportedProvider
}

protocol TranslationModelCatalogProviding: Sendable {
    func fetchModels(for provider: TranslationProviderID) async throws(TranslationModelCatalogError) -> [TranslationModelCatalogEntry]
}

struct LiveTranslationModelCatalog: TranslationModelCatalogProviding {
    private let credentialStore: TranslationCredentialStoring
    private let session: URLSession

    init(
        credentialStore: TranslationCredentialStoring,
        session: URLSession = TranslationNetworkSession.ephemeral
    ) {
        self.credentialStore = credentialStore
        self.session = session
    }

    func fetchModels(
        for provider: TranslationProviderID
    ) async throws(TranslationModelCatalogError) -> [TranslationModelCatalogEntry] {
        switch provider {
        case .openAI:
            let key = try await resolveCredential(for: .openAI)
            let request = makeRequest(
                url: "https://api.openai.com/v1/models",
                headers: ["Authorization": "Bearer \(key)"]
            )
            return try await fetchOpenAICompatibleModels(request: request)

        case .anthropic:
            let key = try await resolveCredential(for: .anthropic)
            return try await fetchAnthropicModels(apiKey: key)

        case .gemini:
            let key = try await resolveCredential(for: .gemini)
            return try await fetchGeminiModels(apiKey: key)

        case .openRouter:
            let key = try await resolveCredential(for: .openRouter)
            let request = makeRequest(
                url: "https://openrouter.ai/api/v1/models",
                headers: ["Authorization": "Bearer \(key)"]
            )
            return try await fetchOpenAICompatibleModels(request: request)

        case .groq:
            let key = try await resolveCredential(for: .groq)
            let request = makeRequest(
                url: "https://api.groq.com/openai/v1/models",
                headers: ["Authorization": "Bearer \(key)"]
            )
            return try await fetchOpenAICompatibleModels(request: request)

        case .automatic, .apple, .deepL, .google, .openAICompatible, .anthropicCompatible:
            throw .unsupportedProvider
        }
    }

    private func resolveCredential(
        for provider: TranslationProviderID
    ) async throws(TranslationModelCatalogError) -> String {
        let stored: String?
        do {
            stored = try credentialStore.credential(for: provider)
        } catch {
            throw .missingCredentials
        }
        guard let stored, !stored.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw .missingCredentials
        }
        return stored.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func makeRequest(url: String, headers: [String: String]) -> URLRequest {
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "GET"
        request.timeoutInterval = 20
        for (name, value) in headers {
            request.setValue(value, forHTTPHeaderField: name)
        }
        return request
    }

    private func perform(_ request: URLRequest) async throws(TranslationModelCatalogError) -> Data {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            throw .requestFailed(status: error.errorCode)
        } catch {
            throw .requestFailed(status: -1)
        }
        guard let http = response as? HTTPURLResponse else {
            throw .requestFailed(status: -1)
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw .requestFailed(status: http.statusCode)
        }
        guard data.count <= 262_144 else {
            throw .malformedResponse
        }
        return data
    }

    private func fetchOpenAICompatibleModels(
        request: URLRequest
    ) async throws(TranslationModelCatalogError) -> [TranslationModelCatalogEntry] {
        let data = try await perform(request)
        struct ListResponse: Decodable {
            struct Item: Decodable { let id: String }
            let data: [Item]
        }
        let decoded: ListResponse
        do {
            decoded = try JSONDecoder().decode(ListResponse.self, from: data)
        } catch {
            throw .malformedResponse
        }
        return decoded.data.map { TranslationModelCatalogEntry(identifier: $0.id, displayName: $0.id) }
    }

    private func fetchAnthropicModels(
        apiKey: String
    ) async throws(TranslationModelCatalogError) -> [TranslationModelCatalogEntry] {
        var entries: [TranslationModelCatalogEntry] = []
        var afterID: String?
        let limit = 200
        repeat {
            var urlString = "https://api.anthropic.com/v1/models?limit=\(limit)"
            if let after = afterID {
                urlString += "&after_id=\(after)"
            }
            let request = makeRequest(
                url: urlString,
                headers: [
                    "x-api-key": apiKey,
                    "anthropic-version": "2023-06-01",
                ]
            )
            let data = try await perform(request)
            struct Page: Decodable {
                let data: [AnthropicModelItem]
                let hasMore: Bool
                let lastID: String?
                enum CodingKeys: String, CodingKey {
                    case data
                    case hasMore = "has_more"
                    case lastID = "last_id"
                }
            }
            let page: Page
            do {
                page = try JSONDecoder().decode(Page.self, from: data)
            } catch {
                throw .malformedResponse
            }
            entries.append(contentsOf: page.data.map {
                TranslationModelCatalogEntry(identifier: $0.id, displayName: $0.displayName)
            })
            if page.hasMore, let lastID = page.lastID {
                afterID = lastID
            } else {
                afterID = nil
            }
        } while afterID != nil
        return entries
    }

    private func fetchGeminiModels(
        apiKey: String
    ) async throws(TranslationModelCatalogError) -> [TranslationModelCatalogEntry] {
        let request = makeRequest(
            url: "https://generativelanguage.googleapis.com/v1beta/models?pageSize=200",
            headers: ["x-goog-api-key": apiKey]
        )
        let data = try await perform(request)
        struct ListResponse: Decodable {
            struct Item: Decodable {
                let name: String
                let displayName: String
                let supportedGenerationMethods: [String]?
            }

            let models: [Item]?
        }
        let decoded: ListResponse
        do {
            decoded = try JSONDecoder().decode(ListResponse.self, from: data)
        } catch {
            throw .malformedResponse
        }
        guard let models = decoded.models else { throw .malformedResponse }
        return models
            .filter { model in
                model.supportedGenerationMethods?.contains("generateContent") == true
            }
            .compactMap { model in
                let id = model.name.hasPrefix("models/") ? String(model.name.dropFirst(7)) : model.name
                return TranslationModelCatalogEntry(identifier: id, displayName: model.displayName)
            }
    }
}

private struct AnthropicModelItem: Decodable {
    let id: String
    let displayName: String
    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
    }
}
