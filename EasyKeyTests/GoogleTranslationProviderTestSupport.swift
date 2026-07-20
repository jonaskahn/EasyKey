import EasyEngineCore
@testable import EasyKey
import XCTest

final class MockGoogleURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (Data, URLResponse))?
    static var capturedRequests: [URLRequest] = []

    override static func canInit(with _: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.capturedRequests.append(request)
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        do {
            let (data, response) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

struct GoogleNonURLTransportError: Error {}

extension XCTestCase {
    func googleMockSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockGoogleURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    func googleJSONResponse(
        url: URL,
        status: Int,
        body: [String: Any]
    ) throws -> (Data, HTTPURLResponse) {
        let data = try JSONSerialization.data(withJSONObject: body)
        let response = try XCTUnwrap(
            HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil)
        )
        return (data, response)
    }

    func googleTranslationBody(
        text: String = "xin chào",
        detectedSourceLanguage: String? = "en"
    ) -> [String: Any] {
        var translation: [String: Any] = ["translatedText": text]
        if let detectedSourceLanguage {
            translation["detectedSourceLanguage"] = detectedSourceLanguage
        }
        return ["data": ["translations": [translation]]]
    }
}
