@testable import EasyEngineCore
import XCTest

final class ClipboardHistoryTests: XCTestCase {
    private let base = Date(timeIntervalSince1970: 1_700_000_000)
    private let options = ClipboardOptions(maximumEntryCount: 100, retentionDays: 7)

    // MARK: - ClipboardEntry.kind

    func testKind_WhenItemsEmpty_IsMixed() {
        let entry = ClipboardEntry(fingerprint: "empty", capturedAt: base, items: [])
        XCTAssertEqual(entry.kind, .mixed)
    }

    // MARK: - Ordering & deduplication

    func testInsertOrdersNewestFirst() {
        var history = ClipboardHistory()
        history.insert(textEntry("a", fingerprint: "fa"), options: options, now: base)
        history.insert(textEntry("b", fingerprint: "fb"), options: options, now: base.addingTimeInterval(1))
        XCTAssertEqual(history.entries.map(\.fingerprint), ["fb", "fa"])
    }

    func testRecopyingIdenticalContentRemovesDuplicateAndMovesToTop() {
        var history = ClipboardHistory()
        history.insert(textEntry("a", fingerprint: "fa"), options: options, now: base)
        history.insert(textEntry("b", fingerprint: "fb"), options: options, now: base.addingTimeInterval(1))
        history.insert(textEntry("a", fingerprint: "fa"), options: options, now: base.addingTimeInterval(2))

        XCTAssertEqual(history.entries.count, 2)
        XCTAssertEqual(history.entries.first?.fingerprint, "fa")
        XCTAssertEqual(history.entries.first?.capturedAt, base.addingTimeInterval(2))
    }

    // MARK: - Retention

    func testCountLimitAppliesToUnpinnedOnly() {
        var history = ClipboardHistory()
        let limited = ClipboardOptions(maximumEntryCount: 2, retentionDays: 7)
        for index in 0 ..< 5 {
            history.insert(
                textEntry("t\(index)", fingerprint: "f\(index)"),
                options: limited,
                now: base.addingTimeInterval(Double(index))
            )
        }
        XCTAssertEqual(history.entries.map(\.fingerprint), ["f4", "f3"])
    }

    func testAgeBoundaryPrunesStrictlyOlderThanCutoff() {
        var history = ClipboardHistory()
        let sevenDays: TimeInterval = 7 * 86400
        history.insert(textEntry("old", fingerprint: "old"), options: options, now: base)
        let now = base.addingTimeInterval(sevenDays + 1)
        history.insert(textEntry("new", fingerprint: "new"), options: options, now: now)
        history.prune(options: options, now: now)
        XCTAssertEqual(history.entries.map(\.fingerprint), ["new"])
    }

    func testPinnedEntriesSurvivePruning() {
        var history = ClipboardHistory()
        let limited = ClipboardOptions(maximumEntryCount: 1, retentionDays: 7)
        history.insert(textEntry("keep", fingerprint: "keep"), options: limited, now: base)
        let id = history.entries[0].id
        XCTAssertEqual(history.setPinned(true, entryID: id, now: base), .updated)
        for index in 0 ..< 3 {
            history.insert(
                textEntry("t\(index)", fingerprint: "f\(index)"),
                options: limited,
                now: base.addingTimeInterval(Double(index + 1))
            )
        }
        XCTAssertTrue(history.entries.contains { $0.fingerprint == "keep" })
    }

    // MARK: - Pinning

    func testPinnedEntriesSortAboveRecentByPinnedAt() throws {
        var history = ClipboardHistory()
        history.insert(textEntry("a", fingerprint: "fa"), options: options, now: base)
        history.insert(textEntry("b", fingerprint: "fb"), options: options, now: base.addingTimeInterval(1))
        let idA = try XCTUnwrap(history.entries.first { $0.fingerprint == "fa" }?.id)
        let idB = try XCTUnwrap(history.entries.first { $0.fingerprint == "fb" }?.id)
        history.setPinned(true, entryID: idA, now: base.addingTimeInterval(10))
        history.setPinned(true, entryID: idB, now: base.addingTimeInterval(20))
        XCTAssertEqual(history.entries.map(\.fingerprint), ["fb", "fa"])
    }

    func testRecopyingPinnedContentPreservesPinStateAndPinnedAt() {
        var history = ClipboardHistory()
        history.insert(textEntry("a", fingerprint: "fa"), options: options, now: base)
        let id = history.entries[0].id
        history.setPinned(true, entryID: id, now: base.addingTimeInterval(5))
        let pinnedAt = history.entries[0].pinnedAt

        history.insert(textEntry("a", fingerprint: "fa"), options: options, now: base.addingTimeInterval(30))
        let entry = history.entries.first { $0.fingerprint == "fa" }
        XCTAssertEqual(entry?.isPinned, true)
        XCTAssertEqual(entry?.pinnedAt, pinnedAt)
        XCTAssertEqual(entry?.capturedAt, base.addingTimeInterval(30))
    }

    func testPinningBeyondLimitIsRefusedWithoutMutation() throws {
        var history = ClipboardHistory()
        for index in 0 ..< ClipboardHistory.maximumPinnedEntries {
            history.insert(
                textEntry("t\(index)", fingerprint: "f\(index)"),
                options: options,
                now: base.addingTimeInterval(Double(index))
            )
            let id = try XCTUnwrap(history.entries.first { $0.fingerprint == "f\(index)" }?.id)
            history.setPinned(true, entryID: id, now: base.addingTimeInterval(Double(index)))
        }
        history.insert(textEntry("extra", fingerprint: "extra"), options: options, now: base.addingTimeInterval(1000))
        let extraID = try XCTUnwrap(history.entries.first { $0.fingerprint == "extra" }?.id)

        XCTAssertEqual(history.pinnedCount, ClipboardHistory.maximumPinnedEntries)
        XCTAssertEqual(history.setPinned(true, entryID: extraID, now: base), .pinnedLimitReached)
        XCTAssertEqual(history.pinnedCount, ClipboardHistory.maximumPinnedEntries)
        XCTAssertFalse(try XCTUnwrap(history.entries.first { $0.fingerprint == "extra" }?.isPinned))
    }

    func testUnpinClearsPinnedAt() {
        var history = ClipboardHistory()
        history.insert(textEntry("a", fingerprint: "fa"), options: options, now: base)
        let id = history.entries[0].id
        history.setPinned(true, entryID: id, now: base)
        history.setPinned(false, entryID: id, now: base)
        XCTAssertFalse(history.entries[0].isPinned)
        XCTAssertNil(history.entries[0].pinnedAt)
    }

    func testSetPinnedOnMissingEntryReturnsNotFound() {
        var history = ClipboardHistory()
        XCTAssertEqual(history.setPinned(true, entryID: UUID(), now: base), .notFound)
    }

    // MARK: - Clearing

    func testClearRemovesEverythingIncludingPinned() {
        var history = ClipboardHistory()
        history.insert(textEntry("a", fingerprint: "fa"), options: options, now: base)
        history.setPinned(true, entryID: history.entries[0].id, now: base)
        history.clear()
        XCTAssertTrue(history.entries.isEmpty)
    }

    func testClearUnpinnedKeepsPinned() {
        var history = ClipboardHistory()
        history.insert(textEntry("pin", fingerprint: "pin"), options: options, now: base)
        history.setPinned(true, entryID: history.entries[0].id, now: base)
        history.insert(textEntry("free", fingerprint: "free"), options: options, now: base.addingTimeInterval(1))
        history.clearUnpinned()
        XCTAssertEqual(history.entries.map(\.fingerprint), ["pin"])
    }

    // MARK: - Search

    func testSearchMatchesTextURLFilenameAndSource() {
        var history = ClipboardHistory()
        history.insert(textEntry("Hello World", fingerprint: "text"), options: options, now: base)
        history.insert(urlEntry("https://example.com/path", fingerprint: "url"), options: options, now: base.addingTimeInterval(1))
        history.insert(fileEntry("/Users/me/Report.pdf", fingerprint: "file"), options: options, now: base.addingTimeInterval(2))
        history.insert(
            sourcedTextEntry("plain", fingerprint: "src", appName: "Safari", bundle: "com.apple.Safari"),
            options: options,
            now: base.addingTimeInterval(3)
        )

        XCTAssertEqual(history.entries(matching: "world").map(\.fingerprint), ["text"])
        XCTAssertEqual(history.entries(matching: "example.com").map(\.fingerprint), ["url"])
        XCTAssertEqual(history.entries(matching: "report").map(\.fingerprint), ["file"])
        XCTAssertEqual(history.entries(matching: "safari").map(\.fingerprint), ["src"])
        XCTAssertEqual(history.entries(matching: "com.apple.Safari").map(\.fingerprint), ["src"])
    }

    func testEmptyQueryReturnsAllEntries() {
        var history = ClipboardHistory()
        history.insert(textEntry("a", fingerprint: "fa"), options: options, now: base)
        history.insert(textEntry("b", fingerprint: "fb"), options: options, now: base.addingTimeInterval(1))
        XCTAssertEqual(history.entries(matching: "   ").count, 2)
    }

    func testSearchOnEmptyHistoryReturnsEmpty() {
        let history = ClipboardHistory()
        XCTAssertTrue(history.entries(matching: "anything").isEmpty)
    }

    // MARK: - Fixtures

    private func textEntry(_ text: String, fingerprint: String) -> ClipboardEntry {
        ClipboardEntry(fingerprint: fingerprint, capturedAt: base, items: [textItem(text)])
    }

    private func sourcedTextEntry(_ text: String, fingerprint: String, appName: String, bundle: String) -> ClipboardEntry {
        ClipboardEntry(
            fingerprint: fingerprint,
            capturedAt: base,
            source: ClipboardSource(applicationName: appName, bundleIdentifier: bundle),
            items: [textItem(text)]
        )
    }

    private func urlEntry(_ urlString: String, fingerprint: String) -> ClipboardEntry {
        let item = ClipboardItem(
            kind: .url,
            preview: ClipboardItemPreview(primaryText: urlString),
            representations: [.string(typeIdentifier: "public.url", value: urlString)]
        )
        return ClipboardEntry(fingerprint: fingerprint, capturedAt: base, items: [item])
    }

    private func fileEntry(_ path: String, fingerprint: String) -> ClipboardEntry {
        let name = (path as NSString).lastPathComponent
        let item = ClipboardItem(
            kind: .file,
            preview: ClipboardItemPreview(primaryText: name, fileName: name),
            representations: [.fileURL(URL(fileURLWithPath: path))]
        )
        return ClipboardEntry(fingerprint: fingerprint, capturedAt: base, items: [item])
    }

    private func textItem(_ text: String) -> ClipboardItem {
        ClipboardItem(
            kind: .text,
            preview: ClipboardItemPreview(primaryText: text),
            representations: [.string(typeIdentifier: "public.utf8-plain-text", value: text)]
        )
    }
}
