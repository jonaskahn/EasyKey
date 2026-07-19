import EasyEngineCore
@testable import EasyKey
import XCTest

final class MockDeepLURLProtocol: URLProtocol {
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

final class ThrowingURLProtocol: URLProtocol {
    static var error: URLError = .init(.notConnectedToInternet)

    override static func canInit(with _: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        client?.urlProtocol(self, didFailWithError: Self.error)
    }

    override func stopLoading() {}
}

struct NonURLTransportError: Error {}

final class NonURLErrorProtocol: URLProtocol {
    override static func canInit(with _: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        client?.urlProtocol(self, didFailWithError: NonURLTransportError())
    }

    override func stopLoading() {}
}

final class ThrowingCredentialStore: TranslationCredentialStoring {
    func hasCredential(for _: TranslationProviderID) throws -> Bool {
        true
    }

    func credential(for _: TranslationProviderID) throws -> String? {
        throw TranslationCredentialError.unexpectedStatus(-1)
    }

    func save(_: String, for _: TranslationProviderID) throws {}
    func deleteCredential(for _: TranslationProviderID) throws {}
}

final class InMemoryDeepLCredentialStore: TranslationCredentialStoring, @unchecked Sendable {
    private var credentials: [TranslationProviderID: String]

    init(credentials: [TranslationProviderID: String] = [:]) {
        self.credentials = credentials
    }

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

extension URLRequest {
    func httpBodyStreamData() -> Data? {
        guard let stream = httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var data = Data()
        let bufferSize = 4096
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        while stream.hasBytesAvailable {
            let read = stream.read(&buffer, maxLength: bufferSize)
            if read > 0 {
                data.append(buffer, count: read)
            } else {
                break
            }
        }
        return data.isEmpty ? nil : data
    }
}
