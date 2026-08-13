import CoreGraphics
import EasyEngineCore
@testable import EasyKeyKit
import XCTest

final class KeyboardInputPipelineSettingsUpdateTests: XCTestCase {
    func testUpdateSettings_UnrelatedSetting_DoesNotResetEngine() throws {
        var settings = EasyKeySettings()
        let pipeline = KeyboardInputPipeline(settings: settings)

        let event = try XCTUnwrap(CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true))
        let proxy = unsafeBitCast(UInt(0), to: CGEventTapProxy.self)
        _ = pipeline.process(proxy: proxy, type: .keyDown, event: event, keyCode: 0)

        XCTAssertTrue(pipeline.isComposing)

        // Mutate unrelated setting
        settings.system.showDockIcon.toggle()
        pipeline.update(settings: settings)

        XCTAssertTrue(pipeline.isComposing, "Engine state should be preserved when updating unrelated settings")
    }

    func testUpdateSettings_EngineRelatedSetting_ResetsEngine() throws {
        var settings = EasyKeySettings()
        settings.input.inputMethod = .telex
        let pipeline = KeyboardInputPipeline(settings: settings)

        let event = try XCTUnwrap(CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true))
        let proxy = unsafeBitCast(UInt(0), to: CGEventTapProxy.self)
        _ = pipeline.process(proxy: proxy, type: .keyDown, event: event, keyCode: 0)

        XCTAssertTrue(pipeline.isComposing)

        // Mutate input method setting (affects EngineConfiguration)
        settings.input.inputMethod = .vni
        pipeline.update(settings: settings)

        XCTAssertFalse(pipeline.isComposing, "Engine state should be reset when input method changes")
    }
}
