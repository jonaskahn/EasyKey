import Carbon.HIToolbox
import CoreGraphics
@testable import EasyEngineCore
@testable import EasyKeyKit
import XCTest

final class CommandCDoublePressBoundaryTests: XCTestCase {
    private func fakeProxy() -> CGEventTapProxy {
        unsafeBitCast(UInt(0), to: CGEventTapProxy.self)
    }

    private func cmdC(at timestamp: UInt64, extraFlags: CGEventFlags = []) -> CGEvent {
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: true) else {
            fatalError("Could not create event")
        }
        event.setIntegerValueField(.keyboardEventKeycode, value: Int64(kVK_ANSI_C))
        event.flags = CGEventFlags.maskCommand.union(extraFlags)
        event.timestamp = timestamp
        return event
    }

    private func keyEvent(_ keyCode: UInt16, at timestamp: UInt64) -> CGEvent {
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(keyCode), keyDown: true) else {
            fatalError("Could not create event")
        }
        event.setIntegerValueField(.keyboardEventKeycode, value: Int64(keyCode))
        event.timestamp = timestamp
        return event
    }

    func testDoublePress_ExactlyAtWindowBoundary_Fires() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        let fired = expectation(description: "double press fired")
        pipeline.setCmdCDoublePressHandler(windowMs: 400) {
            XCTAssertTrue(Thread.isMainThread)
            fired.fulfill()
        }

        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: cmdC(at: 0), keyCode: UInt16(kVK_ANSI_C))
        _ = pipeline.process(
            proxy: fakeProxy(),
            type: .keyDown,
            event: cmdC(at: 400_000_000),
            keyCode: UInt16(kVK_ANSI_C)
        )

        waitForExpectations(timeout: 1.0)
    }

    func testDoublePress_OneNanosecondOutsideWindow_DoesNotFire() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        var fired = false
        pipeline.setCmdCDoublePressHandler(windowMs: 400) {
            fired = true
        }

        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: cmdC(at: 0), keyCode: UInt16(kVK_ANSI_C))
        _ = pipeline.process(
            proxy: fakeProxy(),
            type: .keyDown,
            event: cmdC(at: 400_000_001),
            keyCode: UInt16(kVK_ANSI_C)
        )

        XCTAssertFalse(fired)
    }

    func testInterveningKey_ResetsTimestamp_SoOnlyLaterPairFires() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        let fired = expectation(description: "second pair fired")
        var fireCount = 0
        pipeline.setCmdCDoublePressHandler(windowMs: 400) {
            fireCount += 1
            fired.fulfill()
        }

        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: cmdC(at: 0), keyCode: UInt16(kVK_ANSI_C))
        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: keyEvent(1, at: 100_000_000), keyCode: 1)
        _ = pipeline.process(
            proxy: fakeProxy(),
            type: .keyDown,
            event: cmdC(at: 200_000_000),
            keyCode: UInt16(kVK_ANSI_C)
        )
        _ = pipeline.process(
            proxy: fakeProxy(),
            type: .keyDown,
            event: cmdC(at: 300_000_000),
            keyCode: UInt16(kVK_ANSI_C)
        )

        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(fireCount, 1)
    }

    func testCmdOptionC_DoesNotCountTowardDoublePress() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        var fired = false
        pipeline.setCmdCDoublePressHandler(windowMs: 400) {
            fired = true
        }

        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: cmdC(at: 0), keyCode: UInt16(kVK_ANSI_C))
        _ = pipeline.process(
            proxy: fakeProxy(),
            type: .keyDown,
            event: cmdC(at: 100_000_000, extraFlags: .maskAlternate),
            keyCode: UInt16(kVK_ANSI_C)
        )
        _ = pipeline.process(
            proxy: fakeProxy(),
            type: .keyDown,
            event: cmdC(at: 200_000_000),
            keyCode: UInt16(kVK_ANSI_C)
        )

        XCTAssertFalse(fired, "option-modified C resets the timestamp, so the later C starts a fresh window")
    }

    func testClearHandler_DisablesDetection() {
        let pipeline = KeyboardInputPipeline(settings: .defaults)
        var fired = false
        pipeline.setCmdCDoublePressHandler(windowMs: 400) {
            fired = true
        }
        pipeline.clearCmdCDoublePressHandler()

        _ = pipeline.process(proxy: fakeProxy(), type: .keyDown, event: cmdC(at: 0), keyCode: UInt16(kVK_ANSI_C))
        _ = pipeline.process(
            proxy: fakeProxy(),
            type: .keyDown,
            event: cmdC(at: 100_000_000),
            keyCode: UInt16(kVK_ANSI_C)
        )

        XCTAssertFalse(fired)
    }
}
