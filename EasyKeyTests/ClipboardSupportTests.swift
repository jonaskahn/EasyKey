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
