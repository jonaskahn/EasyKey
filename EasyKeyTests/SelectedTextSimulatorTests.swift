import AppKit
@testable import EasyKey
import XCTest

final class SelectedTextSimulatorTests: XCTestCase {
    private var pasteboard: FakeNSPasteboard!
    private var simulator: SystemSelectedTextSimulator!

    override func setUpWithError() throws {
        pasteboard = FakeNSPasteboard()
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
        pasteboard.addItem("pre-existing")

        _ = simulator.copySelection(from: nil)

        XCTAssertEqual(pasteboard.clearContentsCount, 2)
    }

    func testCopySelection_RestoresOriginalPasteboardOnFailure() {
        let item = NSPasteboardItem()
        item.setString("original", forType: .string)
        pasteboard.savedItems = [item]

        _ = simulator.copySelection(from: nil)

        XCTAssertEqual(pasteboard.writeObjectsCount, 1)
        XCTAssertEqual(pasteboard.writtenItems.count, 1)
    }

    func testCopySelection_DoesNotRestoreEmptyPasteboard() {
        pasteboard.savedItems = []

        _ = simulator.copySelection(from: nil)

        XCTAssertEqual(pasteboard.writeObjectsCount, 0)
    }
}

private final class FakeNSPasteboard: NSPasteboard {
    var savedItems: [NSPasteboardItem]?
    private(set) var clearContentsCount = 0
    private(set) var writeObjectsCount = 0
    private(set) var writtenItems: [any NSPasteboardWriting] = []
    private var internalItems: [NSPasteboardItem] = []

    override var pasteboardItems: [NSPasteboardItem]? {
        savedItems
    }

    func addItem(_ text: String) {
        let item = NSPasteboardItem()
        item.setString(text, forType: .string)
        internalItems.append(item)
    }

    override var changeCount: Int {
        if clearContentsCount > 0 {
            return 99
        }
        return 0
    }

    override func clearContents() -> Int {
        clearContentsCount += 1
        internalItems.removeAll()
        return changeCount
    }

    override func writeObjects(_ objects: [any NSPasteboardWriting]) -> Bool {
        writeObjectsCount += 1
        writtenItems = objects
        return true
    }
}
