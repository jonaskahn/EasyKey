import EasyEngineCore
@testable import EasyKeyKit
import XCTest

@MainActor
final class AccessibilityRePromptTests: XCTestCase {
    func testRequestAccessibilityPermission_CanBeCalledMultipleTimes() {
        let settings = EasyKeySettings()
        let service = KeyboardService(settings: settings)

        service.requestAccessibilityPermission()
        XCTAssertEqual(service.health, .requestingPermission)

        service.requestAccessibilityPermission()
        XCTAssertEqual(service.health, .requestingPermission)
    }
}
