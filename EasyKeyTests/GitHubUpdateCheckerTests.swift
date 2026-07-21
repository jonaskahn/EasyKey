@testable import EasyKey
import XCTest

@MainActor
final class GitHubUpdateCheckerTests: XCTestCase {
    func testVersionComparison_NewerVersion_ReturnsTrue() {
        let checker = GitHubUpdateChecker()
        XCTAssertTrue(checker.isNewerVersion("0.0.5", than: "0.0.4"))
        XCTAssertTrue(checker.isNewerVersion("1.0.0", than: "0.9.9"))
        XCTAssertTrue(checker.isNewerVersion("0.1.0", than: "0.0.9"))
        XCTAssertTrue(checker.isNewerVersion("2.0.0", than: "1.9.9"))
    }

    func testVersionComparison_SameVersion_ReturnsFalse() {
        let checker = GitHubUpdateChecker()
        XCTAssertFalse(checker.isNewerVersion("0.0.4", than: "0.0.4"))
        XCTAssertFalse(checker.isNewerVersion("1.0.0", than: "1.0.0"))
    }

    func testVersionComparison_OlderVersion_ReturnsFalse() {
        let checker = GitHubUpdateChecker()
        XCTAssertFalse(checker.isNewerVersion("0.0.4", than: "0.0.5"))
        XCTAssertFalse(checker.isNewerVersion("0.9.9", than: "1.0.0"))
    }

    func testVersionComparison_DifferentLengths() {
        let checker = GitHubUpdateChecker()
        XCTAssertTrue(checker.isNewerVersion("1.0.0.1", than: "1.0.0"))
        XCTAssertTrue(checker.isNewerVersion("1.0.1", than: "1.0"))
        XCTAssertFalse(checker.isNewerVersion("1.0", than: "1.0.0"))
    }

    func testIsTrustedDownloadURL_AcceptsOfficialReleaseLinks() {
        XCTAssertTrue(
            GitHubUpdateChecker.isTrustedDownloadURL(
                "https://github.com/jonaskahn/EasyKey/releases/tag/v0.0.2"
            )
        )
    }

    func testIsTrustedDownloadURL_RejectsUntrustedHostsAndSchemes() {
        XCTAssertFalse(GitHubUpdateChecker.isTrustedDownloadURL("http://github.com/jonaskahn/EasyKey/releases"))
        XCTAssertFalse(GitHubUpdateChecker.isTrustedDownloadURL("https://evil.example/jonaskahn/EasyKey"))
        XCTAssertFalse(GitHubUpdateChecker.isTrustedDownloadURL("https://github.com/other/repo/releases"))
        XCTAssertFalse(GitHubUpdateChecker.isTrustedDownloadURL("not a url"))
    }

    func testCheckForUpdates_NonHTTPSRepository_Fails() async throws {
        let checker = try GitHubUpdateChecker(
            repositoryURL: XCTUnwrap(URL(string: "http://example.com/releases/latest")),
            session: URLSession(configuration: .ephemeral)
        )
        let result = await checker.checkForUpdates()
        guard case .failure = result else {
            return XCTFail("Expected failure for non-HTTPS repository URL")
        }
    }

    func testCheckForUpdates_HTTPErrorStatus_Fails() async throws {
        MockUpdateURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.github.com/repos/jonaskahn/EasyKey/releases/latest")!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (Data(), response)
        }
        let checker = try GitHubUpdateChecker(
            repositoryURL: XCTUnwrap(URL(string: "https://api.github.com/repos/jonaskahn/EasyKey/releases/latest")),
            session: Self.mockSession()
        )
        let result = await checker.checkForUpdates()
        guard case .failure = result else {
            return XCTFail("Expected failure for HTTP 500")
        }
    }

    func testCheckForUpdates_UntrustedDownloadURL_Fails() async throws {
        let payload = Data("""
        {"tag_name":"v9.9.9","name":"Huge","html_url":"https://evil.example/download","published_at":"2026-01-01T00:00:00Z"}
        """.utf8)
        MockUpdateURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.github.com/repos/jonaskahn/EasyKey/releases/latest")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (payload, response)
        }
        let checker = try GitHubUpdateChecker(
            repositoryURL: XCTUnwrap(URL(string: "https://api.github.com/repos/jonaskahn/EasyKey/releases/latest")),
            session: Self.mockSession()
        )
        let result = await checker.checkForUpdates()
        guard case .failure = result else {
            return XCTFail("Expected failure for untrusted download URL")
        }
    }

    func testCheckForUpdates_TrustedNewerRelease_ReturnsUpdateAvailable() async throws {
        let payload = Data("""
        {"tag_name":"v99.0.0","name":"Future","html_url":"https://github.com/jonaskahn/EasyKey/releases/tag/v99.0.0","published_at":"2026-01-01T00:00:00Z"}
        """.utf8)
        MockUpdateURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.github.com/repos/jonaskahn/EasyKey/releases/latest")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (payload, response)
        }
        let checker = try GitHubUpdateChecker(
            repositoryURL: XCTUnwrap(URL(string: "https://api.github.com/repos/jonaskahn/EasyKey/releases/latest")),
            session: Self.mockSession()
        )
        let result = await checker.checkForUpdates()
        guard case let .updateAvailable(_, latest, _, url) = result else {
            return XCTFail("Expected updateAvailable")
        }
        XCTAssertEqual(latest, "99.0.0")
        XCTAssertTrue(GitHubUpdateChecker.isTrustedDownloadURL(url))
    }

    func testGitHubRelease_VersionStripsLeadingV() throws {
        let json = Data("""
        {"tag_name":"v1.2.3","html_url":"https://github.com/jonaskahn/EasyKey/releases/tag/v1.2.3"}
        """.utf8)
        let release = try JSONDecoder().decode(GitHubRelease.self, from: json)
        XCTAssertEqual(release.version, "1.2.3")
    }

    func testInit_WithoutRepositoryURL_ConstructsDefaultURL() {
        let checker = GitHubUpdateChecker()
        _ = checker
    }

    func testCheckForUpdates_UpToDateVersion_ReturnsUpToDate() async throws {
        let payload = Data("""
        {"tag_name":"v0.0.1","name":"Old","html_url":"https://github.com/jonaskahn/EasyKey/releases/tag/v0.0.1","published_at":"2024-01-01T00:00:00Z"}
        """.utf8)
        MockUpdateURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.github.com/repos/jonaskahn/EasyKey/releases/latest")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (payload, response)
        }
        let checker = try GitHubUpdateChecker(
            repositoryURL: XCTUnwrap(URL(string: "https://api.github.com/repos/jonaskahn/EasyKey/releases/latest")),
            session: Self.mockSession()
        )
        let result = await checker.checkForUpdates()
        guard case let .upToDate(current) = result else {
            return XCTFail("Expected upToDate, got \(result)")
        }
        XCTAssertFalse(current.isEmpty)
    }

    func testCheckForUpdates_ResponseExceedsSizeCap_Fails() async throws {
        let oversized = Data(count: 1_048_577)
        MockUpdateURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.github.com/repos/jonaskahn/EasyKey/releases/latest")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (oversized, response)
        }
        let checker = try GitHubUpdateChecker(
            repositoryURL: XCTUnwrap(URL(string: "https://api.github.com/repos/jonaskahn/EasyKey/releases/latest")),
            session: Self.mockSession()
        )
        let result = await checker.checkForUpdates()
        guard case .failure = result else {
            return XCTFail("Expected failure for oversized payload")
        }
    }

    func testCheckForUpdates_NonHTTPResponse_Fails() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [NonHTTPResponseURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let checker = try GitHubUpdateChecker(
            repositoryURL: XCTUnwrap(URL(string: "https://api.github.com/repos/jonaskahn/EasyKey/releases/latest")),
            session: session
        )
        let result = await checker.checkForUpdates()
        guard case .failure = result else {
            return XCTFail("Expected failure for non-HTTP response")
        }
    }

    func testCheckForUpdates_TransportError_Fails() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [FailingURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let checker = try GitHubUpdateChecker(
            repositoryURL: XCTUnwrap(URL(string: "https://api.github.com/repos/jonaskahn/EasyKey/releases/latest")),
            session: session
        )
        let result = await checker.checkForUpdates()
        guard case .failure = result else {
            return XCTFail("Expected failure for transport error")
        }
    }

    func testCheckForUpdates_MalformedJSON_Fails() async throws {
        let payload = Data("not json".utf8)
        MockUpdateURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.github.com/repos/jonaskahn/EasyKey/releases/latest")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (payload, response)
        }
        let checker = try GitHubUpdateChecker(
            repositoryURL: XCTUnwrap(URL(string: "https://api.github.com/repos/jonaskahn/EasyKey/releases/latest")),
            session: Self.mockSession()
        )
        let result = await checker.checkForUpdates()
        guard case .failure = result else {
            return XCTFail("Expected failure for malformed JSON")
        }
    }

    private static func mockSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockUpdateURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

private final class MockUpdateURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (Data, HTTPURLResponse))?

    override static func canInit(with _: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
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

private final class NonHTTPResponseURLProtocol: URLProtocol {
    override static func canInit(with _: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let response = URLResponse(
            url: request.url!,
            mimeType: "application/json",
            expectedContentLength: 0,
            textEncodingName: nil
        )
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data())
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private final class FailingURLProtocol: URLProtocol {
    override static func canInit(with _: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
    }

    override func stopLoading() {}
}
