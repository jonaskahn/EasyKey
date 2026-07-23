@testable import EasyKeyKit
import EasyEngineCore
import XCTest

final class KeyboardInputPipelineAppSwitchTests: XCTestCase {
    func testIsComposing_WhenEngineIsNotEmpty_ReturnsTrue() {
        let settings = EasyKeySettings()
        let pipeline = KeyboardInputPipeline(settings: settings)
        
        XCTAssertFalse(pipeline.isComposing)
        
        // Simulating character process that starts composition
        let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)!
        _ = pipeline.process(event: event, type: .keyDown, keyCode: 0, proxy: nil)
        
        XCTAssertTrue(pipeline.isComposing)
    }
}
