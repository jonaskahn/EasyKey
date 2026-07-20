@testable import EasyEngineCore
@testable import EasyKeyKit
import XCTest

final class KeyboardServiceIntegrationTests: XCTestCase {
    func testInit_DefaultSettings_HealthIsStopped() {
        let service = KeyboardService(settings: .defaults)
        XCTAssertEqual(service.health, .stopped)
    }

    func testSetPaused_WhenToggled_EmitsPauseHandler() {
        let service = KeyboardService(settings: .defaults)
        var pauseStates: [Bool] = []
        service.pauseHandler = { pauseStates.append($0) }

        service.setPaused(true)
        XCTAssertTrue(pauseStates.contains(true))

        service.setPaused(false)
        XCTAssertTrue(pauseStates.contains(false))
    }

    func testTogglePause_CalledTwice_CyclesPausedThenResumed() {
        let service = KeyboardService(settings: .defaults)
        var pauseStates: [Bool] = []
        service.pauseHandler = { pauseStates.append($0) }

        service.togglePause()
        service.togglePause()
        XCTAssertEqual(pauseStates, [true, false])
    }

    func testSetPaused_SameState_DoesNotEmit() {
        let service = KeyboardService(settings: .defaults)
        var pauseCount = 0
        service.pauseHandler = { _ in pauseCount += 1 }

        service.setPaused(false)
        XCTAssertEqual(pauseCount, 0)
    }

    func testMedianCallbackLatencyNanoseconds_EmptyBuffer_ReturnsNil() {
        let service = KeyboardService(settings: .defaults)
        XCTAssertNil(service.medianCallbackLatencyNanoseconds())
    }

    func testUpdate_ValidSettings_DoesNotCrash() {
        let service = KeyboardService(settings: .defaults)
        var updated = EasyKeySettings.defaults
        updated.input.inputMethod = .vni
        updated.input.encoding = .tcvn3
        service.update(settings: updated)
    }

    func testSetActiveApplication_BundleOrNil_DoesNotCrash() {
        let service = KeyboardService(settings: .defaults)
        service.setActiveApplication("com.apple.Safari")
        service.setActiveApplication(nil)
    }

    func testResetSession_WhenCalled_DoesNotCrash() {
        let service = KeyboardService(settings: .defaults)
        service.resetSession()
    }

    func testRefreshInputSource_WhenCalled_DoesNotCrash() {
        let service = KeyboardService(settings: .defaults)
        service.refreshInputSource()
    }

    func testStop_WhenAlreadyStopped_RemainsStopped() {
        let service = KeyboardService(settings: .defaults)
        service.stop()
        XCTAssertEqual(service.health, .stopped)
    }

    func testDefaultEmergencyPauseShortcut_BuiltIn_IsActiveWithControlOptionCommand() {
        let shortcut = KeyboardService.defaultEmergencyPauseShortcut
        XCTAssertTrue(shortcut.isActive)
        XCTAssertTrue(shortcut.modifiers.contains(.control))
        XCTAssertTrue(shortcut.modifiers.contains(.option))
        XCTAssertTrue(shortcut.modifiers.contains(.command))
    }

    func testRequestAccessibilityPermission_DoesNotCrash() {
        let service = KeyboardService(settings: .defaults)
        service.requestAccessibilityPermission()
    }

    func testRefreshPermission_DoesNotCrash() {
        let service = KeyboardService(settings: .defaults)
        service.refreshPermission()
    }

    func testHealthHandler_EmitsOnHealthChange() {
        let service = KeyboardService(settings: .defaults)
        var healths: [KeyboardService.Health] = []
        service.healthHandler = { healths.append($0) }
        service.setPaused(true)
        XCTAssertTrue(healths.contains(.stopped))
    }

    func testSetHealthOnBackgroundThread_DoesNotCrash() {
        let service = KeyboardService(settings: .defaults)
        let exp = expectation(description: "background")
        DispatchQueue.global().async {
            service.togglePause()
            service.setPaused(true)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2)
    }

    func testHandleTapEvent_NormalKeyDown_CanBeCalled() {
        let service = KeyboardService(settings: .defaults)
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)
        else { XCTFail("normal key event"); return }
        event.setIntegerValueField(.keyboardEventKeycode, value: 0)
        let uni: [UniChar] = [97]
        event.keyboardSetUnicodeString(stringLength: 1, unicodeString: uni)
        let result = service.handleTapEvent(proxy: fakeProxy(), type: .keyDown, event: event)
        _ = result
    }

    func testHandleTapEvent_TapDisabledByTimeout_ReturnsPassUnretained() {
        let service = KeyboardService(settings: .defaults)
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)
        else { XCTFail("tapTimeout event"); return }
        event.setIntegerValueField(.eventSourceUserData, value: 0)
        let result = service.handleTapEvent(proxy: fakeProxy(), type: .tapDisabledByTimeout, event: event)
        XCTAssertNotNil(result)
    }

    func testHandleTapEvent_TapDisabledByUserInput_ReturnsPassUnretained() {
        let service = KeyboardService(settings: .defaults)
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)
        else { XCTFail("tapDisabled event"); return }
        event.setIntegerValueField(.eventSourceUserData, value: 0)
        let result = service.handleTapEvent(proxy: fakeProxy(), type: .tapDisabledByUserInput, event: event)
        XCTAssertNotNil(result)
    }

    func testHandleTapEvent_SwitchShortcut_ForwardsLanguageToggleHandler() {
        var settings = EasyKeySettings.defaults
        settings.input.switchShortcut = Shortcut(keyCode: 49, modifiers: [.control, .command])
        let service = KeyboardService(settings: settings)
        let exp = expectation(description: "language toggled")
        var toggled: [InputLanguage] = []
        service.languageToggleHandler = { language in
            toggled.append(language)
            exp.fulfill()
        }

        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 49, keyDown: true)
        else { XCTFail("switch shortcut event"); return }
        event.flags = [.maskControl, .maskCommand]
        _ = service.handleTapEvent(proxy: fakeProxy(), type: .keyDown, event: event)

        wait(for: [exp], timeout: 2)
        XCTAssertEqual(toggled, [.english])
    }

    func testHandleTapEvent_TapDisabledByTimeout_RecoversAndDegradesHealth() {
        let service = KeyboardService(settings: .defaults)
        let exp = expectation(description: "health degraded")
        service.healthHandler = { health in
            if health == .degraded {
                exp.fulfill()
            }
        }

        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)
        else { XCTFail("tapTimeout event"); return }
        event.setIntegerValueField(.eventSourceUserData, value: 0)
        _ = service.handleTapEvent(proxy: fakeProxy(), type: .tapDisabledByTimeout, event: event)

        wait(for: [exp], timeout: 2)
    }

    func testStart_WhilePaused_SkipsInstallWithoutCrashing() {
        let service = KeyboardService(settings: .defaults)
        service.setPaused(true)
        service.start()
        XCTAssertEqual(service.health, .stopped)
    }

    private func fakeProxy() -> CGEventTapProxy {
        unsafeBitCast(UInt(0), to: CGEventTapProxy.self)
    }
}
