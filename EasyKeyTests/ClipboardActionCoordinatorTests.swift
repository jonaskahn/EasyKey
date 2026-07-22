import EasyEngineCore
@testable import EasyKey
import XCTest

@MainActor
final class ClipboardActionCoordinatorTests: XCTestCase {
    func testPasteImmediatelyWritesReactivatesAndSynthesizes() {
        var events: [String] = []
        let coordinator = makeCoordinator(
            write: { _ in events.append("write") },
            close: { events.append("close") },
            reactivate: { events.append("reactivate"); return true },
            synthesize: { events.append("paste"); return true }
        )
        coordinator.perform(entry(), action: .pasteImmediately)
        XCTAssertEqual(events, ["write", "close", "reactivate", "paste"])
        XCTAssertNil(coordinator.lastError)
    }

    func testCopyOnlyNeverSynthesizesPaste() {
        var pasted = false
        let coordinator = makeCoordinator(
            write: { _ in },
            close: {},
            reactivate: { true },
            synthesize: { pasted = true; return true }
        )
        coordinator.perform(entry(), action: .copyOnly)
        XCTAssertFalse(pasted)
    }

    func testExplicitCopyOnlyOverridesEvenWhenDefaultIsPaste() {
        var pasted = false
        let coordinator = makeCoordinator(write: { _ in }, close: {}, reactivate: { true }, synthesize: { pasted = true; return true })
        coordinator.copyOnly(entry())
        XCTAssertFalse(pasted)
    }

    func testUnavailableRepresentationReportsErrorAndDoesNotClose() {
        var closed = false
        let coordinator = makeCoordinator(
            write: { _ in throw PasteboardWriteError.unavailableRepresentation },
            close: { closed = true },
            reactivate: { true },
            synthesize: { true }
        )
        coordinator.perform(entry(), action: .pasteImmediately)
        XCTAssertEqual(coordinator.lastError, .unavailable)
        XCTAssertFalse(closed)
    }

    func testTerminatedTargetReportsErrorWithoutPaste() {
        var pasted = false
        let coordinator = makeCoordinator(
            write: { _ in },
            close: {},
            reactivate: { false },
            synthesize: { pasted = true; return true }
        )
        coordinator.perform(entry(), action: .pasteImmediately)
        XCTAssertEqual(coordinator.lastError, .targetTerminated)
        XCTAssertFalse(pasted)
    }

    func testAccessibilityDeniedReportsError() {
        let coordinator = makeCoordinator(write: { _ in }, close: {}, reactivate: { true }, synthesize: { false })
        coordinator.perform(entry(), action: .pasteImmediately)
        XCTAssertEqual(coordinator.lastError, .accessibilityDenied)
    }

    func testDelayedPasteRejectsChangedFocus() async throws {
        var pasted = false
        let coordinator = ClipboardActionCoordinator(
            writeEntry: { _ in },
            closePanel: {},
            reactivatePrevious: { true },
            synthesizePaste: { pasted = true; return true },
            isTargetFocused: { false },
            pasteDelay: .milliseconds(10)
        )

        coordinator.perform(entry(), action: .pasteImmediately)
        try await Task.sleep(for: .milliseconds(30))

        XCTAssertFalse(pasted)
        XCTAssertEqual(coordinator.lastError, .focusChanged)
    }

    func testNewActionCancelsDelayedPaste() async throws {
        var pasted = false
        let coordinator = ClipboardActionCoordinator(
            writeEntry: { _ in },
            closePanel: {},
            reactivatePrevious: { true },
            synthesizePaste: { pasted = true; return true },
            pasteDelay: .milliseconds(20)
        )

        coordinator.perform(entry(), action: .pasteImmediately)
        coordinator.perform(entry(), action: .copyOnly)
        try await Task.sleep(for: .milliseconds(40))

        XCTAssertFalse(pasted)
    }

    private func makeCoordinator(
        write: @escaping (ClipboardEntry) throws -> Void,
        close: @escaping () -> Void,
        reactivate: @escaping () -> Bool,
        synthesize: @escaping () -> Bool
    ) -> ClipboardActionCoordinator {
        ClipboardActionCoordinator(writeEntry: write, closePanel: close, reactivatePrevious: reactivate, synthesizePaste: synthesize)
    }

    private func entry() -> ClipboardEntry {
        let item = ClipboardItem(
            kind: .text,
            preview: ClipboardItemPreview(primaryText: "hi"),
            representations: [.string(typeIdentifier: "public.utf8-plain-text", value: "hi")]
        )
        return ClipboardEntry(fingerprint: "f", capturedAt: Date(), items: [item])
    }
}
