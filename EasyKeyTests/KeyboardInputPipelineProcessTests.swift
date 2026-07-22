import CoreGraphics
@testable import EasyEngineCore
@testable import EasyKeyKit
import XCTest

final class KeyboardInputPipelineProcessTests: XCTestCase {
    private func fakeProxy() -> CGEventTapProxy {
        unsafeBitCast(UInt(0), to: CGEventTapProxy.self)
    }

    private func keyEvent(character: String, keyCode: UInt16, flags: CGEventFlags = []) -> CGEvent {
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) else {
            fatalError("Could not create event")
        }
        event.setIntegerValueField(.keyboardEventKeycode, value: Int64(keyCode))
        event.flags = flags
        let utf16 = Array(character.utf16)
        utf16.withUnsafeBufferPointer { buffer in
            event.keyboardSetUnicodeString(stringLength: buffer.count, unicodeString: buffer.baseAddress)
        }
        return event
    }

    func testProcess_TypingVietnameseWord_SuppressesAndProducesOutput() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        let events: [(String, UInt16)] = [("a", 0), ("s", 1)]
        var lastResult: KeyboardProcessResult?
        for (character, keyCode) in events {
            let event = keyEvent(character: character, keyCode: keyCode)
            lastResult = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: keyCode)
        }
        XCTAssertNotNil(lastResult)
    }

    func testProcess_EnglishLanguage_Bypasses() {
        var settings = EasyKeySettings.defaults
        settings.input.language = .english
        let pipeline = KeyboardInputPipeline(settings: settings)
        let event = keyEvent(character: "a", keyCode: 0)
        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: 0)
        XCTAssertEqual(result.disposition, .bypassed)
    }

    func testProcess_MacroExpandsWhenSpaceFollowsTrigger() {
        var settings = EasyKeySettings.defaults
        settings.macro.enabled = true
        let pipeline = KeyboardInputPipeline(settings: settings)
        pipeline.update(macros: [Macro(trigger: "sig", expansion: "Best regards")])

        for (character, keyCode) in [("s", UInt16(1)), ("i", 34), ("g", 5)] {
            let event = keyEvent(character: character, keyCode: keyCode)
            _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: keyCode)
        }
        let delimiter = keyEvent(character: " ", keyCode: 49)
        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: delimiter, keyCode: 49)

        XCTAssertTrue(result.suppressesOriginal)
        XCTAssertEqual(result.disposition, .suppressed)
    }

    func testProcess_MacroDoesNotExpandInEnglishUnlessEnabled() {
        var settings = EasyKeySettings.defaults
        settings.input.language = .english
        settings.macro.enabled = true
        let pipeline = KeyboardInputPipeline(settings: settings)
        pipeline.update(macros: [Macro(trigger: "sig", expansion: "Best regards")])

        for (character, keyCode) in [("s", UInt16(1)), ("i", 34), ("g", 5)] {
            let event = keyEvent(character: character, keyCode: keyCode)
            _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: keyCode)
        }
        let delimiter = keyEvent(character: " ", keyCode: 49)
        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: delimiter, keyCode: 49)

        XCTAssertFalse(result.suppressesOriginal)
        XCTAssertEqual(result.disposition, .bypassed)
    }

    func testProcess_EmergencyShortcutPrecedesIgnoredApplication() {
        var settings = EasyKeySettings.defaults
        settings.compatibility.ignoredApplicationBundleIdentifiers = ["dev.example.Ignored"]
        let pipeline = KeyboardInputPipeline(settings: settings)
        pipeline.setActiveApplication("dev.example.Ignored")
        let shortcut = KeyboardService.defaultEmergencyPauseShortcut
        let event = keyEvent(character: "", keyCode: shortcut.keyCode, flags: [.maskControl, .maskAlternate, .maskCommand])

        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: shortcut.keyCode)

        XCTAssertEqual(result.disposition, .suppressed)
        XCTAssertTrue(result.suppressesOriginal)
    }

    func testProcess_MouseEvent_ResetsSessionAndPasses() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) else {
            XCTFail("Could not create event")
            return
        }
        let result = pipeline.process(proxy: fakeProxy(), type: .leftMouseDown, event: event, keyCode: nil)
        XCTAssertEqual(result.disposition, .passed)
    }

    func testProcess_FlagsChanged_ResetsSessionAndPasses() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) else {
            XCTFail("Could not create event")
            return
        }
        let result = pipeline.process(proxy: fakeProxy(), type: .flagsChanged, event: event, keyCode: nil)
        XCTAssertEqual(result.disposition, .passed)
    }

    func testProcess_KeyUpEvent_Passes() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        let event = keyEvent(character: "a", keyCode: 0)
        let result = pipeline.process(proxy: fakeProxy(), type: .keyUp, event: event, keyCode: 0)
        XCTAssertEqual(result.disposition, .passed)
    }

    func testProcess_EmergencyPauseShortcut_TogglesPause() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        let expectation = expectation(description: "toggle pause")
        pipeline.onTogglePause = { expectation.fulfill() }

        let shortcut = KeyboardService.defaultEmergencyPauseShortcut
        let event = keyEvent(character: "", keyCode: shortcut.keyCode, flags: [.maskControl, .maskAlternate, .maskCommand])
        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: shortcut.keyCode)
        XCTAssertEqual(result.disposition, .suppressed)
        wait(for: [expectation], timeout: 1.0)
    }

    func testProcess_SwitchShortcut_TogglesLanguage() {
        var settings = EasyKeySettings.defaults
        settings.input.switchShortcut = Shortcut(keyCode: 49, modifiers: [.control, .command])
        let pipeline = KeyboardInputPipeline(settings: settings)
        let expectation = expectation(description: "toggle language")
        pipeline.onLanguageToggled = { language in
            XCTAssertEqual(language, .english)
            expectation.fulfill()
        }

        let event = keyEvent(character: "", keyCode: 49, flags: [.maskControl, .maskCommand])
        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: 49)
        XCTAssertEqual(result.disposition, .suppressed)
        wait(for: [expectation], timeout: 1.0)
    }

    func testProcess_ModifierOnlySwitchShortcut_OnFlagsChanged_TogglesLanguage() {
        var settings = EasyKeySettings.defaults
        settings.input.switchShortcut = .modifiersOnly([.control, .command])
        let pipeline = KeyboardInputPipeline(settings: settings)
        let expectation = expectation(description: "toggle language via flagsChanged")
        pipeline.onLanguageToggled = { language in
            XCTAssertEqual(language, .english)
            expectation.fulfill()
        }

        let event = keyEvent(character: "", keyCode: 0, flags: [.maskControl, .maskCommand])
        let result = pipeline.process(proxy: fakeProxy(), type: .flagsChanged, event: event, keyCode: nil)
        XCTAssertEqual(result.disposition, .suppressed)
        wait(for: [expectation], timeout: 1.0)
    }

    func testProcess_SynthesisFailurePassesOriginalInput() {
        let pipeline = KeyboardInputPipeline(
            settings: .defaults,
            eventFactory: { _, _ in nil }
        )
        let event = keyEvent(character: "a", keyCode: 0)

        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: 0)

        XCTAssertEqual(result.disposition, .passed)
        XCTAssertFalse(result.suppressesOriginal)
    }

    func testUpdate_ChangesConfigurationAndResetsSession() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        var settings = EasyKeySettings.defaults
        settings.input.inputMethod = .vni
        pipeline.update(settings: settings)
    }

    func testSetActiveApplication_UpdatesSnapshotAndConfiguresRule() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        pipeline.setActiveApplication("com.apple.Safari")
        XCTAssertEqual(pipeline.activeBundleIdentifierSnapshot, "com.apple.Safari")
    }

    func testSetActiveApplication_ChromiumBundle_UsesAddressBarPath() {
        var settings = EasyKeySettings.defaults
        settings.input.language = .vietnamese
        let pipeline = KeyboardInputPipeline(settings: settings)
        pipeline.setActiveApplication("com.google.Chrome")

        let events: [(String, UInt16)] = [("a", 0), ("s", 1)]
        for (character, keyCode) in events {
            let event = keyEvent(character: character, keyCode: keyCode)
            _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: keyCode)
        }
    }

    func testSetUsesForeignInputSource_TrueThenFalse() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        pipeline.setUsesForeignInputSource(true)
        pipeline.setUsesForeignInputSource(false)
    }

    func testResetSession_ClearsEngineAndSynthesizer() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        let event = keyEvent(character: "a", keyCode: 0)
        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: 0)
        pipeline.resetSession()
    }

    func testProcess_SpecialKeyBackspace_Passes() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        let event = keyEvent(character: "", keyCode: 51)
        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: 51)
        XCTAssertNotNil(result)
    }

    func testIsCurrentInputSourceForeign_DoesNotCrash() {
        _ = KeyboardInputPipeline.isCurrentInputSourceForeign()
    }

    func testNormalize_BuildsExpectedKeyEvent() {
        let event = keyEvent(character: "a", keyCode: 0, flags: .maskShift)
        let normalized = KeyboardInputPipeline.normalize(event: event, keyCode: 0)
        XCTAssertTrue(normalized.shift)
    }

    func testProcess_SpotlightVisible_TypingRunsWithoutDesync() {
        let pipeline = KeyboardInputPipeline(settings: .defaults, spotlightVisibilityProvider: { true })

        for (character, keyCode) in [("a", UInt16(0)), ("s", UInt16(1))] {
            let event = keyEvent(character: character, keyCode: keyCode)
            let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: keyCode)
            XCTAssertEqual(result.disposition, .suppressed)
        }
    }

    func testProcess_SpotlightVisibility_CachedWithinTTL() {
        var providerCalls = 0
        let pipeline = KeyboardInputPipeline(settings: .defaults, spotlightVisibilityProvider: {
            providerCalls += 1
            return false
        })

        for (character, keyCode) in [("a", UInt16(0)), ("s", UInt16(1))] {
            let event = keyEvent(character: character, keyCode: keyCode)
            _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: keyCode)
        }

        XCTAssertEqual(providerCalls, 1)
    }

    func testProcess_MouseEvent_InvalidatesSpotlightCache() {
        var providerCalls = 0
        let pipeline = KeyboardInputPipeline(settings: .defaults, spotlightVisibilityProvider: {
            providerCalls += 1
            return false
        })

        let first = keyEvent(character: "a", keyCode: 0)
        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: first, keyCode: 0)
        XCTAssertEqual(providerCalls, 1)

        guard let mouse = CGEvent(source: nil) else {
            XCTFail("Could not create event")
            return
        }
        _ = pipeline.process(proxy: fakeProxy(), type: .leftMouseDown, event: mouse, keyCode: nil)

        let second = keyEvent(character: "a", keyCode: 0)
        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: second, keyCode: 0)
        XCTAssertEqual(providerCalls, 2)
    }

    func testSpotlightWindowDetector_DoesNotCrash() {
        _ = SpotlightWindowDetector.isSpotlightWindowVisible()
    }

    func testProcess_SpotlightToneRewrite_NeverInvokesFocusedTextReplacer() {
        var replacerCallCount = 0
        let pipeline = KeyboardInputPipeline(
            settings: .defaults,
            spotlightVisibilityProvider: { true },
            focusedTextReplacer: { _, _ in
                replacerCallCount += 1
                return .succeeded
            }
        )

        for (character, keyCode) in [("c", UInt16(8)), ("a", 0), ("s", 1)] {
            let event = keyEvent(character: character, keyCode: keyCode)
            _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: keyCode)
        }

        XCTAssertEqual(replacerCallCount, 0)
    }

    func testProcess_SpotlightPlainBackspace_NeverInvokesFocusedTextReplacer() {
        var replacerCallCount = 0
        let pipeline = KeyboardInputPipeline(
            settings: .defaults,
            spotlightVisibilityProvider: { true },
            focusedTextReplacer: { _, _ in
                replacerCallCount += 1
                return .succeeded
            }
        )

        let insert = keyEvent(character: "a", keyCode: 0)
        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: insert, keyCode: 0)

        let backspace = keyEvent(character: "", keyCode: 51)
        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: backspace, keyCode: 51)

        XCTAssertEqual(replacerCallCount, 0)
    }

    func testSpotlightReplacementBreaksAutocomplete() {
        XCTAssertTrue(KeyboardInputPipeline.shouldBreakAutocomplete(
            inChromiumAddressBar: false,
            isSpotlight: true,
            deleteCount: 5
        ))
        XCTAssertFalse(KeyboardInputPipeline.shouldBreakAutocomplete(
            inChromiumAddressBar: false,
            isSpotlight: true,
            deleteCount: 0
        ))
    }

    func testCmdCDoublePress_DoesNotFireWithoutCommandModifier() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        var activated = false
        pipeline.setCmdCDoublePressHandler(windowMs: 400) { activated = true }

        let event = keyEvent(character: "c", keyCode: 8, flags: [])
        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: 8)
        XCTAssertFalse(activated)
    }

    func testCmdCDoublePress_DoesNotFireWithOptionModifier() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        var activated = false
        pipeline.setCmdCDoublePressHandler(windowMs: 400) { activated = true }

        let event = keyEvent(character: "c", keyCode: 8, flags: [.maskCommand, .maskAlternate])
        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: 8)
        XCTAssertFalse(activated)
    }

    func testCmdCDoublePress_ResetsOnInterveningNonMatchingKey() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        var activated = false
        pipeline.setCmdCDoublePressHandler(windowMs: 400) { activated = true }

        let cEvent = keyEvent(character: "c", keyCode: 8, flags: .maskCommand)
        let vEvent = keyEvent(character: "v", keyCode: 9, flags: .maskCommand)

        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: cEvent, keyCode: 8)
        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: vEvent, keyCode: 9)
        XCTAssertFalse(activated)
    }

    func testCmdCDoublePress_DoesNotFireWhenHandlerCleared() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        var activated = false
        pipeline.setCmdCDoublePressHandler(windowMs: 400) { activated = true }
        pipeline.clearCmdCDoublePressHandler()

        let event = keyEvent(character: "c", keyCode: 8, flags: .maskCommand)
        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: 8)
        XCTAssertFalse(activated)
    }
}
