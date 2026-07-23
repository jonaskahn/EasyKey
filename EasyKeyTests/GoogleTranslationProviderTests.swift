import EasyEngineCore
@testable import EasyKey
import XCTest

final class GoogleTranslationProviderTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MockGoogleURLProtocol.requestHandler = nil
        MockGoogleURLProtocol.capturedRequests = []
    }

    private func makeProvider(
        apiKey: String = "fixture-api-key",
        session: URLSession? = nil
    ) -> GoogleTranslationProvider {
        let store = InMemoryTranslationCredentialStore(credentials: [.google: apiKey])
        return GoogleTranslationProvider(credentialStore: store, session: session ?? googleMockSession())
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
            providerID: .google
        ))
    }

    private func installSuccess(
        text: String = "xin chào",
        detectedSourceLanguage: String? = "en"
    ) {
        MockGoogleURLProtocol.requestHandler = { [self] request in
            try googleJSONResponse(
                url: XCTUnwrap(request.url),
                status: 200,
                body: googleTranslationBody(text: text, detectedSourceLanguage: detectedSourceLanguage)
            )
        }
    }

    func testTranslate_UsesFixedHTTPSV2EndpointAndHeaderCredential() async throws {
        let provider = makeProvider()
        installSuccess()

        _ = try await provider.translate(makeRequest())

        let sent = try XCTUnwrap(MockGoogleURLProtocol.capturedRequests.first)
        XCTAssertEqual(sent.url?.scheme, "https")
        XCTAssertEqual(sent.url?.host, "translation.googleapis.com")
        XCTAssertEqual(sent.url?.path, "/language/translate/v2")
        XCTAssertNil(try URLComponents(url: XCTUnwrap(sent.url), resolvingAgainstBaseURL: false)?.queryItems?
            .first(where: { $0.name == "key" }))
        XCTAssertEqual(sent.value(forHTTPHeaderField: "x-goog-api-key"), "fixture-api-key")
        XCTAssertNil(sent.value(forHTTPHeaderField: "Authorization"))
        XCTAssertEqual(sent.httpMethod, "POST")
        XCTAssertEqual(sent.timeoutInterval, 20)
    }

    func testTranslate_ExplicitSourceSendsOneScalarQueryAndMappedLanguages() async throws {
        let provider = makeProvider()
        installSuccess()
        let regionalEnglish = try XCTUnwrap(TranslationLanguage(bcp47: "EN-US"))
        let regionalVietnamese = try XCTUnwrap(TranslationLanguage(bcp47: "VI"))

        _ = try await provider.translate(makeRequest(
            sourceText: "hello world",
            sourceLanguage: regionalEnglish,
            targetLanguage: regionalVietnamese
        ))

        let sent = try XCTUnwrap(MockGoogleURLProtocol.capturedRequests.first)
        XCTAssertEqual(sent.value(forHTTPHeaderField: "Content-Type"), "application/json; charset=utf-8")
        let body = try XCTUnwrap(sent.httpBodyStreamData() ?? sent.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["q"] as? String, "hello world")
        XCTAssertFalse(json["q"] is [String], "Adapter must submit exactly one query")
        XCTAssertEqual(json["source"] as? String, "en-us")
        XCTAssertEqual(json["target"] as? String, "vi")
        XCTAssertEqual(json["format"] as? String, "html")
    }

    func testTranslate_AutoDetectOmitsSource() async throws {
        let provider = makeProvider()
        installSuccess()

        _ = try await provider.translate(makeRequest(sourceLanguage: nil))

        let sent = try XCTUnwrap(MockGoogleURLProtocol.capturedRequests.first)
        let body = try XCTUnwrap(sent.httpBodyStreamData() ?? sent.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertNil(json["source"])
    }

    func testTranslate_PerformsURLLoadingOffMainThread() async throws {
        let provider = makeProvider()
        MockGoogleURLProtocol.requestHandler = { [self] request in
            XCTAssertFalse(Thread.isMainThread)
            return try googleJSONResponse(url: XCTUnwrap(request.url), status: 200, body: googleTranslationBody())
        }

        _ = try await provider.translate(makeRequest())
    }

    func testTranslate_ReturnsSingleTranslationDetectedLanguageAndProvider() async throws {
        let provider = makeProvider()
        installSuccess(text: "xin chào", detectedSourceLanguage: "en")

        let response = try await provider.translate(makeRequest(sourceLanguage: nil))

        XCTAssertEqual(response.translatedText, "xin chào")
        XCTAssertEqual(response.detectedSourceLanguage?.identifier, "en")
        XCTAssertEqual(response.providerID, .google)
    }

    func testTranslate_ExplicitSourceResponseMayOmitDetectedLanguage() async throws {
        let provider = makeProvider()
        installSuccess(detectedSourceLanguage: nil)

        let response = try await provider.translate(makeRequest())

        XCTAssertNil(response.detectedSourceLanguage)
    }

    func testTranslate_DecodesHTMLAndNumericEntitiesWithoutChangingUnicode() async throws {
        let provider = makeProvider()
        installSuccess(text: "Tiếng Việt &amp; café &lt;3 &#39;ok&#39; &#x1F600; ©")

        let response = try await provider.translate(makeRequest())

        XCTAssertEqual(response.translatedText, "Tiếng Việt & café <3 'ok' 😀 ©")
    }

    func testTranslate_PreservesUnknownEntitiesAndDecodesOnlyOneLayer() async throws {
        let provider = makeProvider()
        installSuccess(text: "&unknown; &amp;lt; nguyên")

        let response = try await provider.translate(makeRequest())

        XCTAssertEqual(response.translatedText, "&unknown; &lt; nguyên")
    }

    func testTranslate_RejectsZeroTranslations() async throws {
        try await assertInvalidResponse(body: ["data": ["translations": []]])
    }

    func testTranslate_RejectsMultipleTranslations() async throws {
        try await assertInvalidResponse(body: [
            "data": [
                "translations": [
                    ["translatedText": "one"],
                    ["translatedText": "two"],
                ],
            ],
        ])
    }

    func testTranslate_RejectsBlankTranslation() async throws {
        try await assertInvalidResponse(body: googleTranslationBody(text: "  \n"))
    }

    func testTranslate_RejectsBlankDetectedLanguage() async throws {
        try await assertInvalidResponse(body: googleTranslationBody(detectedSourceLanguage: " "))
    }

    func testTranslate_RejectsMalformedJSON() async {
        let provider = makeProvider()
        MockGoogleURLProtocol.requestHandler = { request in
            let response = try XCTUnwrap(
                HTTPURLResponse(url: XCTUnwrap(request.url), statusCode: 200, httpVersion: nil, headerFields: nil)
            )
            return (Data("not-json".utf8), response)
        }

        await assertTranslationError(.invalidResponse(provider: .google)) {
            try await provider.translate(self.makeRequest())
        }
    }

    func testTranslate_RejectsOversizedResponseBeforeDecoding() async {
        let provider = makeProvider()
        MockGoogleURLProtocol.requestHandler = { request in
            let response = try XCTUnwrap(
                HTTPURLResponse(url: XCTUnwrap(request.url), statusCode: 200, httpVersion: nil, headerFields: nil)
            )
            return (Data(repeating: 0x41, count: 1_048_577), response)
        }

        await assertTranslationError(.invalidResponse(provider: .google)) {
            try await provider.translate(self.makeRequest())
        }
    }

    func testTranslate_RejectsNonHTTPResponse() async {
        let provider = makeProvider()
        MockGoogleURLProtocol.requestHandler = { request in
            try (Data(), URLResponse(url: XCTUnwrap(request.url), mimeType: nil, expectedContentLength: 0, textEncodingName: nil))
        }

        await assertTranslationError(.invalidResponse(provider: .google)) {
            try await provider.translate(self.makeRequest())
        }
    }

    private func assertInvalidResponse(body: [String: Any]) async throws {
        let provider = makeProvider()
        MockGoogleURLProtocol.requestHandler = { [self] request in
            try googleJSONResponse(url: XCTUnwrap(request.url), status: 200, body: body)
        }
        await assertTranslationError(.invalidResponse(provider: .google)) {
            try await provider.translate(self.makeRequest())
        }
    }

    func testTranslate_MissingCredentialDoesNotCallNetwork() async {
        let provider = GoogleTranslationProvider(
            credentialStore: InMemoryTranslationCredentialStore(),
            session: googleMockSession()
        )

        await assertTranslationError(.missingCredentials(provider: .google)) {
            try await provider.translate(self.makeRequest())
        }
        XCTAssertTrue(MockGoogleURLProtocol.capturedRequests.isEmpty)
    }

    func testTranslate_BlankCredentialDoesNotCallNetwork() async {
        let provider = makeProvider(apiKey: " \n ")

        await assertTranslationError(.missingCredentials(provider: .google)) {
            try await provider.translate(self.makeRequest())
        }
        XCTAssertTrue(MockGoogleURLProtocol.capturedRequests.isEmpty)
    }

    func testTranslate_CredentialReadFailurePreservesOperationalError() async {
        let provider = GoogleTranslationProvider(credentialStore: ThrowingCredentialStore(), session: googleMockSession())

        do {
            _ = try await provider.translate(makeRequest())
            XCTFail("Expected Keychain operational error")
        } catch let error as TranslationCredentialError {
            XCTAssertEqual(error, .unexpectedStatus(-1))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        XCTAssertTrue(MockGoogleURLProtocol.capturedRequests.isEmpty)
    }

    func testTranslate_MapsAuthenticationFailures() async throws {
        try await assertHTTPStatus(
            400,
            body: ["error": ["details": [["reason": "API_KEY_INVALID"]]]],
            mapsTo: .missingCredentials(provider: .google)
        )
        try await assertHTTPStatus(401, mapsTo: .missingCredentials(provider: .google))
        try await assertHTTPStatus(403, mapsTo: .missingCredentials(provider: .google))
    }

    func testTranslate_MapsQuotaAndRateFailures() async throws {
        try await assertHTTPStatus(
            403,
            body: ["error": ["errors": [["reason": "dailyLimitExceeded"]]]],
            mapsTo: .rateLimitExceeded(provider: .google)
        )
        try await assertHTTPStatus(429, mapsTo: .rateLimitExceeded(provider: .google))
    }

    func testTranslate_MapsSizeMalformedAndServerFailures() async throws {
        try await assertHTTPStatus(413, mapsTo: .requestTooLarge)
        try await assertHTTPStatus(414, mapsTo: .requestTooLarge)
        try await assertHTTPStatus(400, mapsTo: .providerUnavailable(provider: .google, httpStatus: 400))
        try await assertHTTPStatus(503, mapsTo: .providerUnavailable(provider: .google, httpStatus: 503))
    }

    private func assertHTTPStatus(
        _ status: Int,
        body: [String: Any] = ["error": ["message": "failure"]],
        mapsTo expected: EasyEngineCore.TranslationError
    ) async throws {
        let provider = makeProvider()
        MockGoogleURLProtocol.requestHandler = { [self] request in
            try googleJSONResponse(url: XCTUnwrap(request.url), status: status, body: body)
        }
        await assertTranslationError(expected) {
            try await provider.translate(self.makeRequest())
        }
    }

    func testTranslate_MapsTimeoutCancellationAndNetworkFailures() async throws {
        try await assertTransportError(URLError(.timedOut), mapsTo: .requestTimedOut)
        try await assertTransportError(URLError(.cancelled), mapsTo: .cancelled)
        try await assertTransportError(URLError(.notConnectedToInternet), mapsTo: .networkUnavailable)
        try await assertTransportError(URLError(.networkConnectionLost), mapsTo: .networkUnavailable)
    }

    func testTranslate_MapsUnknownTransportFailures() async throws {
        try await assertTransportError(
            URLError(.unknown),
            mapsTo: .providerUnavailable(provider: .google, httpStatus: nil)
        )
        try await assertTransportError(
            GoogleNonURLTransportError(),
            mapsTo: .providerUnavailable(provider: .google, httpStatus: nil)
        )
    }

    func testTranslate_ErrorNeverContainsKeySourceOrProviderResult() async throws {
        let provider = makeProvider(apiKey: "fixture-secret-key")
        MockGoogleURLProtocol.requestHandler = { [self] request in
            try googleJSONResponse(
                url: XCTUnwrap(request.url),
                status: 403,
                body: ["error": ["message": "fixture-provider-result"]]
            )
        }

        do {
            _ = try await provider.translate(makeRequest(sourceText: "fixture-private-source"))
            XCTFail("Expected missingCredentials")
        } catch {
            let description = String(describing: error)
            XCTAssertFalse(description.contains("fixture-secret-key"))
            XCTAssertFalse(description.contains("fixture-private-source"))
            XCTAssertFalse(description.contains("fixture-provider-result"))
        }
    }

    private func assertTransportError(
        _ transportError: Error,
        mapsTo expected: EasyEngineCore.TranslationError
    ) async throws {
        let provider = makeProvider()
        MockGoogleURLProtocol.requestHandler = { _ in throw transportError }
        await assertTranslationError(expected) {
            try await provider.translate(self.makeRequest())
        }
    }

    private func assertTranslationError(
        _ expected: EasyEngineCore.TranslationError,
        operation: () async throws -> TranslationResponse
    ) async {
        do {
            _ = try await operation()
            XCTFail("Expected \(expected)")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, expected)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
