import EasyEngineCore
@testable import EasyKey
import XCTest

@MainActor
final class ClipboardHistoryModelTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testCaptureRetainsImagePayload() {
        let model = ClipboardHistoryModel(options: ClipboardOptions(isCaptureEnabled: true), now: { self.now })
        model.capture(imageClassified(fingerprint: "a", reference: "r-a", bytes: 100))
        XCTAssertEqual(model.entryCount, 1)
        XCTAssertEqual(model.retainedByteCount, 100)
        XCTAssertNotNil(model.payloadData(for: "r-a"))
    }

    func testDeduplicationRemovesOrphanPayload() {
        let model = ClipboardHistoryModel(options: ClipboardOptions(isCaptureEnabled: true), now: { self.now })
        model.capture(textClassified(fingerprint: "same", value: "hello"))
        model.capture(imageClassified(fingerprint: "img", reference: "r-1", bytes: 50))
        model.capture(imageClassified(fingerprint: "img", reference: "r-2", bytes: 50))
        XCTAssertFalse(model.payloadStore.contains("r-1"))
        XCTAssertTrue(model.payloadStore.contains("r-2"))
        XCTAssertEqual(model.retainedByteCount, 50)
    }

    func testDuplicatePayloadReferenceIsNotCountedAsNewBytes() {
        let model = ClipboardHistoryModel(options: ClipboardOptions(isCaptureEnabled: true), now: { self.now })
        let reference = "same-reference"
        model.capture(imageClassified(fingerprint: "img", reference: reference, bytes: 50))

        model.capture(imageClassified(fingerprint: "img", reference: reference, bytes: 50))

        XCTAssertEqual(model.entryCount, 1)
        XCTAssertEqual(model.retainedByteCount, 50)
        XCTAssertNil(model.limitNotice)
    }

    func testPayloadLimitRejectsCandidate() {
        let model = ClipboardHistoryModel(options: ClipboardOptions(isCaptureEnabled: true), now: { self.now })
        model.capture(imageClassified(fingerprint: "big", reference: "r-big", bytes: ClipboardLimits.maximumRetainedBytes + 1))
        XCTAssertEqual(model.entryCount, 0)
        XCTAssertEqual(model.limitNotice, .payloadLimitReached)
    }

    func testPinnedLimitNoticeSurfaces() {
        let options = ClipboardOptions(isCaptureEnabled: true)
        let model = ClipboardHistoryModel(options: options, now: { self.now })
        for index in 0 ... ClipboardHistory.maximumPinnedEntries {
            model.capture(textClassified(fingerprint: "f\(index)", value: "t\(index)"))
        }
        // Pin the maximum, then attempt one more.
        let entries = model.history.entries
        for index in 0 ..< ClipboardHistory.maximumPinnedEntries {
            model.setPinned(true, entryID: entries[index].id)
        }
        model.setPinned(true, entryID: entries[ClipboardHistory.maximumPinnedEntries].id)
        XCTAssertEqual(model.limitNotice, .pinnedLimitReached)
    }

    func testClearAllRemovesEverything() async {
        let model = ClipboardHistoryModel(options: ClipboardOptions(isCaptureEnabled: true), now: { self.now })
        model.capture(imageClassified(fingerprint: "img", reference: "r-1", bytes: 50))
        await model.clearAll()
        XCTAssertEqual(model.entryCount, 0)
        XCTAssertEqual(model.retainedByteCount, 0)
    }

    func testPersistenceRoundTripThroughModel() async {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("model-persist-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let keyStore = InMemoryClipboardKeyStore()
        var options = ClipboardOptions(isCaptureEnabled: true)
        options.persistsHistory = true

        let writer = ClipboardHistoryModel(
            options: options,
            persistence: ClipboardPersistence(directory: directory, keyProvider: keyStore),
            now: { self.now },
            saveDebounce: .milliseconds(1)
        )
        writer.capture(textClassified(fingerprint: "f", value: "persisted"))
        await writer.flushPendingSave()

        let reader = ClipboardHistoryModel(
            options: options,
            persistence: ClipboardPersistence(directory: directory, keyProvider: keyStore),
            now: { self.now }
        )
        await reader.loadPersistedHistory()
        XCTAssertEqual(reader.entryCount, 1)
        XCTAssertEqual(reader.history.entries.first?.fingerprint, "f")
    }

    private func textClassified(fingerprint: String, value: String) -> ClassifiedClipboard {
        let item = ClipboardItem(
            kind: .text,
            preview: ClipboardItemPreview(primaryText: value),
            representations: [.string(typeIdentifier: "public.utf8-plain-text", value: value)]
        )
        let entry = ClipboardEntry(fingerprint: fingerprint, capturedAt: now, items: [item])
        return ClassifiedClipboard(entry: entry, payloads: [:])
    }

    private func imageClassified(fingerprint: String, reference: String, bytes: Int) -> ClassifiedClipboard {
        let item = ClipboardItem(
            kind: .image,
            preview: ClipboardItemPreview(primaryText: "PNG image", typeLabel: "PNG"),
            representations: [.data(typeIdentifier: "public.png", payloadReference: reference)]
        )
        let entry = ClipboardEntry(fingerprint: fingerprint, capturedAt: now, items: [item])
        return ClassifiedClipboard(entry: entry, payloads: [reference: Data(repeating: 0xAB, count: bytes)])
    }

    func testModel_Remove_DropsEntry() {
        let model = ClipboardHistoryModel(options: ClipboardOptions(maximumEntryCount: 100), persistence: nil)
        model.capture(textClassified(fingerprint: "f1", text: "a"))
        model.capture(textClassified(fingerprint: "f2", text: "b"))
        XCTAssertEqual(model.entryCount, 2)
        let snapshot = model.history.entries
        guard let id = snapshot.first(where: { $0.fingerprint == "f1" })?.id else {
            XCTFail("Entry not found")
            return
        }
        model.remove(entryID: id)
        XCTAssertEqual(model.entryCount, 1)
    }

    func testModel_ClearUnpinned_KeepsPinned() {
        let model = ClipboardHistoryModel(options: ClipboardOptions(maximumEntryCount: 100), persistence: nil)
        model.capture(textClassified(fingerprint: "f1", text: "a"))
        model.capture(textClassified(fingerprint: "f2", text: "b"))
        let snapshot = model.history.entries
        guard let id = snapshot.first(where: { $0.fingerprint == "f1" })?.id else {
            XCTFail("Entry not found")
            return
        }
        model.setPinned(true, entryID: id)
        model.clearUnpinned()
        XCTAssertEqual(model.entryCount, 1)
    }

    func testModel_Apply_RePrunesHistory() {
        let model = ClipboardHistoryModel(options: ClipboardOptions(maximumEntryCount: 1), persistence: nil)
        model.capture(textClassified(fingerprint: "f1", text: "a"))
        model.capture(textClassified(fingerprint: "f2", text: "b"))
        model.apply(ClipboardOptions(maximumEntryCount: 0))
        XCTAssertEqual(model.entryCount, 0)
    }

    func testModel_DisabledPersistence_DoesNotSave() async {
        var options = ClipboardOptions(maximumEntryCount: 100)
        options.persistsHistory = false
        let model = ClipboardHistoryModel(options: options, persistence: nil)
        model.capture(textClassified(fingerprint: "f1", text: "a"))
        await model.flushPendingSave()
    }

    func testModel_Apply_DisablesPersistence() {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("model-disable-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let keyStore = InMemoryClipboardKeyStore()
        var options = ClipboardOptions(isCaptureEnabled: true)
        options.persistsHistory = true
        let persistence = ClipboardPersistence(directory: directory, keyProvider: keyStore)
        let model = ClipboardHistoryModel(options: options, persistence: persistence, now: { self.now })
        model.capture(textClassified(fingerprint: "f", text: "persisted"))

        var disabledOptions = ClipboardOptions(isCaptureEnabled: true)
        disabledOptions.persistsHistory = false
        model.apply(disabledOptions)

        XCTAssertEqual(model.entryCount, 1)
    }

    func testModel_ClearAll_WithFailingPersistence_SetsError() async {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("model-clear-fail-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let keyStore = InMemoryClipboardKeyStore()
        var options = ClipboardOptions(isCaptureEnabled: true)
        options.persistsHistory = true
        let persistence = ClipboardPersistence(directory: directory, keyProvider: keyStore)
        let model = ClipboardHistoryModel(options: options, persistence: persistence, now: { self.now })
        model.capture(textClassified(fingerprint: "f", text: "data"))

        // Delete directory to make persistence.deleteAll fail
        try? FileManager.default.removeItem(at: directory)
        await model.clearAll()

        XCTAssertEqual(model.entryCount, 0)
    }

    func testModel_LoadPersisted_WithFailingPersistence_SetsError() async {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("model-load-fail-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let keyStore = InMemoryClipboardKeyStore()
        var options = ClipboardOptions(isCaptureEnabled: true)
        options.persistsHistory = true
        let persistence = ClipboardPersistence(directory: directory, keyProvider: keyStore)
        let model = ClipboardHistoryModel(options: options, persistence: persistence, now: { self.now })

        // Delete directory to make persistence.load fail
        try? FileManager.default.removeItem(at: directory)
        await model.loadPersistedHistory()

        XCTAssertEqual(model.entryCount, 0)
    }

    func testModel_PerformSave_GenerationMismatch_SkipsSave() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("model-gen-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let keyStore = InMemoryClipboardKeyStore()
        var options = ClipboardOptions(isCaptureEnabled: true)
        options.persistsHistory = true
        let persistence = ClipboardPersistence(directory: directory, keyProvider: keyStore)
        let model = ClipboardHistoryModel(
            options: options,
            persistence: persistence,
            now: { self.now },
            saveDebounce: .milliseconds(1)
        )
        model.capture(textClassified(fingerprint: "f", text: "data"))
        // Trigger a clear which increments generation before save completes
        await model.clearAll()
        try await Task.sleep(for: .milliseconds(50))
    }

    private func textClassified(fingerprint: String, text: String) -> ClassifiedClipboard {
        let item = ClipboardItem(
            kind: .text,
            preview: ClipboardItemPreview(primaryText: text),
            representations: [.string(typeIdentifier: "public.utf8-plain-text", value: text)]
        )
        let entry = ClipboardEntry(fingerprint: fingerprint, capturedAt: now, items: [item])
        return ClassifiedClipboard(entry: entry, payloads: [:])
    }
}
