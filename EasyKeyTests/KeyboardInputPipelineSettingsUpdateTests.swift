@testable import EasyKeyKit
import EasyEngineCore
import CoreGraphics
import XCTest

final class KeyboardInputPipelineSettingsUpdateTests: XCTestCase {
    func testUpdateSettings_UnrelatedSetting_DoesNotResetEngine() {
        var settings = EasyKeySettings()
        let pipeline = KeyboardInputPipeline(settings: settings)
        
        let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)!
        _ = pipeline.process(event: event, type: .keyDown, keyCode: 0, proxy: nil)
        
        XCTAssertTrue(pipeline.isComposing)
        
        // Mutate unrelated setting
        settings.system.showDockIcon.toggle()
        pipeline.update(settings: settings)
        
        XCTAssertTrue(pipeline.isComposing, "Engine state should be preserved when updating unrelated settings")
    }

    func testUpdateSettings_EngineRelatedSetting_ResetsEngine() {
        var settings = EasyKeySettings()
        settings.input.inputMethod = .telex
        let pipeline = KeyboardInputPipeline(settings: settings)
        
        let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)!
        _ = pipeline.process(event: event, type: .keyDown, keyCode: 0, proxy: nil)
        
        XCTAssertTrue(pipeline.isComposing)
        
        // Mutate input method setting (affects EngineConfiguration)
        settings.input.inputMethod = .vni
        pipeline.update(settings: settings)
        
        XCTAssertFalse(pipeline.isComposing, "Engine state should be reset when input method changes")
    }
}
