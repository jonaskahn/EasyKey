import CoreGraphics
@testable import EasyEngineCore
@testable import EasyKeyKit
import XCTest

final class KeyboardPipelineCoverageTests: XCTestCase {
    private func fakeProxy() -> CGEventTapProxy {
        unsafeBitCast(UInt(0), to: CGEventTapProxy.self)
    }

    private func makeKeyDown(keyCode: Int64 = 0) -> CGEvent? {
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) else {
            return nil
        }
        event.setIntegerValueField(.keyboardEventKeycode, value: keyCode)
        return event
    }

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
        settings.typing.toneStyle = .new
        settings.typing.liveConfidenceScoring = true
        settings.typing.liveConfidenceLowThreshold = 0.4
        settings.typing.liveConfidenceHighThreshold = 0.75
        let config = KeyboardInputPipeline.engineConfiguration(for: settings, rule: nil)
        XCTAssertTrue(config.autoRestoreKeys)
        XCTAssertEqual(config.toneStyle, .new)
        XCTAssertTrue(config.liveConfidenceScoring)
        XCTAssertEqual(config.liveConfidenceLowThreshold, 0.4)
        XCTAssertEqual(config.liveConfidenceHighThreshold, 0.75)
    }

    func testProcess_LiveConfidenceRawDisplay_TracksInsertCharacterUnits() {
        var settings = EasyKeySettings.defaults
        settings.typing.liveConfidenceScoring = true
        let pipeline = KeyboardInputPipeline(
            settings: settings,
            eventFactory: { keyCode, keyDown in
                CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: keyDown)
            }
        )

        func keyEvent(character: String, keyCode: UInt16) -> CGEvent {
            guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) else {
                fatalError("Could not create event")
            }
            event.setIntegerValueField(.keyboardEventKeycode, value: Int64(keyCode))
            let utf16 = Array(character.utf16)
            utf16.withUnsafeBufferPointer { buffer in
                event.keyboardSetUnicodeString(stringLength: buffer.count, unicodeString: buffer.baseAddress)
            }
            return event
        }

        let proxy = unsafeBitCast(UInt(0), to: CGEventTapProxy.self)
        for (character, keyCode) in [("s", UInt16(1)), ("t", 17), ("r", 15)] {
            let event = keyEvent(character: character, keyCode: keyCode)
            let result = pipeline.process(proxy: proxy, type: .keyDown, event: event, keyCode: keyCode)
            XCTAssertTrue(result.suppressesOriginal, character)
        }

        XCTAssertEqual(pipeline.encodedUnitCountForTesting, 3)

        let backspace = keyEvent(character: "", keyCode: 51)
        let backspaceResult = pipeline.process(proxy: proxy, type: .keyDown, event: backspace, keyCode: 51)
        XCTAssertTrue(backspaceResult.suppressesOriginal)
        XCTAssertEqual(pipeline.encodedUnitCountForTesting, 2)
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

    func testProcess_IgnoredApplication_Bypasses() {
        var settings = EasyKeySettings.defaults
        let bundleID = "com.example.ignored"
        settings.compatibility.ignoredApplicationBundleIdentifiers = [bundleID]
        let pipeline = KeyboardInputPipeline(settings: settings)
        pipeline.setActiveApplication(bundleID)
        guard let event = makeKeyDown() else { XCTFail("Failed to create key down event"); return }
        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: 0)
        XCTAssertEqual(result.disposition, .bypassed)
    }

    func testProcess_KeyUp_PassesThrough() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false)
        else { XCTFail("key up event"); return }
        let result = pipeline.process(proxy: fakeProxy(), type: .keyUp, event: event, keyCode: nil)
        XCTAssertEqual(result.disposition, .passed)
    }

    func testProcess_KeyDownNilKeyCode_PassesThrough() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        guard let event = makeKeyDown() else { XCTFail("Failed to create key event for nil keyCode test"); return }
        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: nil)
        XCTAssertEqual(result.disposition, .passed)
    }

    func testProcess_MouseEvent_ResetsAndPasses() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        guard let event = makeKeyDown() else { XCTFail("Failed to create mouse event"); return }
        let result = pipeline.process(proxy: fakeProxy(), type: .leftMouseDown, event: event, keyCode: 0)
        XCTAssertEqual(result.disposition, .passed)
    }

    func testProcess_FlagsChangedNoShortcut_ResetsAndPasses() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 100, keyDown: true)
        else { XCTFail("flags changed event"); return }
        let result = pipeline.process(proxy: fakeProxy(), type: .flagsChanged, event: event, keyCode: 100)
        XCTAssertEqual(result.disposition, .passed)
    }

    func testProcess_FlagsChangedEmergencyShortcut_PassesThrough() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 35, keyDown: true)
        else { XCTFail("emergency flagsChanged"); return }
        event.flags = [.maskControl, .maskAlternate, .maskCommand]
        let result = pipeline.process(proxy: fakeProxy(), type: .flagsChanged, event: event, keyCode: 35)
        XCTAssertEqual(result.disposition, .passed)
    }

    func testProcess_FlagsChangedSwitchShortcut_PassesThrough() {
        var settings = EasyKeySettings.defaults
        settings.input.switchShortcut = Shortcut(keyCode: 6, modifiers: [.option])
        let pipeline = KeyboardInputPipeline(settings: settings)
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 6, keyDown: true)
        else { XCTFail("switch flagsChanged"); return }
        event.flags = .maskAlternate
        let result = pipeline.process(proxy: fakeProxy(), type: .flagsChanged, event: event, keyCode: 6)
        XCTAssertEqual(result.disposition, .passed)
    }

    func testProcess_KeyDownEmergencyShortcut_Suppresses() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 35, keyDown: true)
        else { XCTFail("emergency suppress"); return }
        event.flags = [.maskControl, .maskAlternate, .maskCommand]
        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: 35)
        XCTAssertEqual(result.disposition, .suppressed)
    }

    func testProcess_KeyDownSwitchShortcut_Suppresses() {
        var settings = EasyKeySettings.defaults
        settings.input.switchShortcut = Shortcut(keyCode: 6, modifiers: [.option])
        let pipeline = KeyboardInputPipeline(settings: settings)
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 6, keyDown: true)
        else { XCTFail("switch suppress"); return }
        event.flags = .maskAlternate
        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: 6)
        XCTAssertEqual(result.disposition, .suppressed)
    }

    func testIsChromiumAddressBar_NotChromium_DoesNotCrash() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        pipeline.setActiveApplication("com.example.notchromium")
    }

    func testIsCurrentInputSourceForeign_DoesNotCrash() {
        let result = KeyboardInputPipeline.isCurrentInputSourceForeign()
        _ = result
    }

    func testUpdateMacros_DoesNotCrash() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        pipeline.update(macros: [])
    }

    func testResetSession_DoesNotCrash() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        pipeline.resetSession()
    }

    func testShouldBreakAutocomplete_InChromiumNotSpotlight_WithDelete() {
        XCTAssertTrue(KeyboardInputPipeline.shouldBreakAutocomplete(inChromiumAddressBar: true, isSpotlight: false, deleteCount: 3))
    }

    func testShouldBreakAutocomplete_InChromiumZeroDelete_ReturnsFalse() {
        XCTAssertFalse(KeyboardInputPipeline.shouldBreakAutocomplete(inChromiumAddressBar: true, isSpotlight: false, deleteCount: 0))
    }

    func testShouldBreakAutocomplete_NotChromium_ReturnsFalse() {
        XCTAssertFalse(KeyboardInputPipeline.shouldBreakAutocomplete(inChromiumAddressBar: false, isSpotlight: false, deleteCount: 5))
    }

    func testShouldBreakAutocomplete_InSpotlight_ReturnsTrue() {
        XCTAssertTrue(KeyboardInputPipeline.shouldBreakAutocomplete(inChromiumAddressBar: true, isSpotlight: true, deleteCount: 3))
    }

    func testNormalize_WithCommandModifier_HasModifiers() {
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)
        else { XCTFail("normalize event"); return }
        event.flags = .maskCommand
        let normalized = KeyboardInputPipeline.normalize(event: event, keyCode: 0)
        XCTAssertTrue(normalized.hasModifiers)
    }

    // MARK: - processFlagsChanged branches

    func testProcess_FlagsChanged_RestoreWordShortcut_WhenVietnamese() {
        var settings = EasyKeySettings.defaults
        settings.input.language = .vietnamese
        settings.typing.restoreWordShortcut = Shortcut(keyCode: 10, modifiers: [.option])
        let pipeline = KeyboardInputPipeline(settings: settings)
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 10, keyDown: true)
        else { XCTFail("restore event"); return }
        event.flags = .maskAlternate
        let result = pipeline.process(proxy: fakeProxy(), type: .flagsChanged, event: event, keyCode: 10)
        _ = result
    }

    func testProcess_FlagsChanged_RestoreWordShortcut_WhenNotVietnamese_DoesNotMatch() {
        var settings = EasyKeySettings.defaults
        settings.input.language = .english
        settings.typing.restoreWordShortcut = Shortcut(keyCode: 10, modifiers: [.option])
        let pipeline = KeyboardInputPipeline(settings: settings)
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 10, keyDown: true)
        else { XCTFail("non vi restore"); return }
        event.flags = .maskAlternate
        let result = pipeline.process(proxy: fakeProxy(), type: .flagsChanged, event: event, keyCode: 10)
        XCTAssertEqual(result.disposition, .passed)
    }

    func testProcess_KeyDown_RestoreWordShortcut_WhenVietnamese() {
        var settings = EasyKeySettings.defaults
        settings.input.language = .vietnamese
        settings.typing.restoreWordShortcut = Shortcut(keyCode: 10, modifiers: [.option])
        let pipeline = KeyboardInputPipeline(settings: settings)
        for (character, code) in [("a", UInt16(0)), ("s", UInt16(1))] {
            guard let input = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: true) else {
                XCTFail("composition key")
                return
            }
            let units = Array(character.utf16)
            units.withUnsafeBufferPointer {
                input.keyboardSetUnicodeString(stringLength: $0.count, unicodeString: $0.baseAddress)
            }
            _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: input, keyCode: code)
        }
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 10, keyDown: true)
        else { XCTFail("restore key"); return }
        event.flags = .maskAlternate
        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: 10)
        XCTAssertEqual(result.disposition, .suppressed)
    }

    func testProcess_KeyDown_NonVietnamese_Bypasses() {
        var settings = EasyKeySettings.defaults
        settings.input.language = .english
        settings.compatibility.otherLanguageSupport = true
        let pipeline = KeyboardInputPipeline(settings: settings)
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) else {
            XCTFail("Cannot create event")
            return
        }
        event.setIntegerValueField(.keyboardEventKeycode, value: 0)
        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: 0)
        XCTAssertEqual(result.disposition, .bypassed)
    }

    func testProcess_FlagsChanged_NoMatchingShortcut_InvalidatesCache() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 200, keyDown: true)
        else { XCTFail("random key"); return }
        let result = pipeline.process(proxy: fakeProxy(), type: .flagsChanged, event: event, keyCode: 200)
        XCTAssertEqual(result.disposition, .passed)
    }

    // MARK: - Shortcut matches when no keyCode

    func testShortcutMatches_NoKeyCodeModifiersOnly_FlagsChanged() {
        var settings = EasyKeySettings.defaults
        settings.input.switchShortcut = .modifiersOnly([.option])
        let pipeline = KeyboardInputPipeline(settings: settings)
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)
        else { XCTFail("no keyCode event"); return }
        event.flags = .maskAlternate
        let result = pipeline.process(proxy: fakeProxy(), type: .flagsChanged, event: event, keyCode: nil)
        XCTAssertEqual(result.disposition, .suppressed)
    }

    func testShortcutKeyCodeZeroMatchesAKeyDownNotFlagsChanged() {
        var settings = EasyKeySettings.defaults
        settings.input.switchShortcut = Shortcut(keyCode: 0, modifiers: [.option])
        let pipeline = KeyboardInputPipeline(settings: settings)
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) else {
            XCTFail("A key event")
            return
        }
        event.flags = .maskAlternate

        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: 0)

        XCTAssertEqual(result.disposition, .suppressed)
    }

    // MARK: - process with ignored bundle

    func testProcess_IgnoredAppNoMacros() {
        var settings = EasyKeySettings.defaults
        let bundleID = "com.ignored.test-\(UUID().uuidString)"
        settings.compatibility.ignoredApplicationBundleIdentifiers = [bundleID]
        let pipeline = KeyboardInputPipeline(settings: settings)
        pipeline.setActiveApplication(bundleID)
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)
        else { XCTFail("ignored event"); return }
        event.setIntegerValueField(.keyboardEventKeycode, value: 0)
        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: 0)
        XCTAssertEqual(result.disposition, .bypassed)
    }

    func testEmergencyShortcutPrecedesIgnoredApplicationBypass() {
        var settings = EasyKeySettings.defaults
        let bundleID = "com.ignored.emergency"
        settings.compatibility.ignoredApplicationBundleIdentifiers = [bundleID]
        let pipeline = KeyboardInputPipeline(settings: settings)
        pipeline.setActiveApplication(bundleID)
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 35, keyDown: true) else {
            XCTFail("Emergency key event")
            return
        }
        event.flags = [.maskControl, .maskAlternate, .maskCommand]

        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: 35)

        XCTAssertEqual(result.disposition, .suppressed)
    }
}
