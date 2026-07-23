import EasyEngineCore
@testable import EasyKeyKit
import XCTest

final class KeyboardInputPipelineLanguageToggleTests: XCTestCase {
    func testToggleLanguage_DoesNotMutateSettingsLocally_EmitsToggleRequest() throws {
        var settings = EasyKeySettings()
        settings.input.language = .vietnamese
        let pipeline = KeyboardInputPipeline(settings: settings)

        let expectation = expectation(description: "Language toggle request emitted")
        var requestedLanguage: InputLanguage?

        pipeline.onLanguageToggleRequested = { lang in
            requestedLanguage = lang
            expectation.fulfill()
        }

        // Trigger language toggle via shortcut or internal call
        let event = try XCTUnwrap(CGEvent(keyboardEventSource: nil, virtualKey: 49, keyDown: true)) // space or shortcut
        event.flags = [.maskControl, .maskOption]
        _ = pipeline.process(event: event, type: .keyDown, keyCode: 49, proxy: nil)

        waitForExpectations(timeout: 1.0)

        XCTAssertEqual(requestedLanguage, .english)
        XCTAssertEqual(
            pipeline.currentSettings.input.language,
            .vietnamese,
            "Pipeline local settings should remain unchanged until canonical update flows back"
        )
    }
}
