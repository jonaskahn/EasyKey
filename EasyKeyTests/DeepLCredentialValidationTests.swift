import EasyEngineCore
@testable import EasyKey
import XCTest

final class DeepLCredentialValidationTests: XCTestCase {
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

    private func jsonResponse(url: URL, status: Int, body: [String: Any]) throws -> (Data, HTTPURLResponse) {
        let data = try JSONSerialization.data(withJSONObject: body)
        let response = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil))
        return (data, response)
    }

    func testValidateCredential_WithValidKey_UsesUsageEndpointAndReturnsTrue() async throws {
        let store = InMemoryDeepLCredentialStore()
        let provider = DeepLTranslationProvider(endpoint: .free, credentialStore: store, session: mockSession())
        MockDeepLURLProtocol.requestHandler = { [self] request in
            try jsonResponse(url: request.url!, status: 200, body: ["character_count": 100, "character_limit": 500_000])
        }

        let isValid = try await provider.validateCredential("candidate-key")

        XCTAssertTrue(isValid)
        let sent = try XCTUnwrap(MockDeepLURLProtocol.capturedRequests.first)
        XCTAssertEqual(sent.url?.path, "/v2/usage")
        XCTAssertEqual(sent.httpMethod, "GET")
        XCTAssertEqual(sent.value(forHTTPHeaderField: "Authorization"), "DeepL-Auth-Key candidate-key")
    }

    func testValidateCredential_WithInvalidKey_ReturnsFalse() async throws {
        let store = InMemoryDeepLCredentialStore()
        let provider = DeepLTranslationProvider(endpoint: .free, credentialStore: store, session: mockSession())
        MockDeepLURLProtocol.requestHandler = { [self] request in
            try jsonResponse(url: request.url!, status: 403, body: ["message": "Forbidden"])
        }

        let isValid = try await provider.validateCredential("bad-key")

        XCTAssertFalse(isValid)
    }

    func testValidateCredential_WithBlankKey_ReturnsFalseWithoutNetworkCall() async throws {
        let store = InMemoryDeepLCredentialStore()
        let provider = DeepLTranslationProvider(endpoint: .free, credentialStore: store, session: mockSession())

        let isValid = try await provider.validateCredential("   ")

        XCTAssertFalse(isValid)
        XCTAssertTrue(MockDeepLURLProtocol.capturedRequests.isEmpty)
    }

    func testValidateCredential_WithServerError_Throws() async throws {
        let store = InMemoryDeepLCredentialStore()
        let provider = DeepLTranslationProvider(endpoint: .free, credentialStore: store, session: mockSession())
        MockDeepLURLProtocol.requestHandler = { [self] request in
            try jsonResponse(url: request.url!, status: 500, body: ["message": "error"])
        }

        do {
            _ = try await provider.validateCredential("key")
            XCTFail("Expected providerUnavailable")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, .providerUnavailable(provider: .deepL, httpStatus: 500))
        }
    }

    func testValidateCredential_UsesProUsageHostWhenProEndpointSelected() async throws {
        let store = InMemoryDeepLCredentialStore()
        let provider = DeepLTranslationProvider(endpoint: .pro, credentialStore: store, session: mockSession())
        MockDeepLURLProtocol.requestHandler = { [self] request in
            try jsonResponse(url: request.url!, status: 200, body: ["character_count": 1, "character_limit": 2])
        }

        _ = try await provider.validateCredential("key")

        XCTAssertEqual(MockDeepLURLProtocol.capturedRequests.first?.url?.host, "api.deepl.com")
    }

    func testValidateCredential_WithNonHTTPURLResponse_ThrowsInvalidResponse() async throws {
        let store = InMemoryDeepLCredentialStore()
        let provider = DeepLTranslationProvider(endpoint: .free, credentialStore: store, session: mockSession())
        MockDeepLURLProtocol.requestHandler = { request in
            (Data(), URLResponse(url: request.url!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil))
        }

        do {
            _ = try await provider.validateCredential("key")
            XCTFail("Expected invalidResponse")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, .invalidResponse(provider: .deepL))
        }
    }
}
