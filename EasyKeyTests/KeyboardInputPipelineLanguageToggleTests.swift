import CoreGraphics
import EasyEngineCore
@testable import EasyKeyKit
import XCTest

final class KeyboardInputPipelineLanguageToggleTests: XCTestCase {
    func testToggleLanguage_DoesNotMutateSettingsLocally_EmitsToggleRequest() throws {
        var settings = EasyKeySettings()
        settings.input.language = .vietnamese
        settings.input.switchShortcut = Shortcut(keyCode: 49, modifiers: [.control, .option])
        let pipeline = KeyboardInputPipeline(settings: settings)

        let expectation = expectation(description: "Language toggle request emitted")
        var requestedLanguage: InputLanguage?

        pipeline.onLanguageToggleRequested = { lang in
            requestedLanguage = lang
            expectation.fulfill()
        }

        // Trigger language toggle via shortcut
        let event = try XCTUnwrap(CGEvent(keyboardEventSource: nil, virtualKey: 49, keyDown: true)) // space or shortcut
        event.flags = [.maskControl, .maskAlternate]
        let proxy = unsafeBitCast(UInt(0), to: CGEventTapProxy.self)
        _ = pipeline.process(proxy: proxy, type: .keyDown, event: event, keyCode: 49)

        waitForExpectations(timeout: 1.0)

        XCTAssertEqual(requestedLanguage, .english)
        XCTAssertEqual(
            pipeline.currentSettings.input.language,
            .vietnamese,
            "Pipeline local settings should remain unchanged until canonical update flows back"
        )
    }
}
