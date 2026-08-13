import CoreGraphics
@testable import EasyEngineCore
@testable import EasyKeyKit
import XCTest

final class KeyboardPipelineCacheTimingTests: XCTestCase {
    private func fakeProxy() -> CGEventTapProxy {
        unsafeBitCast(UInt(0), to: CGEventTapProxy.self)
    }

    private func keyEvent(character: String, keyCode: UInt16) -> CGEvent {
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

    private func expandMacro(trigger: String, in pipeline: KeyboardInputPipeline) {
        pipeline.update(macros: [Macro(trigger: trigger, expansion: "expanded")])
        for (character, keyCode) in zip(trigger, [UInt16(1), 34, 5]) {
            _ = pipeline.process(
                proxy: fakeProxy(),
                type: .keyDown,
                event: keyEvent(character: String(character), keyCode: keyCode),
                keyCode: keyCode
            )
        }
        let delimiter = keyEvent(character: " ", keyCode: 49)
        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: delimiter, keyCode: 49)
    }

    func testSpotlightCache_ProviderCalledOnFirstUseThenCachedUntilTTL() {
        var time: CFAbsoluteTime = 0
        let lock = NSLock()
        var providerCalls = 0
        let pipeline = KeyboardInputPipeline(
            settings: .defaults,
            spotlightVisibilityProvider: {
                lock.lock()
                providerCalls += 1
                lock.unlock()
                return true
            },
            now: { time }
        )

        expandMacro(trigger: "sig", in: pipeline)
        XCTAssertEqual(providerCalls, 1)

        time = 0.299_999
        expandMacro(trigger: "sig", in: pipeline)
        XCTAssertEqual(providerCalls, 1, "cache stays fresh strictly inside the TTL")

        time = 0.3
        expandMacro(trigger: "sig", in: pipeline)
        XCTAssertEqual(providerCalls, 2, "exactly at the TTL the cache expires and the provider runs again")
    }

    func testSpotlightCache_SecondUseAfterExpiryCachesAgain() {
        var time: CFAbsoluteTime = 0
        let lock = NSLock()
        var providerCalls = 0
        let pipeline = KeyboardInputPipeline(
            settings: .defaults,
            spotlightVisibilityProvider: {
                lock.lock()
                providerCalls += 1
                lock.unlock()
                return false
            },
            now: { time }
        )

        expandMacro(trigger: "sig", in: pipeline)
        XCTAssertEqual(providerCalls, 1)

        time = 0.5
        expandMacro(trigger: "sig", in: pipeline)
        XCTAssertEqual(providerCalls, 2)

        time = 0.5 + 0.299_999
        expandMacro(trigger: "sig", in: pipeline)
        XCTAssertEqual(providerCalls, 2, "refresh at 0.5 re-caches until 0.8")
    }

    func testChromiumCache_FirstMissReturnsFalseAndStartsOneRefresh() {
        var time: CFAbsoluteTime = 0
        let detectorCalled = expectation(description: "detector invoked")
        let release = DispatchSemaphore(value: 0)
        let lock = NSLock()
        var detectorCalls = 0

        var settings = EasyKeySettings.defaults
        settings.compatibility.compatibilityModeApplicationBundleIdentifiers = ["com.test.browser"]
        let pipeline = KeyboardInputPipeline(
            settings: settings,
            chromiumAddressBarDetector: {
                lock.lock()
                detectorCalls += 1
                lock.unlock()
                detectorCalled.fulfill()
                release.wait()
                return true
            },
            now: { time }
        )
        pipeline.setActiveApplication("com.test.browser")

        expandMacro(trigger: "sig", in: pipeline)
        wait(for: [detectorCalled], timeout: 5.0)

        lock.lock()
        let callsAfterFirstMiss = detectorCalls
        lock.unlock()
        XCTAssertEqual(callsAfterFirstMiss, 1)

        expandMacro(trigger: "sig", in: pipeline)
        lock.lock()
        let callsWhileRefreshing = detectorCalls
        lock.unlock()
        XCTAssertEqual(callsWhileRefreshing, 1, "no second refresh starts while one is in flight")

        release.signal()
    }

    func testChromiumCache_StaleCompletionAfterInvalidation_IsRejected() {
        var time: CFAbsoluteTime = 0
        let firstDetectorCall = expectation(description: "first detector call")
        let secondDetectorCall = expectation(description: "second detector call")
        let release = DispatchSemaphore(value: 0)
        let lock = NSLock()
        var detectorCalls = 0

        var settings = EasyKeySettings.defaults
        settings.compatibility.compatibilityModeApplicationBundleIdentifiers = ["com.test.browser"]
        let pipeline = KeyboardInputPipeline(
            settings: settings,
            chromiumAddressBarDetector: {
                lock.lock()
                detectorCalls += 1
                let callIndex = detectorCalls
                lock.unlock()
                if callIndex == 1 {
                    firstDetectorCall.fulfill()
                    release.wait()
                } else {
                    secondDetectorCall.fulfill()
                }
                return true
            },
            now: { time }
        )
        pipeline.setActiveApplication("com.test.browser")

        expandMacro(trigger: "sig", in: pipeline)
        wait(for: [firstDetectorCall], timeout: 5.0)

        pipeline.setActiveApplication("com.test.browser")
        release.signal()
        usleep(100_000)

        time = 0.2
        expandMacro(trigger: "sig", in: pipeline)
        wait(for: [secondDetectorCall], timeout: 5.0)

        lock.lock()
        let total = detectorCalls
        lock.unlock()
        XCTAssertEqual(total, 2, "the rejected stale completion must not satisfy the cache")
    }

    func testChromiumCache_ValueCachedWithinTTL_NoDetectorRerun() {
        var time: CFAbsoluteTime = 0
        let firstDetectorCall = expectation(description: "first detector call")
        let release = DispatchSemaphore(value: 0)
        let lock = NSLock()
        var detectorCalls = 0

        var settings = EasyKeySettings.defaults
        settings.compatibility.compatibilityModeApplicationBundleIdentifiers = ["com.test.browser"]
        let pipeline = KeyboardInputPipeline(
            settings: settings,
            chromiumAddressBarDetector: {
                lock.lock()
                detectorCalls += 1
                lock.unlock()
                firstDetectorCall.fulfill()
                release.wait()
                return true
            },
            now: { time }
        )
        pipeline.setActiveApplication("com.test.browser")

        expandMacro(trigger: "sig", in: pipeline)
        wait(for: [firstDetectorCall], timeout: 5.0)
        release.signal()
        usleep(100_000)

        time = 0.5
        expandMacro(trigger: "sig", in: pipeline)
        lock.lock()
        let total = detectorCalls
        lock.unlock()
        XCTAssertEqual(total, 1, "a completed cache value serves requests inside the 1.5s TTL")
    }
}
