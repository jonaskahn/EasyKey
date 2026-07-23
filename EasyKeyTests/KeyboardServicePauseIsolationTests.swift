@testable import EasyKeyKit
import XCTest

@MainActor
final class KeyboardServicePauseIsolationTests: XCTestCase {
    func testSetPaused_InvokesPauseHandlerOnMainThread() {
        let settings = EasyKeySettings()
        let service = KeyboardService(settings: settings)

        var invoked = false
        var isMain = false
        service.pauseHandler = { _ in
            invoked = true
            isMain = Thread.isMainThread
        }

        service.setPaused(true)

        XCTAssertTrue(invoked)
        XCTAssertTrue(isMain, "Pause handler must be invoked on the main thread")
    }
}
