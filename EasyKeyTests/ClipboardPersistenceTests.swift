import CryptoKit
import EasyEngineCore
@testable import EasyKey
import XCTest

final class ClipboardPersistenceTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("clipboard-persistence-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testRoundTripRestoresEntriesAndPayloads() async throws {
        let keyStore = InMemoryClipboardKeyStore()
        let persistence = ClipboardPersistence(directory: directory, keyProvider: keyStore)
        let entry = imageEntry(reference: "ref-1")
        let payloads = ["ref-1": Data("secret-bytes".utf8)]

        try await persistence.save(entries: [entry], payloads: payloads)
        let state = try await persistence.load()

        XCTAssertEqual(state.entries, [entry])
        XCTAssertEqual(state.payloads, payloads)
    }

    func testManifestCiphertextDoesNotContainPlaintext() async throws {
        let persistence = ClipboardPersistence(directory: directory, keyProvider: InMemoryClipboardKeyStore())
        let marker = "UNIQUE-PLAINTEXT-MARKER-42"
        try await persistence.save(entries: [textEntry(marker)], payloads: [:])

        let manifest = try Data(contentsOf: directory.appendingPathComponent("manifest.ekc"))
        XCTAssertFalse(manifest.range(of: Data(marker.utf8)) != nil)
    }

    func testWrongKeyFailsClosed() async throws {
        let persistence = ClipboardPersistence(directory: directory, keyProvider: InMemoryClipboardKeyStore())
        try await persistence.save(entries: [textEntry("hello")], payloads: [:])

        let wrongKey = InMemoryClipboardKeyStore(key: SymmetricKey(size: .bits256))
        let reader = ClipboardPersistence(directory: directory, keyProvider: wrongKey)
        do {
            _ = try await reader.load()
            XCTFail("Expected decryption failure")
        } catch {
            XCTAssertEqual(error as? ClipboardPersistenceError, .decryptionFailed)
        }
    }

    func testTamperedManifestFailsClosed() async throws {
        let keyStore = InMemoryClipboardKeyStore()
        let persistence = ClipboardPersistence(directory: directory, keyProvider: keyStore)
        try await persistence.save(entries: [textEntry("hello")], payloads: [:])

        let manifestURL = directory.appendingPathComponent("manifest.ekc")
        var bytes = try Data(contentsOf: manifestURL)
        bytes[bytes.count - 1] ^= 0xFF
        try bytes.write(to: manifestURL)

        let reader = ClipboardPersistence(directory: directory, keyProvider: keyStore)
        do {
            _ = try await reader.load()
            XCTFail("Expected decryption failure")
        } catch {
            XCTAssertEqual(error as? ClipboardPersistenceError, .decryptionFailed)
        }
    }

    func testMissingManifestReturnsEmpty() async throws {
        let persistence = ClipboardPersistence(directory: directory, keyProvider: InMemoryClipboardKeyStore())
        let state = try await persistence.load()
        XCTAssertEqual(state, .empty)
    }

    func testMissingKeyForExistingManifestFailsClosed() async throws {
        let keyStore = InMemoryClipboardKeyStore()
        let persistence = ClipboardPersistence(directory: directory, keyProvider: keyStore)
        try await persistence.save(entries: [textEntry("hello")], payloads: [:])
        try keyStore.deleteKey()

        do {
            _ = try await persistence.load()
            XCTFail("Expected key-unavailable failure")
        } catch {
            XCTAssertEqual(error as? ClipboardPersistenceError, .keyUnavailable)
        }
    }

    func testOrphanPayloadsAreRemovedOnResave() async throws {
        let persistence = ClipboardPersistence(directory: directory, keyProvider: InMemoryClipboardKeyStore())
        try await persistence.save(entries: [imageEntry(reference: "ref-1")], payloads: ["ref-1": Data([1, 2, 3])])
        try await persistence.save(entries: [imageEntry(reference: "ref-2")], payloads: ["ref-2": Data([4, 5, 6])])

        let payloadDir = directory.appendingPathComponent("payloads", isDirectory: true)
        let files = try FileManager.default.contentsOfDirectory(atPath: payloadDir.path)
            .filter { $0.hasSuffix(".ekp") }
        XCTAssertEqual(files.count, 1)
    }

    func testDeleteAllRemovesFilesAndKey() async throws {
        let keyStore = InMemoryClipboardKeyStore()
        let persistence = ClipboardPersistence(directory: directory, keyProvider: keyStore)
        try await persistence.save(entries: [imageEntry(reference: "ref-1")], payloads: ["ref-1": Data([1])])

        try await persistence.deleteAll()

        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path))
        XCTAssertNil(try keyStore.existingKey())
    }

    // MARK: - Fixtures

    private func textEntry(_ text: String) -> ClipboardEntry {
        let item = ClipboardItem(
            kind: .text,
            preview: ClipboardItemPreview(primaryText: text),
            representations: [.string(typeIdentifier: "public.utf8-plain-text", value: text)]
        )
        return ClipboardEntry(fingerprint: "fp-\(text)", capturedAt: fixedDate, items: [item])
    }

    private func imageEntry(reference: String) -> ClipboardEntry {
        let item = ClipboardItem(
            kind: .image,
            preview: ClipboardItemPreview(primaryText: "PNG image", typeLabel: "PNG"),
            representations: [.data(typeIdentifier: "public.png", payloadReference: reference)]
        )
        return ClipboardEntry(fingerprint: "fp-\(reference)", capturedAt: fixedDate, items: [item])
    }

    private let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
}
