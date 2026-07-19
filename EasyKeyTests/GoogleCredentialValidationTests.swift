import EasyEngineCore
@testable import EasyKey
import XCTest

final class GoogleCredentialValidationTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MockGoogleURLProtocol.requestHandler = nil
        MockGoogleURLProtocol.capturedRequests = []
    }

    private func makeProvider() -> GoogleTranslationProvider {
        GoogleTranslationProvider(
            credentialStore: InMemoryTranslationCredentialStore(),
            session: googleMockSession()
        )
    }

    func testValidateCredential_UsesNonBillableLanguagesEndpoint() async throws {
        let provider = makeProvider()
        MockGoogleURLProtocol.requestHandler = { [self] request in
            try googleJSONResponse(url: XCTUnwrap(request.url), status: 200, body: ["data": ["languages": []]])
        }

        let valid = try await provider.validateCredential(" candidate-key ")

        XCTAssertTrue(valid)
        let sent = try XCTUnwrap(MockGoogleURLProtocol.capturedRequests.first)
        XCTAssertEqual(sent.url?.scheme, "https")
        XCTAssertEqual(sent.url?.host, "translation.googleapis.com")
        XCTAssertEqual(sent.url?.path, "/language/translate/v2/languages")
        XCTAssertEqual(sent.httpMethod, "GET")
        XCTAssertNil(sent.httpBody)
        let queryItems = try URLComponents(url: XCTUnwrap(sent.url), resolvingAgainstBaseURL: false)?.queryItems
        XCTAssertEqual(queryItems, [
            URLQueryItem(name: "key", value: "candidate-key"),
            URLQueryItem(name: "target", value: "en"),
        ])
    }

    func testValidateCredential_BlankKeyReturnsFalseWithoutNetwork() async throws {
        let valid = try await makeProvider().validateCredential(" \n ")

        XCTAssertFalse(valid)
        XCTAssertTrue(MockGoogleURLProtocol.capturedRequests.isEmpty)
    }

    func testValidateCredential_AuthFailuresReturnFalse() async throws {
        for status in [400, 401, 403] {
            MockGoogleURLProtocol.requestHandler = { [self] request in
                try googleJSONResponse(url: XCTUnwrap(request.url), status: status, body: ["error": [:]])
            }
            let valid = try await makeProvider().validateCredential("bad-key")
            XCTAssertFalse(valid)
        }
    }

    func testValidateCredential_ServerAndRateFailuresAreNormalized() async throws {
        MockGoogleURLProtocol.requestHandler = { [self] request in
            try googleJSONResponse(
                url: XCTUnwrap(request.url),
                status: 403,
                body: ["error": ["errors": [["reason": "quotaExceeded"]]]]
            )
        }
        await assertValidationError(.rateLimitExceeded(provider: .google)) {
            try await self.makeProvider().validateCredential("key")
        }

        try await assertStatus(429, mapsTo: .rateLimitExceeded(provider: .google))
        try await assertStatus(500, mapsTo: .providerUnavailable(provider: .google, httpStatus: 500))
    }

    func testValidateCredential_RejectsNonHTTPAndOversizedResponses() async {
        let provider = makeProvider()
        MockGoogleURLProtocol.requestHandler = { request in
            try (Data(), URLResponse(url: XCTUnwrap(request.url), mimeType: nil, expectedContentLength: 0, textEncodingName: nil))
        }
        await assertValidationError(.invalidResponse(provider: .google)) {
            try await provider.validateCredential("key")
        }

        MockGoogleURLProtocol.requestHandler = { request in
            let response = try XCTUnwrap(
                HTTPURLResponse(url: XCTUnwrap(request.url), statusCode: 200, httpVersion: nil, headerFields: nil)
            )
            return (Data(repeating: 0x41, count: 1_048_577), response)
        }
        await assertValidationError(.invalidResponse(provider: .google)) {
            try await provider.validateCredential("key")
        }
    }

    func testValidateCredential_TransportFailureIsNormalizedAndRedacted() async {
        MockGoogleURLProtocol.requestHandler = { _ in throw URLError(.timedOut) }
        await assertValidationError(.requestTimedOut) {
            try await self.makeProvider().validateCredential("fixture-secret-key")
        }
    }

    private func assertStatus(
        _ status: Int,
        mapsTo expected: EasyEngineCore.TranslationError
    ) async throws {
        MockGoogleURLProtocol.requestHandler = { [self] request in
            try googleJSONResponse(url: XCTUnwrap(request.url), status: status, body: ["error": [:]])
        }
        await assertValidationError(expected) {
            try await self.makeProvider().validateCredential("key")
        }
    }

    private func assertValidationError(
        _ expected: EasyEngineCore.TranslationError,
        operation: () async throws -> Bool
    ) async {
        do {
            _ = try await operation()
            XCTFail("Expected \(expected)")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, expected)
            XCTAssertFalse(String(describing: error).contains("fixture-secret-key"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
