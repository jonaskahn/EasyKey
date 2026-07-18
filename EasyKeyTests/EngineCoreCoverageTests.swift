@testable import EasyEngineCore
import XCTest

/// Targeted tests closing the last reachable coverage gaps in EasyEngineCore.
/// Each test names the branch it exercises so future edits keep the intent clear.
final class EngineCoreCoverageTests: XCTestCase {
    private let base = Date(timeIntervalSince1970: 1_700_000_000)

    // MARK: - VietnameseEngine fallbacks (VNI)

    func testAddMark_WithoutVowel_FallsThroughAsPassThrough() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(inputMethod: .vni))
        _ = engine.process(event: .char("b"))
        _ = engine.process(event: .char("7")) // horn mark, but no vowel to receive it
        XCTAssertEqual(engine.currentBuffer, "b7")
    }

    func testTransformDStroke_OnEmptyBuffer_FallsThroughAsPassThrough() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(inputMethod: .vni))
        _ = engine.process(event: .char("9")) // stroke key with nothing to stroke
        XCTAssertEqual(engine.currentBuffer, "9")
    }

    // MARK: - Word-break on a whitespace *character* event

    func testWhitespaceCharacter_FlushesBufferAsWordBoundary() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("a"))
        // A non-space whitespace character arrives as a character event, not a .space key.
        let result = engine.process(event: .char("\u{00A0}"))
        XCTAssertEqual(result.sessionEffect, .resetSession)
        XCTAssertEqual(engine.currentBuffer, "")
    }

    // MARK: - SmartSwitch identity

    func testStableKey_WhenAllFieldsEmpty_ReturnsNil() {
        let identity = ApplicationIdentity()
        XCTAssertNil(identity.stableKey)
    }

    func testStableKey_WhenOnlyNameSet_ReturnsNameKey() {
        let identity = ApplicationIdentity(name: "Notes")
        XCTAssertEqual(identity.stableKey, "name:Notes")
    }

    // MARK: - MacroStore import & validation

    func testPreviewImport_LineFailingValidation_IsUnparseable() throws {
        let store = MacroStore()
        // Well-formed 3 fields, but empty trigger fails validateFields.
        let preview = try store.previewImport("\texpansion\t1")
        XCTAssertEqual(preview.unparseableRecords, ["\texpansion\t1"])
        XCTAssertTrue(preview.additions.isEmpty)
    }

    func testAdd_ExpansionWithNewline_ThrowsInvalidImportLine() {
        let store = MacroStore()
        XCTAssertThrowsError(try store.add(trigger: "sig", expansion: "line1\nline2")) { error in
            XCTAssertEqual(error as? MacroStoreError, .invalidImportLine(0))
        }
    }

    func testApplyRename_WhenFirstCandidateTaken_IncrementsSuffix() throws {
        let store = MacroStore()
        try store.add(trigger: "btw", expansion: "by the way")
        try store.add(trigger: "btw 2", expansion: "occupied suffix")
        // Import a conflicting "btw"; resolving with rename must skip "btw 2" to "btw 3".
        let preview = try store.previewImport("btw\tsomething else\t1")
        let conflict = try XCTUnwrap(preview.conflicts.first)
        try store.apply(preview, resolving: [conflict.imported.id: .rename])
        XCTAssertTrue(store.macros.contains { $0.trigger == "btw 3" })
    }

    // MARK: - ClipboardHistory pin & remove

    func testSetPinned_OnAlreadyPinnedEntry_ReturnsUpdatedWithoutChange() {
        var history = ClipboardHistory(entries: [entry("pinned", fingerprint: "f1", pinned: true)])
        let id = history.entries[0].id
        XCTAssertEqual(history.setPinned(true, entryID: id, now: base), .updated)
        XCTAssertEqual(history.pinnedCount, 1)
    }

    func testRemove_ExistingEntry_DropsIt() throws {
        var history = ClipboardHistory(entries: [
            entry("a", fingerprint: "f1"),
            entry("b", fingerprint: "f2"),
        ])
        let id = try XCTUnwrap(history.entries.first { $0.fingerprint == "f1" }?.id)
        history.remove(entryID: id)
        XCTAssertEqual(history.entries.map(\.fingerprint), ["f2"])
    }

    // MARK: - ClipboardEntry searchable text branches

    func testSearchableText_IncludesSecondaryFileNameTypeLabelAndFileHost() throws {
        let preview = ClipboardItemPreview(
            primaryText: "Primary",
            secondaryText: "Secondary",
            fileName: "notes.txt",
            typeLabel: "Plain Text"
        )
        let fileURL = try XCTUnwrap(URL(string: "https://example.com/path/report.pdf"))
        let item = ClipboardItem(
            kind: .mixed,
            preview: preview,
            representations: [
                .string(typeIdentifier: "public.text", value: "StringValue"),
                .fileURL(fileURL),
                .data(typeIdentifier: "public.png", payloadReference: "ref-1"),
            ]
        )
        let entry = ClipboardEntry(fingerprint: "f", capturedAt: base, items: [item])
        let text = entry.searchableText
        for token in ["Primary", "Secondary", "notes.txt", "Plain Text", "StringValue", "report.pdf", "example.com"] {
            XCTAssertTrue(text.contains(token), "missing token: \(token)")
        }
    }

    // MARK: - SettingsRepository migration & write failure

    @MainActor
    func testLoad_FileWithOlderSchema_MigratesToCurrentVersion() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ek-migrate-\(UUID().uuidString).json")
        var old = EasyKeySettings.defaults
        old.schemaVersion = 0
        try JSONEncoder().encode(old).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let repo = SettingsRepository(fileURL: url)
        repo.load()
        XCTAssertEqual(repo.settings.schemaVersion, EasyKeySettings.currentSchemaVersion)
    }

    @MainActor
    func testSaveNow_WhenDirectoryIsReadOnly_SwallowsWriteFailure() async throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ek-ro-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: dir.path)
            try? FileManager.default.removeItem(at: dir)
        }
        // Read-only parent: the atomic temp write throws and is logged, not fatal.
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: dir.path)

        let repo = SettingsRepository(fileURL: dir.appendingPathComponent("settings.json"))
        await repo.saveNow()
        XCTAssertFalse(FileManager.default.fileExists(atPath: dir.appendingPathComponent("settings.json").path))
    }

    @MainActor
    func testSaveNow_WhenParentDirectoryCannotBeCreated_DoesNotCrash() async throws {
        // Place a regular file where a parent directory would need to exist.
        let blocker = FileManager.default.temporaryDirectory
            .appendingPathComponent("ek-blocker-\(UUID().uuidString)")
        try Data().write(to: blocker)
        defer { try? FileManager.default.removeItem(at: blocker) }

        let target = blocker.appendingPathComponent("child/settings.json")
        let repo = SettingsRepository(fileURL: target)
        await repo.saveNow()
        XCTAssertFalse(FileManager.default.fileExists(atPath: target.path))
    }

    // MARK: - Helpers

    private func entry(_ text: String, fingerprint: String, pinned: Bool = false) -> ClipboardEntry {
        let item = ClipboardItem(
            kind: .text,
            preview: ClipboardItemPreview(primaryText: text),
            representations: [.string(typeIdentifier: "public.utf8-plain-text", value: text)]
        )
        return ClipboardEntry(
            fingerprint: fingerprint,
            capturedAt: base,
            isPinned: pinned,
            pinnedAt: pinned ? base : nil,
            items: [item]
        )
    }
}
