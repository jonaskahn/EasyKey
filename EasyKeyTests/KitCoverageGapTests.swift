import AppKit
import CoreGraphics
@testable import EasyEngineCore
@testable import EasyKeyKit
import XCTest

@MainActor
final class KitCoverageGapTests: XCTestCase {
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

    private func typeWord(_ word: String, pipeline: KeyboardInputPipeline, keyCodes: [UInt16]) {
        for (index, character) in word.enumerated() {
            let event = keyEvent(character: String(character), keyCode: keyCodes[index])
            _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: keyCodes[index])
        }
    }

    // MARK: - FocusedElementInspector

    func testIsChromiumAddressBar_DoesNotCrash() {
        _ = FocusedElementInspector.isChromiumAddressBar()
        _ = FocusedElementInspector.isChromiumAddressBar()
    }

    // MARK: - KeyboardInputPipeline

    func testCurrentSettings_ReflectsLatestSettings() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        var settings = EasyKeySettings.defaults
        settings.input.language = .english
        pipeline.update(settings: settings)
        XCTAssertEqual(pipeline.currentSettings.input.language, .english)
    }

    func testProcess_WordBoundary_SuppressedAndSessionReset() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        typeWord("as", pipeline: pipeline, keyCodes: [0, 1])
        let space = keyEvent(character: " ", keyCode: 49)
        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: space, keyCode: 49)
        XCTAssertEqual(result.disposition, .suppressed)
        XCTAssertTrue(result.suppressesOriginal)
        XCTAssertFalse(pipeline.isComposing)
    }

    func testProcess_MacroExpansionSynthesisFailure_ResetsAndPasses() {
        var settings = EasyKeySettings.defaults
        settings.macro.enabled = true
        let pipeline = KeyboardInputPipeline(
            settings: settings,
            // Pin the spotlight detector: this test exercises the physical-backspace
            // synthesis-failure path, and a visible Spotlight window (e.g. on CI
            // runners) would route macro expansion through selection replacement,
            // which never synthesizes backspace.
            spotlightVisibilityProvider: { false },
            eventFactory: { keyCode, keyDown in
                if keyCode == 51 {
                    return nil
                }
                return CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: keyDown)
            }
        )
        pipeline.update(macros: [Macro(trigger: "s", expansion: "Best regards")])

        let s = keyEvent(character: "s", keyCode: 1)
        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: s, keyCode: 1)

        let space = keyEvent(character: " ", keyCode: 49)
        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: space, keyCode: 49)

        XCTAssertEqual(result.disposition, .passed)
        XCTAssertFalse(result.suppressesOriginal)
    }

    func testProcess_AddressBarCacheHit_WithinTTL() {
        var settings = EasyKeySettings.defaults
        settings.compatibility.compatibilityModeApplicationBundleIdentifiers = ["com.test.Browser"]
        var detectorCalls = 0
        let detectorCalled = expectation(description: "address bar detector invoked")
        let pipeline = KeyboardInputPipeline(
            settings: settings,
            chromiumAddressBarDetector: {
                detectorCalls += 1
                detectorCalled.fulfill()
                return true
            }
        )
        pipeline.setActiveApplication("com.test.Browser")

        let first = keyEvent(character: "a", keyCode: 0)
        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: first, keyCode: 0)
        wait(for: [detectorCalled], timeout: 2)
        // Let the async cache-write hop land before the next lookup.
        Thread.sleep(forTimeInterval: 0.2)

        let second = keyEvent(character: "s", keyCode: 1)
        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: second, keyCode: 1)

        XCTAssertEqual(detectorCalls, 1)
        XCTAssertEqual(result.disposition, .suppressed)
    }

    func testCmdCDoublePress_TwoFastPresses_FiresHandler() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        let fired = expectation(description: "cmd-C double press")
        pipeline.setCmdCDoublePressHandler(windowMs: 400) { fired.fulfill() }

        let first = keyEvent(character: "c", keyCode: 8, flags: .maskCommand)
        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: first, keyCode: 8)
        let second = keyEvent(character: "c", keyCode: 8, flags: .maskCommand)
        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: second, keyCode: 8)

        wait(for: [fired], timeout: 1)
    }

    func testProcess_FlagsChangedModifierOnlyRestoreShortcut_WhenVietnamese() {
        var settings = EasyKeySettings.defaults
        settings.input.language = .vietnamese
        settings.typing.restoreWordShortcut = .modifiersOnly([.option])
        let pipeline = KeyboardInputPipeline(settings: settings)

        let event = keyEvent(character: "", keyCode: 0, flags: .maskAlternate)
        let result = pipeline.process(proxy: fakeProxy(), type: .flagsChanged, event: event, keyCode: nil)

        XCTAssertEqual(result.disposition, .passed)
    }

    func testProcess_RestoreWordShortcutSynthesisFailure_ResetsAndPasses() {
        var settings = EasyKeySettings.defaults
        settings.typing.restoreWordShortcut = Shortcut(keyCode: 10, modifiers: [.option])
        // Stateful factory: fail backspace synthesis only after the composition
        // is built, so apply() fails at restore time instead of during typing.
        var failBackspace = false
        let pipeline = KeyboardInputPipeline(
            settings: settings,
            // Pin the spotlight detector: this test exercises the physical-backspace
            // synthesis-failure path, and a visible Spotlight window (e.g. on CI
            // runners) would route restore through selection replacement, which
            // never synthesizes backspace.
            spotlightVisibilityProvider: { false },
            eventFactory: { keyCode, keyDown in
                if failBackspace, keyCode == 51 {
                    return nil
                }
                return CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: keyDown)
            }
        )

        typeWord("as", pipeline: pipeline, keyCodes: [0, 1])
        failBackspace = true
        let restore = keyEvent(character: "", keyCode: 10, flags: .maskAlternate)
        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: restore, keyCode: 10)

        XCTAssertEqual(result.disposition, .passed)
        XCTAssertFalse(result.suppressesOriginal)
    }

    func testProcess_VSCodeWorkaround_InsertsAlternateEmptyCharacter() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        pipeline.setActiveApplication("com.microsoft.VSCode")

        typeWord("as", pipeline: pipeline, keyCodes: [0, 1])
        let space = keyEvent(character: " ", keyCode: 49)
        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: space, keyCode: 49)

        XCTAssertEqual(result.disposition, .suppressed)
    }

    func testProcess_BasicVietnameseTyping_Suppresses() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        let a = keyEvent(character: "a", keyCode: 0)
        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: a, keyCode: 0)
        XCTAssertEqual(result.disposition, .suppressed)
    }

    func testProcess_EmergencyShortcut_SuppressesAndTogglesPause() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        let toggled = expectation(description: "toggle pause")
        pipeline.onTogglePause = { toggled.fulfill() }

        let shortcut = KeyboardService.defaultEmergencyPauseShortcut
        let event = keyEvent(
            character: "",
            keyCode: shortcut.keyCode,
            flags: [.maskControl, .maskAlternate, .maskCommand]
        )
        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: shortcut.keyCode)

        XCTAssertEqual(result.disposition, .suppressed)
        wait(for: [toggled], timeout: 1)
    }

    func testProcess_MouseEvent_ResetsAndPasses() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        typeWord("as", pipeline: pipeline, keyCodes: [0, 1])
        let event = keyEvent(character: "", keyCode: 0)
        let result = pipeline.process(proxy: fakeProxy(), type: .leftMouseDown, event: event, keyCode: nil)
        XCTAssertEqual(result.disposition, .passed)
        XCTAssertFalse(pipeline.isComposing)
    }

    func testProcess_EnglishLanguage_Bypasses() {
        var settings = EasyKeySettings.defaults
        settings.input.language = .english
        let pipeline = KeyboardInputPipeline(settings: settings)
        let event = keyEvent(character: "a", keyCode: 0)
        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: 0)
        XCTAssertEqual(result.disposition, .bypassed)
    }

    func testProcess_KeyUpEvent_Passes() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        let event = keyEvent(character: "a", keyCode: 0)
        let result = pipeline.process(proxy: fakeProxy(), type: .keyUp, event: event, keyCode: 0)
        XCTAssertEqual(result.disposition, .passed)
    }

    func testUpdate_SettingsChange_ReconfiguresEngine() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        var settings = EasyKeySettings.defaults
        settings.input.inputMethod = .vni
        pipeline.update(settings: settings)
        XCTAssertEqual(pipeline.currentSettings.input.inputMethod, .vni)
    }

    func testUpdateMacros_DoesNotCrash() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        pipeline.update(macros: [])
    }

    func testIsComposing_AfterTyping_True() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        XCTAssertFalse(pipeline.isComposing)
        typeWord("as", pipeline: pipeline, keyCodes: [0, 1])
        XCTAssertTrue(pipeline.isComposing)
    }

    func testSetActiveApplication_UpdatesBundleSnapshot() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        pipeline.setActiveApplication("com.apple.Safari")
        XCTAssertEqual(pipeline.activeApplicationBundleIdentifier, "com.apple.Safari")
    }

    func testSetUsesForeignInputSource_ResetsSession() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        pipeline.setUsesForeignInputSource(true)
        pipeline.setUsesForeignInputSource(false)
    }

    func testNormalize_BuildsKeyEventWithModifiers() {
        let event = keyEvent(character: "a", keyCode: 0, flags: [.maskShift, .maskCommand])
        let normalized = KeyboardInputPipeline.normalize(event: event, keyCode: 0)
        XCTAssertTrue(normalized.shift)
        XCTAssertTrue(normalized.command)
        XCTAssertEqual(normalized.kind, .character("a"))
    }

    func testNormalize_SpecialKeyCode_MapsToKind() {
        let event = keyEvent(character: "", keyCode: 51)
        let normalized = KeyboardInputPipeline.normalize(event: event, keyCode: 51)
        XCTAssertEqual(normalized.kind, .backspace)
    }

    func testKeyCodeFromEvent_Valid() {
        let event = keyEvent(character: "a", keyCode: 51)
        XCTAssertEqual(KeyboardInputPipeline.keyCode(from: event), 51)
    }

    func testShouldBreakAutocomplete_Combinations() {
        XCTAssertTrue(KeyboardInputPipeline.shouldBreakAutocomplete(inChromiumAddressBar: true, isSpotlight: false, deleteCount: 1))
        XCTAssertFalse(KeyboardInputPipeline.shouldBreakAutocomplete(inChromiumAddressBar: false, isSpotlight: true, deleteCount: 0))
        XCTAssertFalse(KeyboardInputPipeline.shouldBreakAutocomplete(inChromiumAddressBar: false, isSpotlight: false, deleteCount: 5))
    }

    func testEngineConfiguration_UnicodeCombiningRuleOverridesEncoding() {
        let rule = AppCompatibilityRule(bundleIdentifier: "com.apple.Safari", workarounds: [.unicodeCombiningOutput])
        var settings = EasyKeySettings.defaults
        settings.input.encoding = .unicode
        let config = KeyboardInputPipeline.engineConfiguration(for: settings, rule: rule)
        XCTAssertEqual(config.outputEncoding, .unicodeCombining)
    }

    func testIsCurrentInputSourceForeign_DoesNotCrash() {
        _ = KeyboardInputPipeline.isCurrentInputSourceForeign()
    }

    // MARK: - KeyboardService

    func testStart_HealthReflectsInstallOutcome() {
        let service = KeyboardService(settings: .defaults)
        service.start()
        XCTAssertNotEqual(service.health, .stopped)
        service.stop()
        XCTAssertEqual(service.health, .stopped)
    }

    func testStart_WhenTapAlreadyInstalled_SetsActive() {
        let service = KeyboardService(settings: .defaults)
        service.start()
        guard service.health == .active else { return }
        service.start()
        XCTAssertEqual(service.health, .active)
    }

    func testSleepNotification_TearsDownTapAndDegrades() {
        let service = KeyboardService(settings: .defaults)
        service.start()
        let degraded = expectation(description: "degraded on sleep")
        service.healthHandler = { health in
            if health == .degraded {
                degraded.fulfill()
            }
        }
        NSWorkspace.shared.notificationCenter.post(name: NSWorkspace.willSleepNotification, object: nil)
        wait(for: [degraded], timeout: 2)
    }

    func testWakeNotification_RefreshesPermission() {
        let service = KeyboardService(settings: .defaults)
        service.start()
        let refreshed = expectation(description: "health handler after wake")
        var callbackCount = 0
        service.healthHandler = { _ in
            callbackCount += 1
            if callbackCount == 1 {
                refreshed.fulfill()
            }
        }
        NSWorkspace.shared.notificationCenter.post(name: NSWorkspace.didWakeNotification, object: nil)
        wait(for: [refreshed], timeout: 2)
    }

    func testRequestAccessibilityPermission_WhenTrusted_Starts() {
        let service = KeyboardService(settings: .defaults)
        service.requestAccessibilityPermission()
        XCTAssertNotEqual(service.health, .stopped)
    }

    func testRefreshPermission_WhenNotPaused_StartsIfPermitted() {
        let service = KeyboardService(settings: .defaults)
        service.refreshPermission()
        XCTAssertNotEqual(service.health, .stopped)
    }

    func testSetCmdCDoublePressHandler_DoesNotCrash() {
        let service = KeyboardService(settings: .defaults)
        service.setCmdCDoublePressHandler(windowMs: 400) {}
        service.clearCmdCDoublePressHandler()
    }

    func testHandleTapEvent_SelfPostedEvent_PassesThrough() {
        let service = KeyboardService(settings: .defaults)
        guard let event = CGEvent(source: nil) else {
            XCTFail("Could not create event")
            return
        }
        KeySynthesizer.markAsSelfPosted(event)

        let result = service.handleTapEvent(proxy: fakeProxy(), type: .keyDown, event: event)

        XCTAssertNotNil(result)
    }

    func testHandleTapEvent_TapDisabledByTimeout_RecoversToDegraded() {
        let service = KeyboardService(settings: .defaults)
        let degraded = expectation(description: "recovered degraded")
        service.healthHandler = { health in
            if health == .degraded {
                degraded.fulfill()
            }
        }
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) else {
            XCTFail("Could not create event")
            return
        }

        _ = service.handleTapEvent(proxy: fakeProxy(), type: .tapDisabledByTimeout, event: event)

        wait(for: [degraded], timeout: 2)
    }

    func testHandleTapEvent_SwitchShortcut_SuppressesOriginal() {
        var settings = EasyKeySettings.defaults
        settings.input.switchShortcut = Shortcut(keyCode: 49, modifiers: [.control, .command])
        let service = KeyboardService(settings: settings)
        let event = keyEvent(character: "", keyCode: 49, flags: [.maskControl, .maskCommand])

        let result = service.handleTapEvent(proxy: fakeProxy(), type: .keyDown, event: event)

        XCTAssertNil(result)
    }

    func testEncodedUnitCountForTesting_AfterTyping() {
        var settings = EasyKeySettings.defaults
        settings.typing.liveConfidenceScoring = true
        let pipeline = KeyboardInputPipeline(settings: settings)
        typeWord("str", pipeline: pipeline, keyCodes: [1, 17, 15])
        XCTAssertEqual(pipeline.encodedUnitCountForTesting, 3)
    }

    func testProcess_IgnoredApplication_BypassesAndResets() {
        var settings = EasyKeySettings.defaults
        settings.compatibility.ignoredApplicationBundleIdentifiers = ["com.ignored.App"]
        let pipeline = KeyboardInputPipeline(settings: settings)
        pipeline.setActiveApplication("com.ignored.App")
        typeWord("as", pipeline: pipeline, keyCodes: [0, 1])

        let event = keyEvent(character: "a", keyCode: 0)
        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: 0)

        XCTAssertEqual(result.disposition, .bypassed)
        XCTAssertFalse(pipeline.isComposing)
    }

    func testProcess_SynthesisFailure_PassesOriginalAndResets() {
        let pipeline = KeyboardInputPipeline(
            settings: .defaults,
            eventFactory: { _, _ in nil }
        )
        let event = keyEvent(character: "a", keyCode: 0)
        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: event, keyCode: 0)
        XCTAssertEqual(result.disposition, .passed)
        XCTAssertFalse(result.suppressesOriginal)
    }

    func testProcess_MacroExpansionSuccess_ResetsEncodedUnits() {
        var settings = EasyKeySettings.defaults
        settings.macro.enabled = true
        let pipeline = KeyboardInputPipeline(settings: settings)
        pipeline.update(macros: [Macro(trigger: "s", expansion: "Best regards")])

        let s = keyEvent(character: "s", keyCode: 1)
        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: s, keyCode: 1)
        let space = keyEvent(character: " ", keyCode: 49)
        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: space, keyCode: 49)

        XCTAssertEqual(result.disposition, .suppressed)
        XCTAssertTrue(result.suppressesOriginal)
    }

    func testCmdCDoublePress_InterveningKey_ResetsTimestamp() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        var activated = false
        pipeline.setCmdCDoublePressHandler(windowMs: 400) { activated = true }

        let c1 = keyEvent(character: "c", keyCode: 8, flags: .maskCommand)
        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: c1, keyCode: 8)
        let v = keyEvent(character: "v", keyCode: 9, flags: .maskCommand)
        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: v, keyCode: 9)
        let c2 = keyEvent(character: "c", keyCode: 8, flags: .maskCommand)
        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: c2, keyCode: 8)

        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        XCTAssertFalse(activated)
    }

    func testProcess_FlagsChangedModifierOnlySwitchShortcut_TogglesLanguage() {
        var settings = EasyKeySettings.defaults
        settings.input.switchShortcut = .modifiersOnly([.option])
        let pipeline = KeyboardInputPipeline(settings: settings)
        let toggled = expectation(description: "language toggle via flags changed")
        pipeline.onLanguageToggleRequested = { language in
            XCTAssertEqual(language, .english)
            toggled.fulfill()
        }

        let event = keyEvent(character: "", keyCode: 0, flags: .maskAlternate)
        let result = pipeline.process(proxy: fakeProxy(), type: .flagsChanged, event: event, keyCode: nil)

        XCTAssertEqual(result.disposition, .suppressed)
        wait(for: [toggled], timeout: 1)
    }

    func testProcess_FlagsChangedNoMatch_InvalidatesAndResetsComposition() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        typeWord("as", pipeline: pipeline, keyCodes: [0, 1])
        XCTAssertTrue(pipeline.isComposing)

        let event = keyEvent(character: "", keyCode: 200, flags: [])
        let result = pipeline.process(proxy: fakeProxy(), type: .flagsChanged, event: event, keyCode: 200)

        XCTAssertEqual(result.disposition, .passed)
        XCTAssertFalse(pipeline.isComposing)
    }

    func testProcess_RestoreRawKeysSuccess_SuppressedWithOutput() {
        var settings = EasyKeySettings.defaults
        settings.typing.restoreWordShortcut = Shortcut(keyCode: 10, modifiers: [.option])
        let pipeline = KeyboardInputPipeline(settings: settings)
        typeWord("as", pipeline: pipeline, keyCodes: [0, 1])

        let restore = keyEvent(character: "", keyCode: 10, flags: .maskAlternate)
        let result = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: restore, keyCode: 10)

        XCTAssertEqual(result.disposition, .suppressed)
        XCTAssertTrue(result.suppressesOriginal)
    }

    func testStart_WhilePaused_SetsStopped() {
        let service = KeyboardService(settings: .defaults)
        service.setPaused(true)
        service.start()
        XCTAssertEqual(service.health, .stopped)
    }

    func testHandleTapEvent_SwitchShortcut_ForwardsLanguageToggle() {
        var settings = EasyKeySettings.defaults
        settings.input.switchShortcut = Shortcut(keyCode: 49, modifiers: [.control, .command])
        let service = KeyboardService(settings: settings)
        let toggled = expectation(description: "language toggle via service")
        service.languageToggleHandler = { language in
            XCTAssertEqual(language, .english)
            toggled.fulfill()
        }

        let event = keyEvent(character: "", keyCode: 49, flags: [.maskControl, .maskCommand])
        _ = service.handleTapEvent(proxy: fakeProxy(), type: .keyDown, event: event)

        wait(for: [toggled], timeout: 2)
    }

    func testTogglePause_CyclesPauseState() {
        let service = KeyboardService(settings: .defaults)
        var pauseStates: [Bool] = []
        service.pauseHandler = { pauseStates.append($0) }

        service.togglePause()
        service.togglePause()

        XCTAssertEqual(pauseStates, [true, false])
    }

    func testSetActiveApplication_NilBundle_DoesNotCrash() {
        let service = KeyboardService(settings: .defaults)
        service.setActiveApplication(nil)
    }

    func testUpdateAndReset_DoesNotCrash() {
        let service = KeyboardService(settings: .defaults)
        service.update(settings: .defaults)
        service.update(macros: [])
        service.resetSession()
        XCTAssertNil(service.medianCallbackLatencyNanoseconds())
    }

    func testIsComposing_ViaService_ReflectsPipeline() {
        let service = KeyboardService(settings: .defaults)
        let event = keyEvent(character: "a", keyCode: 0)
        _ = service.handleTapEvent(proxy: fakeProxy(), type: .keyDown, event: event)
        _ = service.isComposing
    }

    // MARK: - KeyboardEventTap

    func testInstall_WithBoundService_InstallsAndTearsDown() {
        let tap = KeyboardEventTap(eventMask: KeyboardInputPipeline.makeEventMask())
        let service = KeyboardService(settings: .defaults)
        tap.bind(to: service)
        let installed = tap.install()
        XCTAssertEqual(tap.isInstalled, installed)
        tap.tearDown()
        XCTAssertFalse(tap.isInstalled)
    }

    func testInstall_WithoutBoundService_ReturnsFalse() {
        let tap = KeyboardEventTap(eventMask: KeyboardInputPipeline.makeEventMask())
        XCTAssertFalse(tap.install())
    }

    func testTearDown_WhenNotInstalled_DoesNotCrash() {
        let tap = KeyboardEventTap(eventMask: KeyboardInputPipeline.makeEventMask())
        tap.tearDown()
        XCTAssertFalse(tap.isInstalled)
    }

    func testInstallWorkspaceObserversIfNeeded_OnlyInstallsOnce() {
        let tap = KeyboardEventTap(eventMask: KeyboardInputPipeline.makeEventMask())
        var sleepCount = 0
        var wakeCount = 0
        tap.installWorkspaceObserversIfNeeded(onSleep: { sleepCount += 1 }, onWake: { wakeCount += 1 })
        tap.installWorkspaceObserversIfNeeded(onSleep: { sleepCount += 1 }, onWake: { wakeCount += 1 })
        XCTAssertEqual(sleepCount, 0)
        XCTAssertEqual(wakeCount, 0)
    }

    func testKeyboardEventTapCallback_NilUserInfo_ReturnsEvent() {
        let event = keyEvent(character: "a", keyCode: 0)
        let result = keyboardEventTapCallback(proxy: fakeProxy(), type: .keyDown, event: event, userInfo: nil)
        XCTAssertNotNil(result)
    }

    func testKeyboardEventTapCallback_WithBoundService_Dispatches() {
        let service = KeyboardService(settings: .defaults)
        let event = keyEvent(character: "a", keyCode: 0)
        let userInfo = Unmanaged.passUnretained(service).toOpaque()
        _ = keyboardEventTapCallback(proxy: fakeProxy(), type: .keyDown, event: event, userInfo: userInfo)
    }

    // MARK: - SpotlightWindowDetector

    func testIsSpotlightWindowVisible_DoesNotCrash() {
        _ = SpotlightWindowDetector.isSpotlightWindowVisible()
    }
}
