import CoreGraphics
@testable import EasyEngineCore
@testable import EasyKeyKit
import XCTest

final class KeyboardInputPipelineStaticTests: XCTestCase {
    func testMakeEventMask() {
        let mask = KeyboardInputPipeline.makeEventMask()
        XCTAssertNotEqual(mask, 0)
    }

    func testIsMouseEventKeyDown() {
        XCTAssertFalse(KeyboardInputPipeline.isMouseEvent(.keyDown))
    }

    func testIsMouseEventMouseDown() {
        XCTAssertTrue(KeyboardInputPipeline.isMouseEvent(.leftMouseDown))
        XCTAssertTrue(KeyboardInputPipeline.isMouseEvent(.rightMouseDown))
        XCTAssertTrue(KeyboardInputPipeline.isMouseEvent(.otherMouseDown))
    }

    func testIsMouseEventMouseDragged() {
        XCTAssertTrue(KeyboardInputPipeline.isMouseEvent(.leftMouseDragged))
        XCTAssertTrue(KeyboardInputPipeline.isMouseEvent(.rightMouseDragged))
        XCTAssertTrue(KeyboardInputPipeline.isMouseEvent(.otherMouseDragged))
    }

    func testIsMouseEventFlagsChanged() {
        XCTAssertFalse(KeyboardInputPipeline.isMouseEvent(.flagsChanged))
    }

    func testModifiersFromEvent() {
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) else {
            XCTFail("Could not create event")
            return
        }

        let modifiers = KeyboardInputPipeline.modifiers(from: event)
        XCTAssertTrue(modifiers.isEmpty)
    }

    func testEngineConfigurationDefault() {
        let settings = EasyKeySettings.defaults
        let config = KeyboardInputPipeline.engineConfiguration(for: settings, rule: nil)
        XCTAssertEqual(config.inputMethod, .telex)
        XCTAssertEqual(config.outputEncoding, .unicode)
    }

    func testEngineConfigurationVNI() {
        var settings = EasyKeySettings.defaults
        settings.input.inputMethod = .vni
        settings.input.encoding = .tcvn3

        let config = KeyboardInputPipeline.engineConfiguration(for: settings, rule: nil)
        XCTAssertEqual(config.inputMethod, .vni)
        XCTAssertEqual(config.outputEncoding, .tcvn3)
    }

    func testEngineConfigurationWithRule() {
        let settings = EasyKeySettings.defaults
        let rule = AppCompatibilityRule(
            bundleIdentifier: "com.apple.Safari",
            workarounds: [.unicodeCombiningOutput]
        )

        let config = KeyboardInputPipeline.engineConfiguration(for: settings, rule: rule)
        XCTAssertEqual(config.outputEncoding, .unicodeCombining)
    }

    func testEngineConfigurationTypingOptions() {
        var settings = EasyKeySettings.defaults
        settings.typing.restoreInvalidWord = true
        settings.typing.spellingModernization = false

        let config = KeyboardInputPipeline.engineConfiguration(for: settings, rule: nil)
        XCTAssertTrue(config.autoRestoreKeys)
        XCTAssertFalse(config.modernStyle)
    }

    func testKeyCodeFromEvent() {
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) else {
            XCTFail("Could not create event")
            return
        }
        event.setIntegerValueField(.keyboardEventKeycode, value: 51)

        let keyCode = KeyboardInputPipeline.keyCode(from: event)
        XCTAssertEqual(keyCode, 51)
    }

    func testKeyCodeFromEventDefaultIsValid() {
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) else {
            XCTFail("Could not create event")
            return
        }

        let keyCode = KeyboardInputPipeline.keyCode(from: event)
        XCTAssertNotNil(keyCode)
    }
}
