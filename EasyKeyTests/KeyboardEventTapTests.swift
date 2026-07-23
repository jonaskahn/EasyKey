import CoreGraphics
@testable import EasyKeyKit
import XCTest

@MainActor
final class KeyboardEventTapTests: XCTestCase {
    func testInit_NotInstalled() {
        let tap = KeyboardEventTap(eventMask: KeyboardInputPipeline.makeEventMask())
        XCTAssertFalse(tap.isInstalled)
    }

    func testBind_ThenInstall_ReturnsBoolWithoutCrashing() {
        let tap = KeyboardEventTap(eventMask: KeyboardInputPipeline.makeEventMask())
        let service = KeyboardService(settings: .defaults)
        tap.bind(to: service)
        _ = tap.install()
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

    func testTearDown_AfterInstallAttempt_ClearsInstalledFlag() {
        let tap = KeyboardEventTap(eventMask: KeyboardInputPipeline.makeEventMask())
        let service = KeyboardService(settings: .defaults)
        tap.bind(to: service)
        _ = tap.install()
        tap.tearDown()
        XCTAssertFalse(tap.isInstalled)
    }

    func testInstallWorkspaceObserversIfNeeded_CalledTwice_OnlyInstallsOnce() {
        let tap = KeyboardEventTap(eventMask: KeyboardInputPipeline.makeEventMask())
        var sleepCount = 0
        var wakeCount = 0
        tap.installWorkspaceObserversIfNeeded(onSleep: { sleepCount += 1 }, onWake: { wakeCount += 1 })
        tap.installWorkspaceObserversIfNeeded(onSleep: { sleepCount += 1 }, onWake: { wakeCount += 1 })
        XCTAssertEqual(sleepCount, 0)
        XCTAssertEqual(wakeCount, 0)
    }

    func testKeyboardEventTapCallback_WithNilUserInfo_ReturnsSameEvent() {
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) else {
            XCTFail("Could not create event")
            return
        }
        let proxy = unsafeBitCast(UInt(0), to: CGEventTapProxy.self)
        let result = keyboardEventTapCallback(proxy: proxy, type: .keyDown, event: event, userInfo: nil)
        XCTAssertNotNil(result)
    }

    func testKeyboardEventTapCallback_WithBoundService_Dispatches() {
        let service = KeyboardService(settings: .defaults)
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) else {
            XCTFail("Could not create event")
            return
        }
        let proxy = unsafeBitCast(UInt(0), to: CGEventTapProxy.self)
        let userInfo = Unmanaged.passUnretained(service).toOpaque()
        _ = keyboardEventTapCallback(proxy: proxy, type: .keyDown, event: event, userInfo: userInfo)
    }
}
