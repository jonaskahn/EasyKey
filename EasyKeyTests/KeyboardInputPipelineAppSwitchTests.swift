import CoreGraphics
import EasyEngineCore
@testable import EasyKeyKit
import XCTest

final class KeyboardInputPipelineAppSwitchTests: XCTestCase {
    func testIsComposing_WhenEngineIsNotEmpty_ReturnsTrue() throws {
        let settings = EasyKeySettings()
        let pipeline = KeyboardInputPipeline(settings: settings)

        XCTAssertFalse(pipeline.isComposing)

        // Simulating character process that starts composition
        let event = try XCTUnwrap(CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true))
        let proxy = unsafeBitCast(UInt(0), to: CGEventTapProxy.self)
        _ = pipeline.process(proxy: proxy, type: .keyDown, event: event, keyCode: 0)

        XCTAssertTrue(pipeline.isComposing)
    }
}
