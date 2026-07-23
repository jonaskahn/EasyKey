import CoreGraphics
@testable import EasyKeyKit
import XCTest

@MainActor
final class KeyboardServiceLatencyTests: XCTestCase {
    func testKeyboardEventProcessing_DoesNotBlockMainThread() {
        let settings = EasyKeySettings()
        let service = KeyboardService(settings: settings)

        let source = CGEventSource(stateID: .privateState)
        guard let event = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) else {
            XCTFail("Failed to create CGEvent")
            return
        }

        let start = DispatchTime.now().uptimeNanoseconds
        for _ in 0 ..< 500 {
            _ = service.handleTapEvent(proxy: nil, type: .keyDown, event: event)
        }
        let elapsed = DispatchTime.now().uptimeNanoseconds - start

        // 500 events should process rapidly without blocking the main loop
        XCTAssertLessThan(elapsed, 1_000_000_000, "500 events should execute in under 1 second")
    }
}
