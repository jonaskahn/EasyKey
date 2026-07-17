import AppKit
import EasyEngineCore
@testable import EasyKey
import SwiftUI
import XCTest

final class ShortcutKeyCaptureTests: XCTestCase {
    func testKeyCaptureView_AcceptsFirstResponder() {
        let view = KeyCaptureView()
        XCTAssertTrue(view.acceptsFirstResponder)
    }

    func testKeyDown_InvokesCaptureWithShortcut() {
        let view = KeyCaptureView()
        var captured: Shortcut?
        view.capture = { captured = $0 }

        guard let event = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [.shift],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "a",
            charactersIgnoringModifiers: "a",
            isARepeat: false,
            keyCode: 0
        )
        else {
            XCTFail("Could not create event")
            return
        }

        view.keyDown(with: event)
        XCTAssertEqual(captured?.keyCode, 0)
        XCTAssertTrue(captured?.modifiers.contains(.shift) ?? false)
    }

    func testPerformKeyEquivalent_InvokesCaptureAndReturnsTrue() {
        let view = KeyCaptureView()
        var captureCount = 0
        view.capture = { _ in captureCount += 1 }

        guard let event = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [.control, .command],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "x",
            charactersIgnoringModifiers: "x",
            isARepeat: false,
            keyCode: 7
        )
        else {
            XCTFail("Could not create event")
            return
        }

        XCTAssertTrue(view.performKeyEquivalent(with: event))
        XCTAssertEqual(captureCount, 1)
    }

    func testKeyDown_AllModifiers_MapCorrectly() {
        let view = KeyCaptureView()
        var captured: Shortcut?
        view.capture = { captured = $0 }

        guard let event = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [.shift, .control, .option, .command],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "z",
            charactersIgnoringModifiers: "z",
            isARepeat: false,
            keyCode: 6
        )
        else {
            XCTFail("Could not create event")
            return
        }

        view.keyDown(with: event)
        XCTAssertTrue(captured?.modifiers.contains(.shift) ?? false)
        XCTAssertTrue(captured?.modifiers.contains(.control) ?? false)
        XCTAssertTrue(captured?.modifiers.contains(.option) ?? false)
        XCTAssertTrue(captured?.modifiers.contains(.command) ?? false)
    }

    @MainActor
    func testShortcutKeyCapture_RendersViaHostingView() {
        struct Probe: View {
            @State private var isRecording = true
            @State private var shortcut = Shortcut.none

            var body: some View {
                ShortcutKeyCapture(isRecording: $isRecording, shortcut: $shortcut)
            }
        }
        let hostingView = NSHostingView(rootView: Probe())
        hostingView.frame = NSRect(x: 0, y: 0, width: 100, height: 40)
        hostingView.layoutSubtreeIfNeeded()
        XCTAssertNotNil(hostingView)
    }
}
