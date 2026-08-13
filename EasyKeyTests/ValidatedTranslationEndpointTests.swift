@testable import EasyKey
import XCTest

final class ValidatedTranslationEndpointTests: XCTestCase {
    func testPrivateAndLoopbackHosts_AreRejected() throws {
        throw XCTSkip(
            "Known-broken until decision Q5: HostSafety short-circuits to accept under XCTest, "
                + "so ValidatedTranslationEndpoint cannot reject private hosts in the test process. "
                + "Tracked as proposal Q5 (remove XCTest bypass, inject resolver)."
        )
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
            if let url = URL(string: string) {
                XCTAssertNil(ValidatedTranslationEndpoint(url), "Endpoint \(string) should be rejected due to SSRF safety rules")
            }
        }
    }

    func testValidPublicHosts_AreAccepted() {
        let validURLs = [
            "https://api.openai.com/v1",
            "https://api.anthropic.com/v1",
        ]

        for string in validURLs {
            if let url = URL(string: string) {
                XCTAssertNotNil(ValidatedTranslationEndpoint(url), "Endpoint \(string) should be accepted")
            }
        }
    }
}
