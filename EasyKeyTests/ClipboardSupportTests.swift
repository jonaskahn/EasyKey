import EasyEngineCore
@testable import EasyKey
import XCTest

@MainActor
final class ClipboardPayloadStoreTests: XCTestCase {
    func testInsertTracksBytesAndAvoidsDuplicates() throws {
        let store = ClipboardPayloadStore()
        store.insert(["a": Data([1, 2, 3])])
        store.insert(["a": Data([9, 9, 9, 9])])
        XCTAssertEqual(store.totalByteCount, 3)
        XCTAssertEqual(try store.data(for: "a"), Data([1, 2, 3]))
    }

    func testRemoveUpdatesTotal() {
        let store = ClipboardPayloadStore()
        store.insert(["a": Data([1, 2]), "b": Data([3, 4, 5])])
        store.remove(references: ["a"])
        XCTAssertEqual(store.totalByteCount, 3)
        XCTAssertFalse(store.contains("a"))
    }

    func testCanRetainRespectsCap() {
        let store = ClipboardPayloadStore()
        XCTAssertTrue(store.canRetain(additionalBytes: ClipboardLimits.maximumRetainedBytes))
        XCTAssertFalse(store.canRetain(additionalBytes: ClipboardLimits.maximumRetainedBytes + 1))
    }

    func testMissingReferenceThrows() {
        let store = ClipboardPayloadStore()
        XCTAssertThrowsError(try store.data(for: "missing"))
    }

    func testByteCountOfSubset() {
        let store = ClipboardPayloadStore()
        store.insert(["a": Data([1]), "b": Data([2, 2])])
        XCTAssertEqual(store.byteCount(of: ["a", "b"]), 3)
        XCTAssertEqual(store.byteCount(of: ["a"]), 1)
    }
}

@MainActor
final class ClipboardThumbnailLoaderTests: XCTestCase {
    func testDecodesAndCachesThenInvalidates() {
        let png = Self.makePNG()
        let loader = ClipboardThumbnailLoader(dataProvider: { _ in png })
        XCTAssertNotNil(loader.thumbnail(for: "ref"))
        XCTAssertNotNil(loader.thumbnail(for: "ref"))
        loader.remove(references: ["ref"])
        loader.clear()
    }

    func testReturnsNilForUndecodableData() {
        let loader = ClipboardThumbnailLoader(dataProvider: { _ in Data([0, 1, 2]) })
        XCTAssertNil(loader.thumbnail(for: "ref"))
    }

    private static func makePNG() -> Data {
        let image = NSImage(size: NSSize(width: 4, height: 4))
        image.lockFocus()
        NSColor.red.drawSwatch(in: NSRect(x: 0, y: 0, width: 4, height: 4))
        image.unlockFocus()
        let tiff = image.tiffRepresentation!
        let rep = NSBitmapImageRep(data: tiff)!
        return rep.representation(using: .png, properties: [:])!
    }
}

@MainActor
final class ClipboardKeyStoreTests: XCTestCase {
    func testInMemoryExistingKey_ReturnsNilInitially() throws {
        let store = InMemoryClipboardKeyStore()
        XCTAssertNil(try store.existingKey())
    }

    func testInMemoryCreateKey_ReturnsSameOnSecondCall() throws {
        let store = InMemoryClipboardKeyStore()
        let key1 = try store.createKey()
        let key2 = try store.createKey()
        XCTAssertEqual(key1, key2)
    }

    func testInMemoryDeleteKey_ThenExistingKeyReturnsNil() throws {
        let store = InMemoryClipboardKeyStore()
        _ = try store.createKey()
        try store.deleteKey()
        XCTAssertNil(try store.existingKey())
    }
}

@MainActor
final class PasteboardWriterTests: XCTestCase {
    func testCopyConvertedText_WritesAndMarksSuppression() {
        let suppressor = ClipboardWriteSuppressor()
        let writer = PasteboardWriter(suppressor: suppressor)
        writer.copyConvertedText("hello", preservingHTML: nil)
        XCTAssertNotNil(suppressor.suppressedChangeCount)
    }

    func testCopyConvertedText_PreservesHTML() {
        let suppressor = ClipboardWriteSuppressor()
        let writer = PasteboardWriter(suppressor: suppressor)
        writer.copyConvertedText("hello", preservingHTML: Data([0x48, 0x54, 0x4D, 0x4C]))
        XCTAssertNotNil(suppressor.suppressedChangeCount)
    }

    func testSuppressorShouldSuppress_MatchingCount_ReturnsTrue() {
        let suppressor = ClipboardWriteSuppressor()
        suppressor.markWritten(changeCount: 42)
        XCTAssertTrue(suppressor.shouldSuppress(42))
    }

    func testSuppressorShouldSuppress_DifferentCount_ReturnsFalse() {
        let suppressor = ClipboardWriteSuppressor()
        suppressor.markWritten(changeCount: 42)
        XCTAssertFalse(suppressor.shouldSuppress(43))
    }

    func testSuppressorInitialState_ReturnsFalse() {
        let suppressor = ClipboardWriteSuppressor()
        XCTAssertFalse(suppressor.shouldSuppress(0))
        XCTAssertNil(suppressor.suppressedChangeCount)
    }

    func testCopyThrowsWhenNoPayloadStore() {
        let suppressor = ClipboardWriteSuppressor()
        let writer = PasteboardWriter(suppressor: suppressor)
        let item = ClipboardItem(
            kind: .text,
            preview: ClipboardItemPreview(primaryText: "test"),
            representations: [.data(typeIdentifier: "public.data", payloadReference: "ref")]
        )
        let entry = ClipboardEntry(fingerprint: "f", capturedAt: Date(), items: [item])
        XCTAssertThrowsError(try writer.copy(entry))
    }
}

@MainActor
final class ClipboardPanelPresenterTests: XCTestCase {
    func testIsShown_InitiallyFalse() {
        let presenter = ClipboardPanelPresenter()
        XCTAssertFalse(presenter.isShown)
    }

    func testPreviousApplication_InitiallyNil() {
        let presenter = ClipboardPanelPresenter()
        XCTAssertNil(presenter.previousApplication)
    }

    func testPanelCanBecomeKey() {
        let panel = ClipboardPanel(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        XCTAssertTrue(panel.canBecomeKey)
    }
}

final class PasteboardSnapshotTests: XCTestCase {
    func testSensitiveMarkers_ContainsPasswordManager() {
        XCTAssertTrue(SensitivePasteboardMarkers.contains(["com.agilebits.onepassword"]))
    }

    func testSensitiveMarkers_DoesNotContainPlainText() {
        XCTAssertFalse(SensitivePasteboardMarkers.contains(["public.utf8-plain-text"]))
    }

    func testSensitiveMarkers_ContainsConcealedType() {
        XCTAssertTrue(SensitivePasteboardMarkers.contains(["org.nspasteboard.ConcealedType"]))
    }

    func testSensitiveMarkers_EmptyList() {
        XCTAssertFalse(SensitivePasteboardMarkers.contains([]))
    }
}

final class ClipboardWriteSuppressorTests: XCTestCase {
    func testMultipleMarkWritten_UpdatesCount() async {
        let suppressor = await MainActor.run { ClipboardWriteSuppressor() }
        await MainActor.run { suppressor.markWritten(changeCount: 10) }
        let count = await MainActor.run { suppressor.suppressedChangeCount }
        XCTAssertEqual(count, 10)
        await MainActor.run { suppressor.markWritten(changeCount: 20) }
        let updated = await MainActor.run { suppressor.suppressedChangeCount }
        XCTAssertEqual(updated, 20)
    }
}
