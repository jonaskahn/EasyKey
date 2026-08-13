@testable import EasyKeyKit
import XCTest

final class FocusedElementInspectorTests: XCTestCase {
    func testIsChromiumAddressBar_DoesNotCrash() {
        _ = FocusedElementInspector.isChromiumAddressBar()
    }

    func testIsChromiumAddressBar_CalledRepeatedly_IsStable() {
        let first = FocusedElementInspector.isChromiumAddressBar()
        let second = FocusedElementInspector.isChromiumAddressBar()
        XCTAssertEqual(first, second)
    }
}
