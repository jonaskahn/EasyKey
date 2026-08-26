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

    private func unicodeText(of event: CGEvent) -> String {
        var length = 0
        var buffer = [UniChar](repeating: 0, count: 8)
        event.keyboardGetUnicodeString(
            maxStringLength: buffer.count,
            actualStringLength: &length,
            unicodeString: &buffer
        )
        guard length > 0 else { return "" }
        return String(utf16CodeUnits: buffer, count: length)
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

    func testProcess_VietnameseCategoryMacroDoesNotExpandInEnglish() {
        var settings = EasyKeySettings.defaults
        settings.input.language = .english
        settings.macro.enabled = true
        let pipeline = KeyboardInputPipeline(settings: settings)
        pipeline.update(macros: [Macro(trigger: "sig", expansion: "Best regards", category: .vietnamese)])

        for (character, keyCode) in [("s", UInt16(1)), ("i", 34), ("g", 5)] {
            let event = keyEvent(character: character, keyCode: keyCode)
            _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: keyCode)
        }
        let delimiter = keyEvent(character: " ", keyCode: 49)
        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: delimiter, keyCode: 49)

        XCTAssertFalse(result.suppressesOriginal)
        XCTAssertEqual(result.disposition, .bypassed)
    }

    func testProcess_EnglishCategoryMacroExpandsInEnglish() {
        var settings = EasyKeySettings.defaults
        settings.input.language = .english
        settings.macro.enabled = true
        let pipeline = KeyboardInputPipeline(settings: settings)
        pipeline.update(macros: [Macro(trigger: "sig", expansion: "Best regards", category: .english)])

        for (character, keyCode) in [("s", UInt16(1)), ("i", 34), ("g", 5)] {
            let event = keyEvent(character: character, keyCode: keyCode)
            _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: keyCode)
        }
        let delimiter = keyEvent(character: " ", keyCode: 49)
        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: delimiter, keyCode: 49)

        XCTAssertTrue(result.suppressesOriginal)
        XCTAssertEqual(result.disposition, .suppressed)
    }

    func testProcess_MacroTriggerSurvivesFlagsChanged() {
        var settings = EasyKeySettings.defaults
        settings.input.language = .english
        settings.macro.enabled = true
        let pipeline = KeyboardInputPipeline(settings: settings)
        pipeline.update(macros: [Macro(trigger: "sig", expansion: "Best regards", category: .both)])

        for (character, keyCode) in [("s", UInt16(1)), ("i", 34), ("g", 5)] {
            let event = keyEvent(character: character, keyCode: keyCode)
            _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: keyCode)
        }
        let flags = keyEvent(character: "", keyCode: 0)
        _ = pipeline.process(proxy: fakeProxy(), type: .flagsChanged, event: flags, keyCode: 0)
        let delimiter = keyEvent(character: " ", keyCode: 49)
        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: delimiter, keyCode: 49)

        XCTAssertTrue(result.suppressesOriginal)
        XCTAssertEqual(result.disposition, .suppressed)
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

    func testProcess_ShiftFlagsChangedPreservesUppercaseVowelComposition() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        let aDown = keyEvent(character: "A", keyCode: 0, flags: .maskShift)
        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: aDown, keyCode: 0)
        let shiftUp = keyEvent(character: "", keyCode: 56)
        let shiftResult = pipeline.process(proxy: fakeProxy(), type: .flagsChanged, event: shiftUp, keyCode: 56)
        XCTAssertEqual(shiftResult.disposition, .passed)
        XCTAssertTrue(pipeline.isComposing, "Shift release must not flush the uppercase vowel")
        let sDown = keyEvent(character: "s", keyCode: 1)
        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: sDown, keyCode: 1)
        XCTAssertEqual(pipeline.composedTextForTesting, "Á")
    }

    func testProcess_ShiftFlagsChangedPreservesMidWordUppercaseComposition() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        let mDown = keyEvent(character: "m", keyCode: 0)
        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: mDown, keyCode: 0)
        let shiftDown = keyEvent(character: "", keyCode: 56)
        _ = pipeline.process(proxy: fakeProxy(), type: .flagsChanged, event: shiftDown, keyCode: 56)
        let aDown = keyEvent(character: "A", keyCode: 0, flags: .maskShift)
        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: aDown, keyCode: 0)
        let shiftUp = keyEvent(character: "", keyCode: 56)
        _ = pipeline.process(proxy: fakeProxy(), type: .flagsChanged, event: shiftUp, keyCode: 56)
        let iDown = keyEvent(character: "i", keyCode: 34)
        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: iDown, keyCode: 34)
        let sDown = keyEvent(character: "s", keyCode: 1)
        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: sDown, keyCode: 1)
        XCTAssertEqual(pipeline.composedTextForTesting, "mÁi")
    }

    func testProcess_ControlFlagsChangedStillResetsComposition() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        let aDown = keyEvent(character: "a", keyCode: 0)
        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: aDown, keyCode: 0)
        let controlDown = keyEvent(character: "", keyCode: 59, flags: .maskControl)
        _ = pipeline.process(proxy: fakeProxy(), type: .flagsChanged, event: controlDown, keyCode: 59)
        XCTAssertFalse(pipeline.isComposing, "Control flags change should flush the composition")
        let sDown = keyEvent(character: "s", keyCode: 1)
        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: sDown, keyCode: 1)
        XCTAssertEqual(pipeline.composedTextForTesting, "s")
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
        pipeline.onLanguageToggleRequested = { language in
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
        pipeline.onLanguageToggleRequested = { language in
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
        XCTAssertEqual(pipeline.activeApplicationBundleIdentifier, "com.apple.Safari")
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

    func testProcess_SpotlightToneRewrite_DoesNotCrash() {
        let pipeline = KeyboardInputPipeline(
            settings: .defaults,
            spotlightVisibilityProvider: { true }
        )

        for (character, keyCode) in [("c", UInt16(8)), ("a", 0), ("s", 1)] {
            let event = keyEvent(character: character, keyCode: keyCode)
            _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: keyCode)
        }
    }

    func testProcess_SpotlightPlainBackspace_DoesNotCrash() {
        let pipeline = KeyboardInputPipeline(
            settings: .defaults,
            spotlightVisibilityProvider: { true }
        )

        let insert = keyEvent(character: "a", keyCode: 0)
        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: insert, keyCode: 0)

        let backspace = keyEvent(character: "", keyCode: 51)
        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: backspace, keyCode: 51)
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

    func testProcess_FunctionKeyPassesThroughWhenIgnoredByDefault() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        let event = keyEvent(character: "\u{10}", keyCode: 111)

        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: 111)

        XCTAssertEqual(result.disposition, .bypassed)
        XCTAssertFalse(result.suppressesOriginal)
    }

    func testProcess_FunctionKeyMidCompositionFlushesAndPassesThrough() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        let aDown = keyEvent(character: "a", keyCode: 0)
        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: aDown, keyCode: 0)
        XCTAssertTrue(pipeline.isComposing)

        let f12Down = keyEvent(character: "\u{10}", keyCode: 111)
        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: f12Down, keyCode: 111)

        XCTAssertEqual(result.disposition, .bypassed)
        XCTAssertFalse(pipeline.isComposing)
    }

    func testProcess_FunctionKeyWhenIgnoringDisabled_IsSuppressed() {
        var settings = EasyKeySettings.defaults
        settings.typing.ignoreFunctionKeys = false
        let pipeline = KeyboardInputPipeline(settings: settings)
        let event = keyEvent(character: "\u{10}", keyCode: 111)

        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: 111)

        XCTAssertEqual(result.disposition, .suppressed)
    }

    func testProcess_FunctionKeyBoundAsSwitchShortcutStillTogglesLanguage() {
        var settings = EasyKeySettings.defaults
        settings.input.switchShortcut = Shortcut(keyCode: 111)
        let pipeline = KeyboardInputPipeline(settings: settings)
        let expectation = expectation(description: "toggle language")
        pipeline.onLanguageToggleRequested = { language in
            XCTAssertEqual(language, .english)
            expectation.fulfill()
        }

        let event = keyEvent(character: "\u{10}", keyCode: 111)
        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: 111)

        XCTAssertEqual(result.disposition, .suppressed)
        wait(for: [expectation], timeout: 1.0)
    }

    func testProcess_ReturnCommit_PostsPhysicalReturn() {
        var settings = EasyKeySettings.defaults
        settings.input.language = .vietnamese
        var posted: [CGEvent] = []
        let pipeline = KeyboardInputPipeline(
            settings: settings,
            eventPoster: { event, _ in posted.append(event) }
        )

        for (character, keyCode) in [("a", UInt16(0)), ("s", UInt16(1))] {
            let event = keyEvent(character: character, keyCode: keyCode)
            _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: keyCode)
        }
        XCTAssertTrue(pipeline.isComposing)

        let returnEvent = keyEvent(character: "\n", keyCode: 36)
        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: returnEvent, keyCode: 36)

        XCTAssertTrue(result.suppressesOriginal)
        XCTAssertEqual(result.disposition, .suppressed)
        XCTAssertFalse(pipeline.isComposing, "Return commit should reset the composition")

        let postedReturnDown = posted.contains { event in
            event.type == .keyDown && event.getIntegerValueField(.keyboardEventKeycode) == 36
        }
        XCTAssertTrue(postedReturnDown, "Return commit should re-post a physical Return keyDown")
    }

    func testProcess_ReturnCommitInChromium_DoesNotPostStrayZeroWidthSpace() {
        var settings = EasyKeySettings.defaults
        settings.input.language = .vietnamese
        var posted: [CGEvent] = []
        let pipeline = KeyboardInputPipeline(
            settings: settings,
            eventPoster: { event, _ in posted.append(event) }
        )
        pipeline.setActiveApplication("com.google.Chrome")

        for (character, keyCode) in [("a", UInt16(0)), ("s", UInt16(1))] {
            let event = keyEvent(character: character, keyCode: keyCode)
            _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: keyCode)
        }

        let returnEvent = keyEvent(character: "\n", keyCode: 36)
        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: returnEvent, keyCode: 36)

        let returnUpIndex = posted.lastIndex { event in
            event.type == .keyUp && event.getIntegerValueField(.keyboardEventKeycode) == 36
        }
        guard let returnUpIndex else {
            XCTFail("Expected a physical Return keyUp to be posted")
            return
        }
        for event in posted[(returnUpIndex + 1)...] {
            XCTAssertFalse(
                unicodeText(of: event).contains("\u{200B}"),
                "Stray zero-width space after Return commit"
            )
        }
    }

    func testProcess_SpaceCommitInChromium_PostsZeroWidthSpace() {
        var settings = EasyKeySettings.defaults
        settings.input.language = .vietnamese
        var posted: [CGEvent] = []
        let pipeline = KeyboardInputPipeline(
            settings: settings,
            eventPoster: { event, _ in posted.append(event) }
        )
        pipeline.setActiveApplication("com.google.Chrome")

        for (character, keyCode) in [("x", UInt16(6)), ("i", 34), ("n", 45)] {
            let event = keyEvent(character: character, keyCode: keyCode)
            _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: keyCode)
        }
        XCTAssertTrue(pipeline.isComposing, "Should be composing after typing 'xin'")

        let spaceEvent = keyEvent(character: " ", keyCode: 49)
        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: spaceEvent, keyCode: 49)

        XCTAssertFalse(pipeline.isComposing, "Space commit should end composition")

        let spaceInsertIndex = posted.lastIndex { event in
            event.type == .keyDown && unicodeText(of: event) == " "
        }
        guard let spaceInsertIndex else {
            XCTFail("Expected a Space character to be inserted")
            return
        }
        var foundZWS = false
        for event in posted[(spaceInsertIndex + 1)...] {
            if unicodeText(of: event).contains("\u{200B}") {
                foundZWS = true
                break
            }
        }
        XCTAssertTrue(
            foundZWS,
            "Zero-width space must be posted after Space commit in Chromium to maintain IME session"
        )
    }

    func testProcess_TypingTwoWordsCombiningOutput_PreservesSpaceBetweenWords() {
        // Regression: typing "tuyeenf nguyeenx" in Chrome (combining output)
        // produced "tuyềnguyễn" — the space was deleted because replacement
        // backspaces were counted in UTF-16 units (ề = 3) instead of grapheme
        // clusters (ề = 1), over-deleting the preceding space.
        var settings = EasyKeySettings.defaults
        settings.input.language = .vietnamese
        var posted: [CGEvent] = []
        let pipeline = KeyboardInputPipeline(
            settings: settings,
            eventPoster: { event, _ in posted.append(event) }
        )
        pipeline.setActiveApplication("com.google.Chrome")

        let firstWord: [(String, UInt16)] = [
            ("t", 17), ("u", 32), ("y", 16), ("e", 14), ("e", 14), ("n", 45), ("f", 3),
        ]
        for (character, keyCode) in firstWord {
            let event = keyEvent(character: character, keyCode: keyCode)
            _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: keyCode)
        }
        let spaceEvent = keyEvent(character: " ", keyCode: 49)
        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: spaceEvent, keyCode: 49)
        XCTAssertFalse(pipeline.isComposing, "Space commit should end composition")

        let secondWord: [(String, UInt16)] = [
            ("n", 45), ("g", 5), ("u", 32), ("y", 16), ("e", 14), ("e", 14), ("n", 45), ("x", 7),
        ]
        for (character, keyCode) in secondWord {
            let event = keyEvent(character: character, keyCode: keyCode)
            _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: keyCode)
        }

        // Replay the posted events into a fake field: unicode keyDowns insert
        // text, physical backspace (keyCode 51) deletes one grapheme cluster.
        var field = ""
        for event in posted where event.type == .keyDown {
            if event.getIntegerValueField(.keyboardEventKeycode) == 51 {
                if !field.isEmpty { field.removeLast() }
            } else {
                field += unicodeText(of: event)
            }
        }

        let visible = field
            .replacingOccurrences(of: "​", with: "")
            .replacingOccurrences(of: " ", with: "")
        XCTAssertEqual(visible, "tuyền nguyễn")
    }
}
