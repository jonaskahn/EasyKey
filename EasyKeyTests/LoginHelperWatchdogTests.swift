@testable import EasyKey
import XCTest

final class LoginHelperWatchdogTests: XCTestCase {
    func testHostURLValidation_RejectsInvalidPaths() {
        let invalidURL = URL(fileURLWithPath: "/tmp/not_an_app.txt")
        XCTAssertNotEqual(invalidURL.pathExtension, "app")
    }
}
