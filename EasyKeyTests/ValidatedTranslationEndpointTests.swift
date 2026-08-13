@testable import EasyKey
import XCTest

final class ValidatedTranslationEndpointTests: XCTestCase {
    func testPrivateAndLoopbackHosts_AreRejected() async throws {
        let invalidURLs = [
            "https://127.0.0.1/v1",
            "https://192.168.1.1/v1",
            "https://10.0.0.1/v1",
            "https://169.254.169.254/latest/meta-data",
            "https://[::1]/v1",
            "https://something.local/v1",
            "https://localhost/v1",
        ]

        for string in invalidURLs {
            let endpoint = try XCTUnwrap(
                ValidatedTranslationEndpoint(string),
                "Endpoint \(string) should still pass syntax validation"
            )
            let safe = await endpoint.validateHostSafety()
            XCTAssertFalse(safe, "Endpoint \(string) should be rejected due to SSRF safety rules")
        }
    }

    func testValidPublicHosts_AreAcceptedWithInjectedResolver() async throws {
        let publicResolver = HostResolver { _ in
            [ResolvedHostAddress(family: .ipv4, bytes: [8, 8, 8, 8])]
        }

        for string in ["https://api.openai.com/v1", "https://api.anthropic.com/v1"] {
            let endpoint = try XCTUnwrap(ValidatedTranslationEndpoint(string))
            let safe = await endpoint.validateHostSafety(resolver: publicResolver)
            XCTAssertTrue(safe, "Endpoint \(string) should be accepted")
        }
    }

    func testPrivateHostRejectedWithInjectedResolver() async throws {
        let privateResolver = HostResolver { _ in
            [ResolvedHostAddress(family: .ipv4, bytes: [10, 0, 0, 1])]
        }
        let endpoint = try XCTUnwrap(ValidatedTranslationEndpoint("https://internal.example.com/v1"))
        let safe = await endpoint.validateHostSafety(resolver: privateResolver)
        XCTAssertFalse(safe)
    }
}
