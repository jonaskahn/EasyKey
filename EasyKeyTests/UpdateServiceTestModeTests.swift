@testable import EasyKey
import XCTest

@MainActor
final class UpdateServiceTestModeTests: XCTestCase {
    func testUpdateService_InTestMode_IsDisabled() {
        let service = UpdateService(isUITesting: true)
        XCTAssertFalse(service.isConfigured, "UpdateService must not configure Sparkle during testing")
    }
}
