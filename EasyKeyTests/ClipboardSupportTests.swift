import Combine
import CryptoKit
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
        let decoded = expectation(description: "thumbnail decoded")
        let cancellable = loader.objectWillChange.sink { decoded.fulfill() }
        XCTAssertNil(loader.thumbnail(for: "ref"))
        wait(for: [decoded], timeout: 2)
        XCTAssertNotNil(loader.thumbnail(for: "ref"))
        loader.remove(references: ["ref"])
        loader.clear()
        withExtendedLifetime(cancellable) {}
    }

    func testReturnsNilForUndecodableData() {
        let loader = ClipboardThumbnailLoader(dataProvider: { _ in Data([0, 1, 2]) })
        let completed = expectation(description: "decode completed")
        let cancellable = loader.objectWillChange.sink { completed.fulfill() }
        XCTAssertNil(loader.thumbnail(for: "ref"))
        wait(for: [completed], timeout: 2)
        XCTAssertNil(loader.thumbnail(for: "ref"))
        withExtendedLifetime(cancellable) {}
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

    func testCreateKeyReturns256BitKey() throws {
        let store = InMemoryClipboardKeyStore()
        let key = try store.createKey()
        XCTAssertEqual(key.bitCount, 256)
    }

    func testPreloadedKeyReturned() throws {
        let preload = SymmetricKey(size: .bits256)
        let store = InMemoryClipboardKeyStore(key: preload)
        let key = try store.existingKey()
        XCTAssertEqual(key, preload)
    }

    func testDeleteKeyWithoutCreateDoesNotThrow() throws {
        let store = InMemoryClipboardKeyStore()
        try store.deleteKey()
        XCTAssertNil(try store.existingKey())
    }

    func testThreadSafety() throws {
        let store = InMemoryClipboardKeyStore()
        let e1 = expectation(description: "create1")
        let e2 = expectation(description: "create2")
        DispatchQueue.global().async {
            _ = try? store.createKey()
            e1.fulfill()
        }
        DispatchQueue.global().async {
            _ = try? store.createKey()
            e2.fulfill()
        }
        wait(for: [e1, e2], timeout: 2.0)
        XCTAssertNotNil(try store.existingKey())
    }

    func testClipboardKeyErrorEquality() {
        XCTAssertEqual(ClipboardKeyError.unexpectedStatus(-1), ClipboardKeyError.unexpectedStatus(-1))
        XCTAssertEqual(ClipboardKeyError.invalidKeyData, ClipboardKeyError.invalidKeyData)
        XCTAssertNotEqual(ClipboardKeyError.unexpectedStatus(-1), ClipboardKeyError.invalidKeyData)
    }

    func testKeychainStore_RoundTripCreateExistingAndDelete() throws {
        let service = "one.ifelse.easykey.clipboard.tests.\(UUID().uuidString)"
        let store = KeychainClipboardKeyStore(service: service, account: "test-key")
        XCTAssertNil(try store.existingKey())

        let created = try store.createKey()
        let fetched = try XCTUnwrap(try store.existingKey())
        XCTAssertEqual(created, fetched)

        try store.deleteKey()
        XCTAssertNil(try store.existingKey())
    }

    func testKeychainStore_DeleteIsIdempotent() throws {
        let service = "one.ifelse.easykey.clipboard.tests.\(UUID().uuidString)"
        let store = KeychainClipboardKeyStore(service: service, account: "test-key")
        try store.deleteKey()
        XCTAssertNil(try store.existingKey())
    }

    func testKeychainStore_DifferentServicesAreIsolated() throws {
        let base = "one.ifelse.easykey.clipboard.tests.\(UUID().uuidString)"
        let storeA = KeychainClipboardKeyStore(service: "\(base).A", account: "test-key")
        let storeB = KeychainClipboardKeyStore(service: "\(base).B", account: "test-key")

        let keyA = try storeA.createKey()
        let fetchedB = try storeB.existingKey()
        XCTAssertNil(fetchedB)

        let fetchedA = try XCTUnwrap(try storeA.existingKey())
        XCTAssertEqual(keyA, fetchedA)

        try storeA.deleteKey()
        try storeB.deleteKey()
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

    func testCopyConvertedText_WithoutHTML_DoesNotWriteHTML() {
        let suppressor = ClipboardWriteSuppressor()
        let pasteboard = NSPasteboard.withUniqueName()
        let writer = PasteboardWriter(pasteboard: pasteboard, suppressor: suppressor)
        writer.copyConvertedText("text", preservingHTML: nil)
        XCTAssertNil(pasteboard.data(forType: .html))
        XCTAssertEqual(pasteboard.string(forType: .string), "text")
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

    func testSuppressorOnlySuppressesLastMarked() {
        let suppressor = ClipboardWriteSuppressor()
        suppressor.markWritten(changeCount: 10)
        suppressor.markWritten(changeCount: 20)
        XCTAssertFalse(suppressor.shouldSuppress(10))
        XCTAssertTrue(suppressor.shouldSuppress(20))
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

    func testCopyEntryWithStringRepresentation() throws {
        let pasteboard = NSPasteboard.withUniqueName()
        pasteboard.clearContents()
        let suppressor = ClipboardWriteSuppressor()
        let writer = PasteboardWriter(pasteboard: pasteboard, suppressor: suppressor)
        let entry = ClipboardEntry(
            fingerprint: "fp",
            capturedAt: Date(),
            items: [
                ClipboardItem(
                    kind: .text,
                    preview: ClipboardItemPreview(primaryText: "hello"),
                    representations: [
                        .string(typeIdentifier: "public.utf8-plain-text", value: "hello"),
                    ]
                ),
            ]
        )
        try writer.copy(entry)
        XCTAssertEqual(pasteboard.string(forType: .string), "hello")
    }

    func testCopyEntryWithDataRepresentation() throws {
        let pasteboard = NSPasteboard.withUniqueName()
        pasteboard.clearContents()
        let payloadStore = ClipboardPayloadStore()
        let imageData = Data(repeating: 0xFF, count: 100)
        payloadStore.insert(["ref": imageData])
        let suppressor = ClipboardWriteSuppressor()
        let writer = PasteboardWriter(pasteboard: pasteboard, suppressor: suppressor, payloadStore: payloadStore)
        let entry = ClipboardEntry(
            fingerprint: "img",
            capturedAt: Date(),
            items: [
                ClipboardItem(
                    kind: .image,
                    preview: ClipboardItemPreview(primaryText: "PNG"),
                    representations: [
                        .data(typeIdentifier: "public.png", payloadReference: "ref"),
                    ]
                ),
            ]
        )
        try writer.copy(entry)
        XCTAssertEqual(pasteboard.data(forType: NSPasteboard.PasteboardType("public.png")), imageData)
    }

    func testCopyMultipleItems() throws {
        let pasteboard = NSPasteboard.withUniqueName()
        pasteboard.clearContents()
        let suppressor = ClipboardWriteSuppressor()
        let writer = PasteboardWriter(pasteboard: pasteboard, suppressor: suppressor)
        let entry = ClipboardEntry(
            fingerprint: "multi",
            capturedAt: Date(),
            items: [
                ClipboardItem(
                    kind: .text,
                    preview: ClipboardItemPreview(primaryText: "a"),
                    representations: [.string(typeIdentifier: "public.utf8-plain-text", value: "first")]
                ),
                ClipboardItem(
                    kind: .text,
                    preview: ClipboardItemPreview(primaryText: "b"),
                    representations: [.string(typeIdentifier: "public.utf8-plain-text", value: "second")]
                ),
            ]
        )
        try writer.copy(entry)
        XCTAssertEqual(pasteboard.pasteboardItems?.count, 2)
    }

    func testPasteboardWriteErrorEquality() {
        XCTAssertEqual(PasteboardWriteError.unavailableRepresentation, PasteboardWriteError.unavailableRepresentation)
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

    func testSensitiveMarkers_DetectsAutoGenerated() {
        XCTAssertTrue(SensitivePasteboardMarkers.contains(["org.nspasteboard.AutoGeneratedType"]))
    }

    func testSensitiveMarkers_DetectsTransient() {
        XCTAssertTrue(SensitivePasteboardMarkers.contains(["org.nspasteboard.TransientType"]))
    }

    func testSensitiveMarkers_DetectsLastPass() {
        XCTAssertTrue(SensitivePasteboardMarkers.contains(["com.lastpass.lastpass"]))
    }

    func testSensitiveMarkers_DetectsClipboardPrivate() {
        XCTAssertTrue(SensitivePasteboardMarkers.contains(["de.dirkholtwick.clipboard.private"]))
    }

    func testSensitiveMarkers_DetectsInMixedList() {
        XCTAssertTrue(SensitivePasteboardMarkers.contains(["public.utf8-plain-text", "org.nspasteboard.ConcealedType", "public.png"]))
    }

    func testSensitiveMarkers_RejectsMixedSafeList() {
        XCTAssertFalse(SensitivePasteboardMarkers.contains(["public.utf8-plain-text", "public.png"]))
    }

    func testClipboardLimits_HasExpectedValues() {
        XCTAssertEqual(ClipboardLimits.maximumEventBytes, 10 * 1024 * 1024)
        XCTAssertEqual(ClipboardLimits.maximumRetainedBytes, 100 * 1024 * 1024)
    }

    func testPasteboardDescriptor_Equality() {
        let d1 = PasteboardDescriptor(changeCount: 1, items: [PasteboardItemDescriptor(typeIdentifiers: ["a"])])
        let d2 = PasteboardDescriptor(changeCount: 1, items: [PasteboardItemDescriptor(typeIdentifiers: ["a"])])
        let d3 = PasteboardDescriptor(changeCount: 2, items: [])
        XCTAssertEqual(d1, d2)
        XCTAssertNotEqual(d1, d3)
    }

    func testPasteboardSnapshot_Equality() {
        let rep = CapturedPasteboardRepresentation(typeIdentifier: "text", data: Data([1]))
        let s1 = PasteboardSnapshot(changeCount: 1, items: [PasteboardItemSnapshot(representations: [rep])])
        let s2 = PasteboardSnapshot(changeCount: 1, items: [PasteboardItemSnapshot(representations: [rep])])
        let s3 = PasteboardSnapshot(changeCount: 2, items: [])
        XCTAssertEqual(s1, s2)
        XCTAssertNotEqual(s1, s3)
    }

    func testCapturedPasteboardRepresentation_Equality() {
        let r1 = CapturedPasteboardRepresentation(typeIdentifier: "text", data: Data([1, 2, 3]))
        let r2 = CapturedPasteboardRepresentation(typeIdentifier: "text", data: Data([1, 2, 3]))
        let r3 = CapturedPasteboardRepresentation(typeIdentifier: "text", data: Data([4, 5, 6]))
        let r4 = CapturedPasteboardRepresentation(typeIdentifier: "image", data: Data([1, 2, 3]))
        XCTAssertEqual(r1, r2)
        XCTAssertNotEqual(r1, r3)
        XCTAssertNotEqual(r1, r4)
    }

    func testSensitiveMarkers_AllIdentifiersSetNotEmpty() {
        XCTAssertTrue(SensitivePasteboardMarkers.identifiers.count > 0)
    }

    func testSystemPasteboardReader_ChangeCount() {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("SystemPasteboardReaderTests-\(UUID().uuidString)"))
        let reader = SystemPasteboardReader(pasteboard: pasteboard)
        let initial = reader.changeCount
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString("hello", forType: .string)
        XCTAssertGreaterThan(reader.changeCount, initial)
    }

    func testSystemPasteboardReader_Descriptor() {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("SystemPasteboardReaderTests-\(UUID().uuidString)"))
        pasteboard.declareTypes([.string, .rtf], owner: nil)
        pasteboard.setString("hello", forType: .string)
        let reader = SystemPasteboardReader(pasteboard: pasteboard)
        let descriptor = reader.descriptor()
        XCTAssertEqual(descriptor.changeCount, pasteboard.changeCount)
        XCTAssertEqual(descriptor.items.count, 1)
        XCTAssertTrue(descriptor.items[0].typeIdentifiers.contains("public.utf8-plain-text"))
    }

    func testSystemPasteboardReader_Snapshot_SelectsData() {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("SystemPasteboardReaderTests-\(UUID().uuidString)"))
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString("snapshot", forType: .string)
        let reader = SystemPasteboardReader(pasteboard: pasteboard)
        let snapshot = reader.snapshot(selecting: [["public.utf8-plain-text"]])
        XCTAssertEqual(snapshot.changeCount, pasteboard.changeCount)
        XCTAssertEqual(snapshot.items.count, 1)
        XCTAssertEqual(snapshot.items[0].representations.count, 1)
        XCTAssertEqual(snapshot.items[0].representations[0].typeIdentifier, "public.utf8-plain-text")
        XCTAssertEqual(String(data: snapshot.items[0].representations[0].data, encoding: .utf8), "snapshot")
    }

    func testSystemPasteboardReader_Snapshot_SkipsMissingType() {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("SystemPasteboardReaderTests-\(UUID().uuidString)"))
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString("data", forType: .string)
        let reader = SystemPasteboardReader(pasteboard: pasteboard)
        let snapshot = reader.snapshot(selecting: [["public.utf8-plain-text", "public.png"]])
        XCTAssertEqual(snapshot.items[0].representations.count, 1)
        XCTAssertEqual(snapshot.items[0].representations[0].typeIdentifier, "public.utf8-plain-text")
    }

    func testSystemPasteboardReader_Snapshot_FewerIdentifiersThanItems() {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("SystemPasteboardReaderTests-\(UUID().uuidString)"))
        pasteboard.declareTypes([.string, .rtf], owner: nil)
        pasteboard.setString("hello", forType: .string)
        let reader = SystemPasteboardReader(pasteboard: pasteboard)
        let snapshot = reader.snapshot(selecting: [["public.utf8-plain-text"]])
        XCTAssertEqual(snapshot.items.count, 1)
        XCTAssertEqual(snapshot.items[0].representations.count, 1)
    }

    func testSystemPasteboardReader_DefaultInit() {
        let reader = SystemPasteboardReader()
        XCTAssertEqual(reader.changeCount, NSPasteboard.general.changeCount)
    }
}

@MainActor
final class ClipboardPanelPresenterExtendedTests: XCTestCase {
    func testPresenterDefaultState() {
        let presenter = ClipboardPanelPresenter()
        XCTAssertFalse(presenter.isShown)
        XCTAssertNil(presenter.previousApplication)
    }

    func testShowSetsPreviousApplication() {
        let presenter = ClipboardPanelPresenter()
        presenter.show(previousApplication: nil)
        presenter.close()
    }

    func testToggleOpensAndCloses() {
        let presenter = ClipboardPanelPresenter()
        XCTAssertFalse(presenter.isShown)
        presenter.toggle(previousApplication: nil)
        presenter.close()
    }

    func testSetKeepOnTopPersistsValueAcrossPresenterInstances() throws {
        let suiteName = "ClipboardPanelPresenterExtendedTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let presenter = ClipboardPanelPresenter(userDefaults: defaults)
        XCTAssertFalse(defaults.bool(forKey: "panel.clipboard.keepOnTop"))

        presenter.setKeepOnTop(true)
        XCTAssertTrue(defaults.bool(forKey: "panel.clipboard.keepOnTop"))

        presenter.setKeepOnTop(false)
        XCTAssertFalse(defaults.bool(forKey: "panel.clipboard.keepOnTop"))
    }

    func testNewPresenterLoadsPersistedKeepOnTopValue() throws {
        let suiteName = "ClipboardPanelPresenterExtendedTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(true, forKey: "panel.clipboard.keepOnTop")

        _ = ClipboardPanelPresenter(userDefaults: defaults)

        XCTAssertTrue(defaults.bool(forKey: "panel.clipboard.keepOnTop"))
    }
}

@MainActor
final class ClipboardActionCoordinatorExtendedTests: XCTestCase {
    func testPerformPasteImmediately_AllStepsSequence() {
        var steps: [String] = []
        let coordinator = ClipboardActionCoordinator(
            writeEntry: { _ in steps.append("write") },
            closePanel: { steps.append("close") },
            reactivatePrevious: { steps.append("reactivate"); return true },
            synthesizePaste: { steps.append("paste"); return true }
        )
        let item = ClipboardItem(
            kind: .text,
            preview: ClipboardItemPreview(primaryText: "test"),
            representations: [.string(typeIdentifier: "public.utf8-plain-text", value: "test")]
        )
        let entry = ClipboardEntry(fingerprint: "f", capturedAt: Date(), items: [item])
        coordinator.perform(entry, action: .pasteImmediately)
        XCTAssertEqual(steps.count, 4)
    }

    func testPerformCopyOnly_NoPasteNoReactivate() {
        var steps: [String] = []
        let coordinator = ClipboardActionCoordinator(
            writeEntry: { _ in steps.append("write") },
            closePanel: { steps.append("close") },
            reactivatePrevious: { steps.append("reactivate"); return true },
            synthesizePaste: { steps.append("paste"); return true }
        )
        let entry = ClipboardEntry(
            fingerprint: "f",
            capturedAt: Date(),
            items: [
                ClipboardItem(
                    kind: .text,
                    preview: ClipboardItemPreview(primaryText: "t"),
                    representations: [
                        .string(typeIdentifier: "public.utf8-plain-text", value: "t"),
                    ]
                ),
            ]
        )
        coordinator.perform(entry, action: .copyOnly)
        XCTAssertFalse(steps.contains("reactivate"))
        XCTAssertFalse(steps.contains("paste"))
    }

    func testLastErrorInitialIsNil() {
        let coordinator = ClipboardActionCoordinator(
            writeEntry: { _ in },
            closePanel: {},
            reactivatePrevious: { true },
            synthesizePaste: { true }
        )
        XCTAssertNil(coordinator.lastError)
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
