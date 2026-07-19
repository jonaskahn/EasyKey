import EasyEngineCore
@testable import EasyKey
import XCTest

final class MockAnthropicURLProtocol: URLProtocol {
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

struct AnthropicNonURLTransportError: Error {}

extension XCTestCase {
    func anthropicMockSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockAnthropicURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    func anthropicJSONResponse(
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

    func anthropicSuccessBody(text: String = "xin chào") -> [String: Any] {
        [
            "type": "message",
            "role": "assistant",
            "stop_reason": "end_turn",
            "content": [["type": "text", "text": "<translation>\(text)</translation>"]],
        ]
    }
}
