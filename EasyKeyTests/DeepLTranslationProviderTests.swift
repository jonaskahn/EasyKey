import EasyEngineCore
@testable import EasyKey
import XCTest

final class DeepLTranslationProviderTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MockDeepLURLProtocol.requestHandler = nil
        MockDeepLURLProtocol.capturedRequests = []
    }

    private func mockSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockDeepLURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    private func throwingSession(_ error: URLError) -> URLSession {
        ThrowingURLProtocol.error = error
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ThrowingURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    private func nonURLErrorSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [NonURLErrorProtocol.self]
        return URLSession(configuration: configuration)
    }

    private func makeRequest(
        sourceText: String = "hello",
        sourceLanguage: TranslationLanguage? = .english,
        targetLanguage: TranslationLanguage = .vietnamese
    ) throws -> TranslationRequest {
        try XCTUnwrap(TranslationRequest(
            sourceText: sourceText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            providerID: .deepL
        ))
    }

    private func jsonResponse(url: URL, status: Int, body: [String: Any]) throws -> (Data, HTTPURLResponse) {
        let data = try JSONSerialization.data(withJSONObject: body)
        let response = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil))
        return (data, response)
    }

    // MARK: - Host selection

    func testTranslate_WithFreeEndpoint_UsesFreeHost() async throws {
        let store = InMemoryDeepLCredentialStore(credentials: [.deepL: "key"])
        let provider = DeepLTranslationProvider(endpoint: .free, credentialStore: store, session: mockSession())
        MockDeepLURLProtocol.requestHandler = { [self] request in
            try jsonResponse(
                url: request.url!,
                status: 200,
                body: ["translations": [["detected_source_language": "EN", "text": "xin chào"]]]
            )
        }

        _ = try await provider.translate(makeRequest())

        XCTAssertEqual(MockDeepLURLProtocol.capturedRequests.first?.url?.host, "api-free.deepl.com")
    }

    func testTranslate_WithProEndpoint_UsesProHost() async throws {
        let store = InMemoryDeepLCredentialStore(credentials: [.deepL: "key"])
        let provider = DeepLTranslationProvider(endpoint: .pro, credentialStore: store, session: mockSession())
        MockDeepLURLProtocol.requestHandler = { [self] request in
            try jsonResponse(
                url: request.url!,
                status: 200,
                body: ["translations": [["detected_source_language": "EN", "text": "xin chào"]]]
            )
        }

        _ = try await provider.translate(makeRequest())

        XCTAssertEqual(MockDeepLURLProtocol.capturedRequests.first?.url?.host, "api.deepl.com")
        XCTAssertTrue(MockDeepLURLProtocol.capturedRequests.first?.url?.scheme == "https")
    }

    // MARK: - Request shape

    func testTranslate_SendsAuthorizationHeaderAndJSONBody() async throws {
        let store = InMemoryDeepLCredentialStore(credentials: [.deepL: "secret-key"])
        let provider = DeepLTranslationProvider(endpoint: .free, credentialStore: store, session: mockSession())
        MockDeepLURLProtocol.requestHandler = { [self] request in
            try jsonResponse(
                url: request.url!,
                status: 200,
                body: ["translations": [["detected_source_language": "EN", "text": "xin chào"]]]
            )
        }

        _ = try await provider.translate(makeRequest(sourceText: "hello world"))

        let sent = try XCTUnwrap(MockDeepLURLProtocol.capturedRequests.first)
        XCTAssertEqual(sent.value(forHTTPHeaderField: "Authorization"), "DeepL-Auth-Key secret-key")
        XCTAssertEqual(sent.httpMethod, "POST")

        let body = try XCTUnwrap(sent.httpBodyStreamData() ?? sent.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["target_lang"] as? String, "VI")
        XCTAssertEqual(json["source_lang"] as? String, "EN")
        XCTAssertEqual(json["text"] as? [String], ["hello world"])
    }

    func testTranslate_WithAutoDetectSource_OmitsSourceLangField() async throws {
        let store = InMemoryDeepLCredentialStore(credentials: [.deepL: "key"])
        let provider = DeepLTranslationProvider(endpoint: .free, credentialStore: store, session: mockSession())
        MockDeepLURLProtocol.requestHandler = { [self] request in
            try jsonResponse(
                url: request.url!,
                status: 200,
                body: ["translations": [["detected_source_language": "EN", "text": "xin chào"]]]
            )
        }

        _ = try await provider.translate(makeRequest(sourceLanguage: nil))

        let sent = try XCTUnwrap(MockDeepLURLProtocol.capturedRequests.first)
        let body = try XCTUnwrap(sent.httpBodyStreamData() ?? sent.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertNil(json["source_lang"])
    }

    // MARK: - Successful parsing

    func testTranslate_WithSuccessfulResponse_ReturnsMappedResult() async throws {
        let store = InMemoryDeepLCredentialStore(credentials: [.deepL: "key"])
        let provider = DeepLTranslationProvider(endpoint: .free, credentialStore: store, session: mockSession())
        MockDeepLURLProtocol.requestHandler = { [self] request in
            try jsonResponse(
                url: request.url!,
                status: 200,
                body: ["translations": [["detected_source_language": "EN", "text": "xin chào"]]]
            )
        }

        let response = try await provider.translate(makeRequest())

        XCTAssertEqual(response.translatedText, "xin chào")
        XCTAssertEqual(response.providerID, .deepL)
        XCTAssertEqual(response.detectedSourceLanguage?.identifier, "EN")
    }

    // MARK: - Credentials

    func testTranslate_WithNoStoredCredential_ThrowsMissingCredentials() async throws {
        let store = InMemoryDeepLCredentialStore()
        let provider = DeepLTranslationProvider(endpoint: .free, credentialStore: store, session: mockSession())

        do {
            _ = try await provider.translate(makeRequest())
            XCTFail("Expected missingCredentials")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, .missingCredentials(provider: .deepL))
        }
        XCTAssertTrue(MockDeepLURLProtocol.capturedRequests.isEmpty, "Must not call the network without credentials")
    }

    func testTranslate_WithBlankStoredCredential_ThrowsMissingCredentials() async throws {
        let store = InMemoryDeepLCredentialStore(credentials: [.deepL: ""])
        let provider = DeepLTranslationProvider(endpoint: .free, credentialStore: store, session: mockSession())

        do {
            _ = try await provider.translate(makeRequest())
            XCTFail("Expected missingCredentials")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, .missingCredentials(provider: .deepL))
        }
    }

    func testTranslate_WithCredentialStoreThrowing_ThrowsMissingCredentials() async throws {
        let provider = DeepLTranslationProvider(endpoint: .free, credentialStore: ThrowingCredentialStore(), session: mockSession())

        do {
            _ = try await provider.translate(makeRequest())
            XCTFail("Expected missingCredentials")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, .missingCredentials(provider: .deepL))
        }
        XCTAssertTrue(MockDeepLURLProtocol.capturedRequests.isEmpty, "Must not call the network when credential lookup fails")
    }

    // MARK: - HTTP error mapping

    func testTranslate_With403_ThrowsMissingCredentials() async throws {
        try await assertHTTPStatus(403, mapsTo: .missingCredentials(provider: .deepL))
    }

    func testTranslate_With429_ThrowsRateLimitExceeded() async throws {
        try await assertHTTPStatus(429, mapsTo: .rateLimitExceeded(provider: .deepL))
    }

    func testTranslate_With456QuotaExceeded_ThrowsRateLimitExceeded() async throws {
        try await assertHTTPStatus(456, mapsTo: .rateLimitExceeded(provider: .deepL))
    }

    func testTranslate_With413_ThrowsRequestTooLarge() async throws {
        try await assertHTTPStatus(413, mapsTo: .requestTooLarge)
    }

    func testTranslate_With500_ThrowsProviderUnavailableWithStatus() async throws {
        try await assertHTTPStatus(500, mapsTo: .providerUnavailable(provider: .deepL, httpStatus: 500))
    }

    func testTranslate_With400_ThrowsProviderUnavailableWithStatus() async throws {
        try await assertHTTPStatus(400, mapsTo: .providerUnavailable(provider: .deepL, httpStatus: 400))
    }

    private func assertHTTPStatus(_ status: Int, mapsTo expected: EasyEngineCore.TranslationError) async throws {
        let store = InMemoryDeepLCredentialStore(credentials: [.deepL: "key"])
        let provider = DeepLTranslationProvider(endpoint: .free, credentialStore: store, session: mockSession())
        MockDeepLURLProtocol.requestHandler = { [self] request in
            try jsonResponse(url: request.url!, status: status, body: ["message": "error"])
        }

        do {
            _ = try await provider.translate(makeRequest())
            XCTFail("Expected \(expected) for status \(status)")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, expected)
        }
    }

    // MARK: - Malformed / oversized response

    func testTranslate_WithMalformedJSON_ThrowsInvalidResponse() async throws {
        let store = InMemoryDeepLCredentialStore(credentials: [.deepL: "key"])
        let provider = DeepLTranslationProvider(endpoint: .free, credentialStore: store, session: mockSession())
        MockDeepLURLProtocol.requestHandler = { request in
            let response = try XCTUnwrap(HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil))
            return (Data("not json".utf8), response)
        }

        do {
            _ = try await provider.translate(makeRequest())
            XCTFail("Expected invalidResponse")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, .invalidResponse(provider: .deepL))
        }
    }

    func testTranslate_WithEmptyTranslationsArray_ThrowsInvalidResponse() async throws {
        let store = InMemoryDeepLCredentialStore(credentials: [.deepL: "key"])
        let provider = DeepLTranslationProvider(endpoint: .free, credentialStore: store, session: mockSession())
        MockDeepLURLProtocol.requestHandler = { [self] request in
            try jsonResponse(url: request.url!, status: 200, body: ["translations": []])
        }

        do {
            _ = try await provider.translate(makeRequest())
            XCTFail("Expected invalidResponse")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, .invalidResponse(provider: .deepL))
        }
    }

    func testTranslate_WithAmbiguousMultipleTranslations_ThrowsInvalidResponse() async throws {
        let store = InMemoryDeepLCredentialStore(credentials: [.deepL: "key"])
        let provider = DeepLTranslationProvider(endpoint: .free, credentialStore: store, session: mockSession())
        MockDeepLURLProtocol.requestHandler = { [self] request in
            try jsonResponse(url: request.url!, status: 200, body: [
                "translations": [
                    ["detected_source_language": "EN", "text": "a"],
                    ["detected_source_language": "EN", "text": "b"],
                ],
            ])
        }

        do {
            _ = try await provider.translate(makeRequest())
            XCTFail("Expected invalidResponse")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, .invalidResponse(provider: .deepL))
        }
    }

    func testTranslate_WithEmptyDetectedSourceLanguage_ThrowsInvalidResponse() async throws {
        let store = InMemoryDeepLCredentialStore(credentials: [.deepL: "key"])
        let provider = DeepLTranslationProvider(endpoint: .free, credentialStore: store, session: mockSession())
        MockDeepLURLProtocol.requestHandler = { [self] request in
            try jsonResponse(url: request.url!, status: 200, body: ["translations": [["detected_source_language": "", "text": "xin chào"]]])
        }

        do {
            _ = try await provider.translate(makeRequest())
            XCTFail("Expected invalidResponse")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, .invalidResponse(provider: .deepL))
        }
    }

    func testTranslate_WithBlankTranslatedText_ThrowsInvalidResponse() async throws {
        let store = InMemoryDeepLCredentialStore(credentials: [.deepL: "key"])
        let provider = DeepLTranslationProvider(endpoint: .free, credentialStore: store, session: mockSession())
        MockDeepLURLProtocol.requestHandler = { [self] request in
            try jsonResponse(url: request.url!, status: 200, body: ["translations": [["detected_source_language": "EN", "text": "  "]]])
        }

        do {
            _ = try await provider.translate(makeRequest())
            XCTFail("Expected invalidResponse")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, .invalidResponse(provider: .deepL))
        }
    }

    func testTranslate_WithNonHTTPURLResponse_ThrowsInvalidResponse() async throws {
        let store = InMemoryDeepLCredentialStore(credentials: [.deepL: "key"])
        let provider = DeepLTranslationProvider(endpoint: .free, credentialStore: store, session: mockSession())
        MockDeepLURLProtocol.requestHandler = { request in
            (Data(), URLResponse(url: request.url!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil))
        }

        do {
            _ = try await provider.translate(makeRequest())
            XCTFail("Expected invalidResponse")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, .invalidResponse(provider: .deepL))
        }
    }

    func testTranslate_WithOversizedResponse_ThrowsInvalidResponse() async throws {
        let store = InMemoryDeepLCredentialStore(credentials: [.deepL: "key"])
        let provider = DeepLTranslationProvider(endpoint: .free, credentialStore: store, session: mockSession())
        MockDeepLURLProtocol.requestHandler = { request in
            let response = try XCTUnwrap(HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil))
            let oversized = Data(repeating: 0x41, count: 1_048_577)
            return (oversized, response)
        }

        do {
            _ = try await provider.translate(makeRequest())
            XCTFail("Expected invalidResponse")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, .invalidResponse(provider: .deepL))
        }
    }

    func testTranslate_WithNonHTTPResponse_ThrowsInvalidResponse() async throws {
        let store = InMemoryDeepLCredentialStore(credentials: [.deepL: "key"])
        let session = throwingSession(URLError(.badServerResponse))
        let provider = DeepLTranslationProvider(endpoint: .free, credentialStore: store, session: session)

        do {
            _ = try await provider.translate(makeRequest())
            XCTFail("Expected providerUnavailable")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, .providerUnavailable(provider: .deepL, httpStatus: nil))
        }
    }

    func testTranslate_WithNonURLErrorTransportFailure_ThrowsProviderUnavailable() async throws {
        let store = InMemoryDeepLCredentialStore(credentials: [.deepL: "key"])
        let provider = DeepLTranslationProvider(endpoint: .free, credentialStore: store, session: nonURLErrorSession())

        do {
            _ = try await provider.translate(makeRequest())
            XCTFail("Expected providerUnavailable")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, .providerUnavailable(provider: .deepL, httpStatus: nil))
        }
    }

    // MARK: - Transport error mapping

    func testTranslate_WithNoConnection_ThrowsNetworkUnavailable() async throws {
        let store = InMemoryDeepLCredentialStore(credentials: [.deepL: "key"])
        let session = throwingSession(URLError(.notConnectedToInternet))
        let provider = DeepLTranslationProvider(endpoint: .free, credentialStore: store, session: session)

        do {
            _ = try await provider.translate(makeRequest())
            XCTFail("Expected networkUnavailable")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, .networkUnavailable)
        }
    }

    func testTranslate_WithTimeout_ThrowsRequestTimedOut() async throws {
        let store = InMemoryDeepLCredentialStore(credentials: [.deepL: "key"])
        let session = throwingSession(URLError(.timedOut))
        let provider = DeepLTranslationProvider(endpoint: .free, credentialStore: store, session: session)

        do {
            _ = try await provider.translate(makeRequest())
            XCTFail("Expected requestTimedOut")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, .requestTimedOut)
        }
    }

    func testTranslate_WithCancellation_ThrowsCancelled() async throws {
        let store = InMemoryDeepLCredentialStore(credentials: [.deepL: "key"])
        let session = throwingSession(URLError(.cancelled))
        let provider = DeepLTranslationProvider(endpoint: .free, credentialStore: store, session: session)

        do {
            _ = try await provider.translate(makeRequest())
            XCTFail("Expected cancelled")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, .cancelled)
        }
    }

    func testTranslate_WithUnrecognizedURLError_ThrowsProviderUnavailable() async throws {
        let store = InMemoryDeepLCredentialStore(credentials: [.deepL: "key"])
        let session = throwingSession(URLError(.unknown))
        let provider = DeepLTranslationProvider(endpoint: .free, credentialStore: store, session: session)

        do {
            _ = try await provider.translate(makeRequest())
            XCTFail("Expected providerUnavailable")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, .providerUnavailable(provider: .deepL, httpStatus: nil))
        }
    }

    // MARK: - Redaction

    func testTranslate_NeverLeaksCredentialOrSourceTextInThrownError() async throws {
        let store = InMemoryDeepLCredentialStore(credentials: [.deepL: "super-secret-key"])
        let provider = DeepLTranslationProvider(endpoint: .free, credentialStore: store, session: mockSession())
        MockDeepLURLProtocol.requestHandler = { [self] request in
            try jsonResponse(url: request.url!, status: 403, body: ["message": "Forbidden"])
        }

        do {
            _ = try await provider.translate(makeRequest(sourceText: "very secret source text"))
            XCTFail("Expected missingCredentials")
        } catch let error as EasyEngineCore.TranslationError {
            let description = String(describing: error)
            XCTAssertFalse(description.contains("super-secret-key"))
            XCTAssertFalse(description.contains("very secret source text"))
        }
    }
}
