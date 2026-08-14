import CoreGraphics
import EasyEngineCore
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

        let proxy = unsafeBitCast(UInt(0), to: CGEventTapProxy.self)
        let start = DispatchTime.now().uptimeNanoseconds
        for _ in 0 ..< 500 {
            _ = service.handleTapEvent(proxy: proxy, type: .keyDown, event: event)
        }
        let elapsed = DispatchTime.now().uptimeNanoseconds - start

        // 500 events should process rapidly without blocking the main loop. The
        // budget must absorb shared CI runner variance (measured 1.1-1.6s there
        // vs ~0.4s locally): the assertion is "not pathological", not a benchmark.
        XCTAssertLessThan(elapsed, 5_000_000_000, "500 events should execute in under 5 seconds")
    }
}
