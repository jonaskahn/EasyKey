import AppKit
@testable import EasyKey
import XCTest

final class SelectedTextSimulatorTests: XCTestCase {
    private var pasteboard: FakeSelectedTextPasteboard!
    private var simulator: SystemSelectedTextSimulator!

    override func setUpWithError() throws {
        pasteboard = FakeSelectedTextPasteboard()
        simulator = SystemSelectedTextSimulator(
            pasteboard: pasteboard,
            eventSource: nil,
            activationTimeBudget: 0.05
        )
    }

    func testCopySelection_ReturnsNilWhenEventSourceIsNil() {
        let result = simulator.copySelection(from: nil)
        XCTAssertNil(result)
    }

    func testCopySelection_ClearsContentsBeforePostingEvents() {
        pasteboard.savedItems = [makeItem("pre-existing")]

        _ = simulator.copySelection(from: nil)

        XCTAssertGreaterThanOrEqual(pasteboard.clearContentsCount, 1)
    }

    func testCopySelection_RestoresOriginalPasteboardOnFailure() {
        pasteboard.savedItems = [makeItem("original")]

        _ = simulator.copySelection(from: nil)

        XCTAssertGreaterThanOrEqual(pasteboard.writeObjectsCount, 1)
        XCTAssertEqual(pasteboard.writtenItems.count, 1)
    }

    func testCopySelection_DoesNotRestoreEmptyPasteboard() {
        pasteboard.savedItems = []

        _ = simulator.copySelection(from: nil)

        XCTAssertEqual(pasteboard.writeObjectsCount, 0)
    }

    func testCopySelection_CapturesTextWhenChangeCountChanges() {
        pasteboard.savedItems = [makeItem("original")]
        pasteboard.pendingString = "captured text"

        let result = simulator.copySelection(from: nil)

        XCTAssertEqual(result, "captured text")
    }

    private func makeItem(_ text: String) -> NSPasteboardItem {
        let item = NSPasteboardItem()
        item.setString(text, forType: .string)
        return item
    }
}

private final class FakeSelectedTextPasteboard: SelectedTextPasteboardAccessing {
    var savedItems: [NSPasteboardItem]?
    var pendingString: String?
    private(set) var clearContentsCount = 0
    private(set) var writeObjectsCount = 0
    private(set) var writtenItems: [NSPasteboardWriting] = []
    private var readCount = 0

    var pasteboardItems: [NSPasteboardItem]? {
        savedItems
    }

    var changeCount: Int {
        readCount += 1
        // Reads: clearContents return (1), cleared baseline (2), then poll.
        // Return a different value from the baseline so the poll loop
        // observes a pasteboard change.
        return readCount >= 3 ? 99 : 0
    }

    func clearContents() -> Int {
        clearContentsCount += 1
        savedItems = nil
        return changeCount
    }

    func string(forType _: NSPasteboard.PasteboardType) -> String? {
        pendingString
    }

    func writeObjects(_ objects: [NSPasteboardWriting]) -> Bool {
        writeObjectsCount += 1
        writtenItems = objects
        return true
    }
}
