import CoreGraphics
@testable import EasyKeyKit
import XCTest

@MainActor
final class KeyboardTapIsolationTests: XCTestCase {
    func testKeyboardEventTapCallback_RunsOnMainThread() {
        let settings = EasyKeySettings()
        let service = KeyboardService(settings: settings)
        let unmanagedService = Unmanaged.passUnretained(service)
        let opaquePointer = unmanagedService.toOpaque()

        let source = CGEventSource(stateID: .privateState)
        guard let event = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) else {
            XCTFail("Failed to create CGEvent")
            return
        }

        let result = keyboardEventTapCallback(
            proxy: nil as CGEventTapProxy?,
            type: .keyDown,
            event: event,
            userInfo: opaquePointer
        )

        XCTAssertNotNil(result)
    }
}
