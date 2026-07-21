import EasyEngineCore
@testable import EasyKey
import XCTest

final class TranslationModelCatalogTests: XCTestCase {
    private var credentialStore: InMemoryTranslationCredentialStore!

    override func setUpWithError() throws {
        credentialStore = InMemoryTranslationCredentialStore()
    }

    override func tearDownWithError() throws {
        credentialStore = nil
        CatalogURLProtocol.handler = nil
    }

    func testFetchOpenAIModels_DecodesSuccessfully() async throws {
        try credentialStore.save("test-key", for: .openAI)
        let catalog = makeCatalog()
        CatalogURLProtocol.handler = { _ in
            (.ok, """
            {"object":"list","data":[{"id":"gpt-4o-mini","object":"model"},{"id":"gpt-4.1","object":"model"}]}
            """)
        }

        let models = try await catalog.fetchModels(for: .openAI)
        XCTAssertEqual(models.count, 2)
        XCTAssertEqual(models[0].identifier, "gpt-4o-mini")
        XCTAssertEqual(models[0].displayName, "gpt-4o-mini")
        XCTAssertEqual(models[1].identifier, "gpt-4.1")
    }

    func testFetchAnthropicModels_WithPagination() async throws {
        try credentialStore.save("test-key", for: .anthropic)
        let catalog = makeCatalog()

        var callCount = 0
        CatalogURLProtocol.handler = { request in
            callCount += 1
            let hasAfter = request.url?.absoluteString.contains("after_id") == true
            if hasAfter {
                return (.ok, """
                {"data":[{"id":"claude-sonnet-4-5","display_name":"Claude Sonnet 4.5"}],"has_more":false,"last_id":null}
                """)
            }
            return (.ok, """
            {"data":[{"id":"claude-opus-4-6","display_name":"Claude Opus 4.6"}],"has_more":true,"last_id":"claude-opus-4-6"}
            """)
        }

        let models = try await catalog.fetchModels(for: .anthropic)
        XCTAssertEqual(callCount, 2)
        XCTAssertEqual(models.count, 2)
        XCTAssertEqual(models[0].identifier, "claude-opus-4-6")
        XCTAssertEqual(models[0].displayName, "Claude Opus 4.6")
        XCTAssertEqual(models[1].identifier, "claude-sonnet-4-5")
    }

    func testFetchGeminiModels_FiltersGenerateContentOnly() async throws {
        try credentialStore.save("test-key", for: .gemini)
        let catalog = makeCatalog()
        CatalogURLProtocol.handler = { _ in
            (.ok, """
            {"models":[
              {"name":"models/gemini-2.0-flash","displayName":"Gemini 2.0 Flash","supportedGenerationMethods":["generateContent"]},
              {"name":"models/text-embedding-004","displayName":"Text Embedding","supportedGenerationMethods":["embedContent"]},
              {"name":"models/gemini-2.5-pro","displayName":"Gemini 2.5 Pro","supportedGenerationMethods":["generateContent","countTokens"]}
            ]}
            """)
        }

        let models = try await catalog.fetchModels(for: .gemini)
        XCTAssertEqual(models.count, 2)
        XCTAssertEqual(models[0].identifier, "gemini-2.0-flash")
        XCTAssertEqual(models[1].identifier, "gemini-2.5-pro")
    }

    func testFetchGeminiModels_StripsModelsPrefix() async throws {
        try credentialStore.save("test-key", for: .gemini)
        let catalog = makeCatalog()
        let name = #"{"name":"models/gemini-2.0-flash","displayName":"G Flash","supportedGenerationMethods":["generateContent"]}"#
        let json = "{\"models\":[\(name)]}"
        CatalogURLProtocol.handler = { _ in (.ok, json) }

        let models = try await catalog.fetchModels(for: .gemini)
        XCTAssertEqual(models[0].identifier, "gemini-2.0-flash")
    }

    func testFetchOpenRouterModels() async throws {
        let catalog = makeCatalog()
        CatalogURLProtocol.handler = { _ in
            (.ok, """
            {"data":[{"id":"openai/gpt-4o-mini","name":"GPT-4o mini"},{"id":"anthropic/claude-sonnet-4-5","name":"Claude Sonnet 4.5"}]}
            """)
        }

        let models = try await catalog.fetchModels(for: .openRouter)
        XCTAssertEqual(models.count, 2)
        XCTAssertEqual(models[0].identifier, "openai/gpt-4o-mini")
        XCTAssertEqual(models[0].displayName, "GPT-4o mini")
        XCTAssertEqual(models[1].identifier, "anthropic/claude-sonnet-4-5")
        XCTAssertEqual(models[1].displayName, "Claude Sonnet 4.5")
    }

    func testFetchOpenRouterModels_WithoutCredentials() async throws {
        let catalog = makeCatalog()
        CatalogURLProtocol.handler = { request in
            XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
            return (.ok, """
            {"data":[{"id":"openai/gpt-4o-mini","name":"GPT-4o mini"}]}
            """)
        }

        let models = try await catalog.fetchModels(for: .openRouter)
        XCTAssertEqual(models.count, 1)
        XCTAssertEqual(models[0].identifier, "openai/gpt-4o-mini")
        XCTAssertEqual(models[0].displayName, "GPT-4o mini")
    }

    func testFetchOpenRouterModels_AllowsLargeCatalogResponse() async throws {
        let catalog = makeCatalog()
        let items = (0 ..< 4000).map { index in
            #"{"id":"provider/model-\#(index)","name":"Model \#(index) with a descriptive display name"}"#
        }
        let responseBody = #"{"data":[\#(items.joined(separator: ","))]}"#
        XCTAssertGreaterThan(responseBody.utf8.count, 262_144)
        CatalogURLProtocol.handler = { _ in (.ok, responseBody) }

        let models = try await catalog.fetchModels(for: .openRouter)

        XCTAssertEqual(models.count, 4000)
        XCTAssertEqual(models.last?.identifier, "provider/model-3999")
    }

    func testFetchGroqModels() async throws {
        try credentialStore.save("test-key", for: .groq)
        let catalog = makeCatalog()
        CatalogURLProtocol.handler = { _ in
            (.ok, """
            {"data":[{"id":"llama-3.1-8b-instant"},{"id":"mixtral-8x7b-32768"}]}
            """)
        }

        let models = try await catalog.fetchModels(for: .groq)
        XCTAssertEqual(models.count, 2)
    }

    func testMissingCredentialsThrows() async {
        let catalog = makeCatalog()
        do {
            _ = try await catalog.fetchModels(for: .openAI)
            XCTFail("Expected missingCredentials error")
        } catch {
            XCTAssertEqual(error, .missingCredentials)
        }
    }

    func testWhitespaceOnlyCredentialThrows() async {
        let rawStore = RawInMemoryCredentialStore()
        try? rawStore.save("   ", for: .openAI)
        let catalog = LiveTranslationModelCatalog(
            credentialStore: rawStore,
            session: makeSession()
        )
        do {
            _ = try await catalog.fetchModels(for: .openAI)
            XCTFail("Expected missingCredentials error")
        } catch {
            XCTAssertEqual(error, .missingCredentials)
        }
    }

    func testUnsupportedProviderThrows() async {
        let catalog = makeCatalog()
        do {
            _ = try await catalog.fetchModels(for: .deepL)
            XCTFail("Expected unsupportedProvider error")
        } catch {
            XCTAssertEqual(error, .unsupportedProvider)
        }
    }

    func testHTTPErrorStatusCode() async throws {
        try credentialStore.save("test-key", for: .openAI)
        let catalog = makeCatalog()
        CatalogURLProtocol.handler = { _ in (.unauthorized, "") }
        do {
            _ = try await catalog.fetchModels(for: .openAI)
            XCTFail("Expected requestFailed error")
        } catch {
            XCTAssertEqual(error, .requestFailed(status: 401))
        }
    }

    func testMalformedJSONResponse() async throws {
        try credentialStore.save("test-key", for: .openAI)
        let catalog = makeCatalog()
        CatalogURLProtocol.handler = { _ in (.ok, "not json") }
        do {
            _ = try await catalog.fetchModels(for: .openAI)
            XCTFail("Expected malformedResponse error")
        } catch {
            XCTAssertEqual(error, .malformedResponse)
        }
    }

    func testOversizedResponseThrowsMalformed() async throws {
        try credentialStore.save("test-key", for: .openAI)
        let catalog = makeCatalog()
        CatalogURLProtocol.handler = { _ in (.ok, String(repeating: "x", count: 300_000)) }
        do {
            _ = try await catalog.fetchModels(for: .openAI)
            XCTFail("Expected malformedResponse error")
        } catch {
            XCTAssertEqual(error, .malformedResponse)
        }
    }

    func testURLErrorMappedToRequestFailed() async throws {
        try credentialStore.save("test-key", for: .openAI)
        let catalog = makeCatalog()
        CatalogURLProtocol.handler = { _ in throw URLError(.timedOut) }
        do {
            _ = try await catalog.fetchModels(for: .openAI)
            XCTFail("Expected requestFailed error")
        } catch {
            XCTAssertEqual(error, .requestFailed(status: URLError.Code.timedOut.rawValue))
        }
    }

    func testFetchModels_AllFiveOfficialProviders_SucceedWithValidResponse() async throws {
        for provider: TranslationProviderID in [.openAI, .anthropic, .gemini, .openRouter, .groq] {
            try credentialStore.save("test-key", for: provider)
        }
        let catalog = makeCatalog()
        CatalogURLProtocol.handler = { request in
            if request.url?.host?.contains("anthropic") == true {
                return (.ok, """
                {"data":[{"id":"claude-opus","display_name":"Claude Opus"}],"has_more":false,"last_id":null}
                """)
            }
            if request.url?.host?.contains("googleapis") == true {
                return (.ok, """
                {"models":[{"name":"models/gemini-flash","displayName":"Gemini Flash","supportedGenerationMethods":["generateContent"]}]}
                """)
            }
            return (.ok, """
            {"object":"list","data":[{"id":"test-model"}]}
            """)
        }

        let openAI = try await catalog.fetchModels(for: .openAI)
        XCTAssertEqual(openAI.first?.identifier, "test-model")

        let anthropic = try await catalog.fetchModels(for: .anthropic)
        XCTAssertEqual(anthropic.first?.identifier, "claude-opus")

        let gemini = try await catalog.fetchModels(for: .gemini)
        XCTAssertEqual(gemini.first?.identifier, "gemini-flash")

        let openRouter = try await catalog.fetchModels(for: .openRouter)
        XCTAssertEqual(openRouter.first?.identifier, "test-model")

        let groq = try await catalog.fetchModels(for: .groq)
        XCTAssertEqual(groq.first?.identifier, "test-model")
    }

    private func makeCatalog() -> LiveTranslationModelCatalog {
        LiveTranslationModelCatalog(credentialStore: credentialStore, session: makeSession())
    }

    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [CatalogURLProtocol.self]
        return URLSession(configuration: config)
    }
}

private final class RawInMemoryCredentialStore: TranslationCredentialStoring, @unchecked Sendable {
    private var credentials: [TranslationProviderID: String] = [:]

    func hasCredential(for provider: TranslationProviderID) throws -> Bool {
        credentials[provider] != nil
    }

    func credential(for provider: TranslationProviderID) throws -> String? {
        credentials[provider]
    }

    func save(_ apiKey: String, for provider: TranslationProviderID) throws {
        credentials[provider] = apiKey
    }

    func deleteCredential(for provider: TranslationProviderID) throws {
        credentials.removeValue(forKey: provider)
    }
}

private final class CatalogURLProtocol: URLProtocol {
    typealias Handler = (URLRequest) throws -> (status: Int, body: String)
    static var handler: Handler?

    override static func canInit(with _: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let result = try handler(request)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: result.status,
                httpVersion: nil,
                headerFields: nil
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data(result.body.utf8))
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private extension Int {
    static let ok = 200
    static let unauthorized = 401
}
