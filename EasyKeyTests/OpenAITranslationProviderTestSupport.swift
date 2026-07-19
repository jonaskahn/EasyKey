import EasyEngineCore
@testable import EasyKey
import XCTest

final class MockOpenAIURLProtocol: URLProtocol {
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

struct OpenAINonURLTransportError: Error {}

extension XCTestCase {
    func openAIMockSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockOpenAIURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    func openAIJSONResponse(
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

    func openAISuccessBody(text: String = "xin chào") throws -> [String: Any] {
        let result = try JSONSerialization.data(withJSONObject: ["translation": text])
        let encodedResult = try XCTUnwrap(String(data: result, encoding: .utf8))
        return [
            "status": "completed",
            "output": [
                [
                    "type": "message",
                    "role": "assistant",
                    "content": [["type": "output_text", "text": encodedResult]],
                ],
            ],
        ]
    }
}
