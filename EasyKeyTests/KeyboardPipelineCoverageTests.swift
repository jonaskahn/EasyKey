import CoreGraphics
@testable import EasyEngineCore
@testable import EasyKeyKit
import XCTest

final class KeyboardPipelineCoverageTests: XCTestCase {
    func testEngineConfigurationAllInputMethods() {
        for method in InputMethod.allCases {
            var settings = EasyKeySettings.defaults
            settings.input.inputMethod = method
            let config = KeyboardInputPipeline.engineConfiguration(for: settings, rule: nil)
            XCTAssertEqual(config.inputMethod, method)
        }
    }

    func testEngineConfigurationAllEncodings() {
        for encoding in EncodingTable.allCases {
            var settings = EasyKeySettings.defaults
            settings.input.encoding = encoding
            let config = KeyboardInputPipeline.engineConfiguration(for: settings, rule: nil)
            XCTAssertEqual(config.outputEncoding, encoding)
        }
    }

    func testEngineConfigurationWithCompatibilityRule() {
        let rules: [(String, Set<AppCompatibilityRule.Workaround>)] = [
            ("com.apple.Safari", [.unicodeCombiningOutput]),
            ("com.apple.Spotlight", [.spotlightSelection]),
            ("com.google.Chrome", [.emptyCharacterInsertion, .chromium]),
        ]
        for (bundleID, workarounds) in rules {
            let rule = AppCompatibilityRule(bundleIdentifier: bundleID, workarounds: workarounds)
            var settings = EasyKeySettings.defaults
            settings.input.encoding = .unicode
            let config = KeyboardInputPipeline.engineConfiguration(for: settings, rule: rule)
            if workarounds.contains(.unicodeCombiningOutput) {
                XCTAssertEqual(config.outputEncoding, .unicodeCombining, bundleID)
            }
        }
    }

    func testEngineConfigurationTypingFlags() {
        var settings = EasyKeySettings.defaults
        settings.typing.restoreInvalidWord = true
        settings.typing.spellingModernization = false
        let config = KeyboardInputPipeline.engineConfiguration(for: settings, rule: nil)
        XCTAssertTrue(config.autoRestoreKeys)
        XCTAssertFalse(config.modernStyle)
    }

    func testKeyCodeFromEventValid() {
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) else {
            XCTFail("Could not create event")
            return
        }
        event.setIntegerValueField(.keyboardEventKeycode, value: 51)
        XCTAssertEqual(KeyboardInputPipeline.keyCode(from: event), 51)
    }

    func testKeyCodeFromEventMax() {
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) else {
            XCTFail("Could not create event")
            return
        }
        event.setIntegerValueField(.keyboardEventKeycode, value: Int64(UInt16.max))
        XCTAssertEqual(KeyboardInputPipeline.keyCode(from: event), UInt16.max)
    }

    func testModifiersFromEventShift() {
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) else {
            XCTFail("Could not create event")
            return
        }
        event.flags = .maskShift
        let modifiers = KeyboardInputPipeline.modifiers(from: event)
        XCTAssertTrue(modifiers.contains(.shift))
        XCTAssertFalse(modifiers.contains(.control))
    }

    func testModifiersFromEventCommand() {
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) else {
            XCTFail("Could not create event")
            return
        }
        event.flags = .maskCommand
        let modifiers = KeyboardInputPipeline.modifiers(from: event)
        XCTAssertTrue(modifiers.contains(.command))
    }

    func testModifiersFromEventMultiple() {
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) else {
            XCTFail("Could not create event")
            return
        }
        event.flags = [.maskShift, .maskControl, .maskAlternate, .maskCommand]
        let modifiers = KeyboardInputPipeline.modifiers(from: event)
        XCTAssertTrue(modifiers.contains(.shift))
        XCTAssertTrue(modifiers.contains(.control))
        XCTAssertTrue(modifiers.contains(.option))
        XCTAssertTrue(modifiers.contains(.command))
    }

    func testIsMouseEventAllTypes() {
        let mouseTypes: [CGEventType] = [
            .leftMouseDown, .rightMouseDown, .otherMouseDown,
            .leftMouseDragged, .rightMouseDragged, .otherMouseDragged,
        ]
        for type in mouseTypes {
            XCTAssertTrue(KeyboardInputPipeline.isMouseEvent(type), "\(type) should be mouse event")
        }
    }

    func testMakeEventMaskNonZero() {
        let mask = KeyboardInputPipeline.makeEventMask()
        XCTAssertNotEqual(mask, 0)
    }

    func testMakeEventMaskIncludesKeyEvents() {
        let mask = KeyboardInputPipeline.makeEventMask()
        let keyDownBit = CGEventMask(1) << CGEventType.keyDown.rawValue
        XCTAssertEqual(mask & keyDownBit, keyDownBit)
    }
}
