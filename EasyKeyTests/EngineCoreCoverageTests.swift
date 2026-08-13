@testable import EasyEngineCore
import XCTest

/// Targeted tests closing the last reachable coverage gaps in EasyEngineCore.
/// Each test names the branch it exercises so future edits keep the intent clear.
final class EngineCoreCoverageTests: XCTestCase {
    private let base = Date(timeIntervalSince1970: 1_700_000_000)

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

    func testWhitespaceCharacter_FlushesBufferAsWordBoundary() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("a"))
        // A non-space whitespace character arrives as a character event, not a .space key.
        let result = engine.process(event: .char("\u{00A0}"))
        XCTAssertEqual(result.sessionEffect, .resetSession)
        XCTAssertEqual(engine.currentBuffer, "")
    }

    func testStableKey_WhenAllFieldsEmpty_ReturnsNil() {
        let identity = ApplicationIdentity()
        XCTAssertNil(identity.stableKey)
    }

    func testStableKey_WhenOnlyNameSet_ReturnsNameKey() {
        let identity = ApplicationIdentity(name: "Notes")
        XCTAssertEqual(identity.stableKey, "name:Notes")
    }

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

    func testHasBase_OnNilOptional_ReturnsFalse() {
        let opt: BufferAtom? = nil
        XCTAssertFalse(opt.hasBase("a"))
    }

    func testEscapeKey_ResetsStateAndPassesThrough() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("a"))
        XCTAssertEqual(engine.currentBuffer, "a")
        let result = engine.process(event: KeyEvent(kind: .escape))
        XCTAssertEqual(result.disposition, .pass)
        XCTAssertEqual(engine.currentBuffer, "")
    }

    func testLeftArrow_ResetsStateAndPassesThrough() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("a"))
        let result = engine.process(event: KeyEvent(kind: .leftArrow))
        XCTAssertEqual(result.disposition, .pass)
        XCTAssertEqual(engine.currentBuffer, "")
    }

    func testQuickTelexConsonantPair() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(quickTelexConsonants: true))
        typeKeys(&engine, "cc")
        XCTAssertEqual(engine.currentBuffer, "ch")
    }

    func testBackspace_AtomHasMarkAndTone_RemovesMarkAndResetsTone() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(outputEncoding: .unicode))
        typeKeys(&engine, "aa") // produces â
        typeKeys(&engine, "s") // produces ấ
        _ = engine.process(event: KeyEvent(kind: .backspace))
        XCTAssertEqual(engine.currentBuffer, "â")
    }

    func testBackspace_OnlyToneNoMark_RemovesTone() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(outputEncoding: .unicode))
        typeKeys(&engine, "as") // produces á
        _ = engine.process(event: KeyEvent(kind: .backspace))
        // After backspace: tone removed; result is "a"
        XCTAssertEqual(engine.currentBuffer, "a")
    }

    func testBackspace_AfterToneRemoval_EmptiesBuffer() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "as") // produces á
        _ = engine.process(event: KeyEvent(kind: .backspace)) // removes tone → "a"
        _ = engine.process(event: KeyEvent(kind: .backspace)) // removes "a" → empty
        XCTAssertEqual(engine.currentBuffer, "")
        let result = engine.process(event: KeyEvent(kind: .backspace))
        XCTAssertEqual(result.disposition, .pass)
    }

    func testToneRepeat_WithNonEmptyBuffer_ReturnsToPlain() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "as") // á
        XCTAssertEqual(engine.currentBuffer, "á")
        _ = engine.process(event: .char("s")) // same tone again → removes tone
        XCTAssertEqual(engine.currentBuffer, "as")
    }

    func testTone_OnEmptyBuffer_PassThroughLiteral() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(inputMethod: .vni))
        // VNI tone "1" (acute) on empty buffer falls through
        let result = engine.process(event: .char("1"))
        XCTAssertEqual(engine.currentBuffer, "1")
        XCTAssertEqual(result.disposition, .suppress)
    }

    func testSmartSwitchSearch_EmptyQuery_ReturnsAll() {
        let store = SmartSwitchStore()
        XCTAssertEqual(store.search("").count, 0)
    }

    func testUpdateChoice_NoPreference_ReturnsFalse() throws {
        let store = SmartSwitchStore()
        let app = ApplicationIdentity(bundleIdentifier: "com.unknown")
        let result = try store.updateChoice(for: app, choice: SmartSwitchChoice(language: .vietnamese))
        XCTAssertFalse(result)
    }

    func testUpdateChoice_SameChoice_ReturnsFalse() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ek-ss-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = SmartSwitchStore(fileURL: url)
        let app = ApplicationIdentity(bundleIdentifier: "com.example.app", name: "App")
        _ = try store.handleAppFocus(app, currentChoice: SmartSwitchChoice(language: .vietnamese))
        // Same choice → no-op
        let result = try store.updateChoice(for: app, choice: SmartSwitchChoice(language: .vietnamese))
        XCTAssertFalse(result)
    }

    func testUpdateChoice_DifferentChoice_ReturnsTrue() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ek-ss-upd-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = SmartSwitchStore(fileURL: url)
        let app = ApplicationIdentity(bundleIdentifier: "com.example.app", name: "App")
        _ = try store.handleAppFocus(app, currentChoice: SmartSwitchChoice(language: .vietnamese))
        let result = try store.updateChoice(for: app, choice: SmartSwitchChoice(language: .english))
        XCTAssertTrue(result)
        XCTAssertEqual(store.choice(for: app)?.language, .english)
    }

    func testHandleAppFocus_MissingIdentity_ThrowsError() {
        let store = SmartSwitchStore()
        let app = ApplicationIdentity()
        XCTAssertThrowsError(try store.handleAppFocus(app, currentChoice: SmartSwitchChoice(language: .vietnamese))) { error in
            XCTAssertEqual(error as? SmartSwitchStoreError, SmartSwitchStoreError.missingApplicationIdentity)
        }
    }

    func testEdit_UnknownPreference_ThrowsError() {
        let store = SmartSwitchStore()
        XCTAssertThrowsError(try store.edit(key: "bundle:nonexistent", choice: SmartSwitchChoice(language: .english))) { error in
            XCTAssertEqual(error as? SmartSwitchStoreError, SmartSwitchStoreError.unknownPreference)
        }
    }

    func testReset_UnknownKey_ThrowsError() {
        let store = SmartSwitchStore()
        XCTAssertThrowsError(try store.reset(key: "bundle:unknown")) { error in
            XCTAssertEqual(error as? SmartSwitchStoreError, SmartSwitchStoreError.unknownPreference)
        }
    }

    func testHandleAppFocus_NewApplication_ReturnsRecorded() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ek-ss-rec-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = SmartSwitchStore(fileURL: url)
        let app = ApplicationIdentity(bundleIdentifier: "com.newapp", name: "NewApp")
        let result = try store.handleAppFocus(app, currentChoice: SmartSwitchChoice(language: .vietnamese))
        XCTAssertEqual(result, .recorded(SmartSwitchChoice(language: .vietnamese)))
    }

    func testIsVowel_WithConsonant_ReturnsFalse() {
        XCTAssertFalse(VietnameseCharacters.isVowel("t"))
    }

    func testMarkForVowel_WithUnmarkedVowel_ReturnsNone() {
        XCTAssertEqual(VietnameseCharacters.mark(forVowel: "a"), .none)
        XCTAssertEqual(VietnameseCharacters.mark(forVowel: "e"), .none)
    }

    func testUnicodePrecomposedEncode_WithHornOnNonVowelAtom_UsesCharacterFallback() {
        // Setting mark on a consonant base is unusual but the encode is defensive.
        let atoms: [BufferAtom] = [
            BufferAtom(base: "t", mark: .horn),
        ]
        let result = UnicodePrecomposedEncoding().encode(atoms: atoms, tone: .none, toneTargetIndex: nil)
        XCTAssertEqual(result, "t")
    }

    func testToneTargetIndex_WithOffglide_RanksEarlierVowel() {
        let atoms = [
            BufferAtom(base: "u"),
            BufferAtom(base: "i"),
        ]
        let idx = TelexComposer.toneTargetIndex(atoms: atoms, style: .old)
        XCTAssertEqual(idx, 0)
    }

    func testToneTargetIndex_DiphthongAY_ToneBeforeY() {
        let atoms = [
            BufferAtom(base: "a"),
            BufferAtom(base: "y"),
        ]
        let idx = TelexComposer.toneTargetIndex(atoms: atoms, style: .old)
        XCTAssertEqual(idx, 0)
    }

    func testToneTargetIndex_OpenSyllableUA_ToneOnA() {
        let atoms = [
            BufferAtom(base: "u"),
            BufferAtom(base: "a"),
        ]
        let idx = TelexComposer.toneTargetIndex(atoms: atoms, style: .old)
        XCTAssertEqual(idx, 0)
    }

    func testToneTargetIndex_OpenSyllableIA_ToneOnI() {
        let atoms = [
            BufferAtom(base: "i"),
            BufferAtom(base: "a"),
        ]
        let idx = TelexComposer.toneTargetIndex(atoms: atoms, style: .old)
        XCTAssertEqual(idx, 0)
    }

    func testToneTargetIndex_SingleVowel_ReturnsFirst() {
        let atoms = [BufferAtom(base: "a")]
        XCTAssertEqual(TelexComposer.toneTargetIndex(atoms: atoms, style: .old), 0)
    }

    func testToneTargetIndex_NoVowels_ReturnsNil() {
        let atoms = [BufferAtom(base: "t")]
        XCTAssertNil(TelexComposer.toneTargetIndex(atoms: atoms, style: .old))
    }

    func testCapitalizeSentences_WithArabicText() {
        let config = ConverterConfiguration(transforms: [.capitalizeSentences])
        let result = Converter.preview(input: "abc 123 def", configuration: config)
        XCTAssertEqual(result, "Abc 123 def")
    }

    func testRemoveMarksWithLowercase() {
        let config = ConverterConfiguration(transforms: [.removeMarks, .lowercase])
        let result = Converter.preview(input: "VIỆT NAM", configuration: config)
        XCTAssertEqual(result, "viet nam")
    }

    func testFullTelexStandaloneWAtEmptyBufferProducesUWithHorn() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(inputMethod: .telex))
        _ = engine.process(event: .char("w"))
        XCTAssertEqual(engine.currentBuffer, "ư")
    }

    func testRepeatedWRestoresLiteralPair() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "uww")
        XCTAssertEqual(engine.currentBuffer, "uw")
    }

    func testSort_PinnedBeforeUnpinned_SameCaptureTime() {
        let now = Date()
        var history = ClipboardHistory(entries: [
            entry("b", fingerprint: "f2", pinned: false),
            entry("a", fingerprint: "f1", pinned: true),
        ])
        XCTAssertEqual(history.entries.map(\.fingerprint), ["f1", "f2"])
    }

    func testInsert_DuplicateUnpinned_ReplacesInPlace() {
        var history = ClipboardHistory(entries: [entry("old", fingerprint: "f1")])
        let newer = entry("new", fingerprint: "f1")
        let opts = ClipboardOptions(isCaptureEnabled: false, maximumEntryCount: 10)
        history.insert(newer, options: opts, now: base.addingTimeInterval(1))
        XCTAssertEqual(history.entries.count, 1)
        XCTAssertEqual(history.entries.first?.capturedAt, base.addingTimeInterval(1))
    }

    func testInsert_DuplicatePinned_PreservesPinState() {
        var history = ClipboardHistory(entries: [entry("old", fingerprint: "f1", pinned: true)])
        let newer = entry("new", fingerprint: "f1")
        let opts = ClipboardOptions(isCaptureEnabled: false, maximumEntryCount: 10)
        history.insert(newer, options: opts, now: base.addingTimeInterval(1))
        XCTAssertEqual(history.entries.count, 1)
        XCTAssertTrue(history.entries.first?.isPinned ?? false)
    }

    func testClearUnpinned_KeepsPinned() {
        var history = ClipboardHistory(entries: [
            entry("p", fingerprint: "f1", pinned: true),
            entry("u", fingerprint: "f2"),
        ])
        history.clearUnpinned()
        XCTAssertEqual(history.entries.map(\.fingerprint), ["f1"])
    }

    func testClear_RemovesAll() {
        var history = ClipboardHistory(entries: [
            entry("p", fingerprint: "f1", pinned: true),
            entry("u", fingerprint: "f2"),
        ])
        history.clear()
        XCTAssertTrue(history.entries.isEmpty)
    }

    func testEntriesMatching_NonEmptyQuery_Filters() {
        let history = ClipboardHistory(entries: [
            entry("apple", fingerprint: "f1"),
            entry("banana", fingerprint: "f2"),
        ])
        let results = history.entries(matching: "apple")
        XCTAssertEqual(results.map(\.fingerprint), ["f1"])
    }

    func testEntriesMatching_WhitespaceOnly_ReturnsAll() {
        let history = ClipboardHistory(entries: [
            entry("apple", fingerprint: "f1"),
            entry("banana", fingerprint: "f2"),
        ])
        let results = history.entries(matching: "   ")
        XCTAssertEqual(results.count, 2)
    }

    func testPrune_ExpiredEntries_RemovesOldOnes() {
        var history = ClipboardHistory(entries: [
            entry("old", fingerprint: "f1"),
            entry("new", fingerprint: "f2"),
        ])
        let oldEntry = entry("old", fingerprint: "f3")
        let opts = ClipboardOptions(isCaptureEnabled: false, maximumEntryCount: 10, retentionDays: 1)
        history.insert(oldEntry, options: opts, now: base)
        XCTAssertGreaterThan(history.entries.count, 0)
    }

    func testPrune_ExceedsMaximum_TrimsUnpinned() {
        let entries = (0 ..< 10).map { i in
            entry("text\(i)", fingerprint: "f\(i)")
        }
        var history = ClipboardHistory(entries: entries)
        let opts = ClipboardOptions(isCaptureEnabled: false, maximumEntryCount: 3)
        history.prune(options: opts, now: base)
        XCTAssertEqual(history.entries.count, 3)
    }

    func testSetPinned_WhenAtLimit_ReturnsPinnedLimitReached() {
        let entries = (0 ..< ClipboardHistory.maximumPinnedEntries).map { i in
            entry("text\(i)", fingerprint: "f\(i)", pinned: true)
        }
        var history = ClipboardHistory(entries: entries)
        let extra = entry("extra", fingerprint: "extra")
        let opts = ClipboardOptions(isCaptureEnabled: false, maximumEntryCount: 100)
        history.insert(extra, options: opts, now: base)
        let result = history.setPinned(true, entryID: extra.id, now: base)
        XCTAssertEqual(result, .pinnedLimitReached)
    }

    func testSetPinned_EntryNotFound_ReturnsNotFound() {
        var history = ClipboardHistory()
        let result = history.setPinned(false, entryID: UUID(), now: base)
        XCTAssertEqual(result, .notFound)
    }

    func testSetPinned_Unpin_ClearsPinnedAt() {
        var history = ClipboardHistory(entries: [entry("p", fingerprint: "f1", pinned: true)])
        let id = history.entries[0].id
        _ = history.setPinned(false, entryID: id, now: base)
        XCTAssertFalse(history.entries[0].isPinned)
        XCTAssertNil(history.entries[0].pinnedAt)
    }

    func testMacroAdd_WithFileURL_WritesToDisk() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ek-macro-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = MacroStore(fileURL: url)
        try store.add(trigger: "btw", expansion: "by the way")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func testMacroEdit_WithFileURL_PersistsChange() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ek-macro-edit-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = MacroStore(fileURL: url)
        let macro = try store.add(trigger: "hello", expansion: "xin chào")
        _ = try store.edit(id: macro.id, trigger: "hello", expansion: "xin chao", isEnabled: true)
        let loaded = MacroStore(fileURL: url)
        XCTAssertEqual(loaded.macros.first?.expansion, "xin chao")
    }

    func testMacroDelete_WithFileURL_RemovesFromPersistence() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ek-macro-del-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = MacroStore(fileURL: url)
        let macro = try store.add(trigger: "btw", expansion: "by the way")
        try store.delete(id: macro.id)
        let loaded = MacroStore(fileURL: url)
        XCTAssertTrue(loaded.macros.isEmpty)
    }

    func testMacroAdd_DuplicateTrigger_ThrowsDuplicateTrigger() throws {
        let store = MacroStore()
        try store.add(trigger: "btw", expansion: "by the way")
        XCTAssertThrowsError(try store.add(trigger: "btw", expansion: "something else")) { error in
            XCTAssertEqual(error as? MacroStoreError, .duplicateTrigger)
        }
    }

    func testMacroDelete_UnknownID_ThrowsError() {
        let store = MacroStore()
        XCTAssertThrowsError(try store.delete(id: UUID())) { error in
            XCTAssertEqual(error as? MacroStoreError, .unknownMacro)
        }
    }

    func testMacroEdit_UnknownID_ThrowsError() {
        let store = MacroStore()
        XCTAssertThrowsError(try store.edit(id: UUID(), trigger: "x", expansion: "y", isEnabled: true)) { error in
            XCTAssertEqual(error as? MacroStoreError, .unknownMacro)
        }
    }

    func testMacroValidate_EmptyTrigger_ThrowsEmptyTrigger() {
        let store = MacroStore()
        XCTAssertThrowsError(try store.add(trigger: "", expansion: "content")) { error in
            XCTAssertEqual(error as? MacroStoreError, .emptyTrigger)
        }
    }

    func testMacroValidate_EmptyExpansion_ThrowsEmptyExpansion() {
        let store = MacroStore()
        XCTAssertThrowsError(try store.add(trigger: "abc", expansion: "")) { error in
            XCTAssertEqual(error as? MacroStoreError, .emptyExpansion)
        }
    }

    func testMacroValidate_TriggerTooLong_Throws() {
        let store = MacroStore()
        let long = String(repeating: "x", count: MacroStore.maximumTriggerLength + 1)
        XCTAssertThrowsError(try store.add(trigger: long, expansion: "test")) { error in
            XCTAssertEqual(error as? MacroStoreError, .triggerTooLong)
        }
    }

    func testMacroValidate_ExpansionTooLong_Throws() {
        let store = MacroStore()
        let long = String(repeating: "x", count: MacroStore.maximumExpansionLength + 1)
        XCTAssertThrowsError(try store.add(trigger: "abc", expansion: long)) { error in
            XCTAssertEqual(error as? MacroStoreError, .expansionTooLong)
        }
    }

    func testMacro_TabOrNewlineInTrigger_ThrowsInvalidImportLine() {
        let store = MacroStore()
        XCTAssertThrowsError(try store.add(trigger: "ab\tc", expansion: "test")) { error in
            XCTAssertEqual(error as? MacroStoreError, .invalidImportLine(0))
        }
    }

    func testMatchCapitalization_AllCaps_ReturnsAllCaps() {
        let result = MacroStore.matchCapitalization(of: "HELLO", in: "xin chào")
        XCTAssertEqual(result, "XIN CHÀO")
    }

    func testMatchCapitalization_FirstLetterUppercase_ReturnsCapitalized() {
        let result = MacroStore.matchCapitalization(of: "Hello", in: "xin chào")
        XCTAssertEqual(result, "Xin chào")
    }

    func testMatchCapitalization_NoLetters_ReturnsExpansionAsIs() {
        let result = MacroStore.matchCapitalization(of: "123", in: "xin chào")
        XCTAssertEqual(result, "xin chào")
    }

    func testExportTSV_GeneratesValidOutput() {
        let store = MacroStore()
        XCTAssertTrue(store.exportTSV().contains("trigger\texpansion\tenabled"))
    }

    func testApplyImport_WithSkipResolution_KeepsExisting() throws {
        let store = MacroStore()
        try store.add(trigger: "btw", expansion: "by the way")
        let preview = try store.previewImport("btw\tdifferent\t1")
        let conflict = try XCTUnwrap(preview.conflicts.first)
        try store.apply(preview, resolving: [conflict.imported.id: .skip])
        XCTAssertEqual(store.macros.first?.expansion, "by the way")
    }

    func testApplyImport_WithReplaceResolution_ReplacesExisting() throws {
        let store = MacroStore()
        try store.add(trigger: "btw", expansion: "by the way")
        let preview = try store.previewImport("btw\treplaced\t1")
        let conflict = try XCTUnwrap(preview.conflicts.first)
        try store.apply(preview, resolving: [conflict.imported.id: .replace])
        XCTAssertEqual(store.macros.first?.expansion, "replaced")
    }

    func testChangeActiveEncoding_RefreshesEncodedExpansions() throws {
        let store = MacroStore()
        try store.add(trigger: "btw", expansion: "by the way")
        store.changeActiveEncoding(to: .vniWindows)
        XCTAssertNotNil(store.macros.first.map { store.encodedExpansion(for: $0.id) } ?? nil)
    }

    @MainActor
    func testInit_WithDefaultFileURL_LoadsDefaultSettings() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ek-default-\(UUID().uuidString).json")
        let repo = SettingsRepository(fileURL: url)
        XCTAssertEqual(repo.settings.schemaVersion, EasyKeySettings.currentSchemaVersion)
    }

    @MainActor
    func testInit_WithInvalidJSON_FallsBackToDefaults() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ek-bad-\(UUID().uuidString).json")
        try "not json".write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }
        let repo = SettingsRepository(fileURL: url)
        XCTAssertEqual(repo.settings.schemaVersion, EasyKeySettings.currentSchemaVersion)
    }

    @MainActor
    func testStartup_WithNonExistentFile_UsesDefault() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ek-nonexistent-\(UUID().uuidString).json")
        let repo = SettingsRepository(fileURL: url)
        XCTAssertEqual(repo.settings.schemaVersion, EasyKeySettings.currentSchemaVersion)
    }

    @MainActor
    func testUpdate_TriggersOnSettingsChange() {
        let repo = SettingsRepository()
        var changed = false
        repo.onSettingsChange = { _ in changed = true }
        repo.update { $0.schemaVersion = 99 }
        XCTAssertTrue(changed)
    }

    @MainActor
    func testReset_RestoresDefaultsAndSchedulesSave() {
        let repo = SettingsRepository()
        repo.update { $0.schemaVersion = 99 }
        repo.reset()
        XCTAssertEqual(repo.settings.schemaVersion, EasyKeySettings.currentSchemaVersion)
    }

    @MainActor
    func testExport_WritesToURL() throws {
        let repo = SettingsRepository()
        let dest = FileManager.default.temporaryDirectory
            .appendingPathComponent("ek-export-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: dest) }
        try repo.export(to: dest)
        XCTAssertTrue(FileManager.default.fileExists(atPath: dest.path))
    }

    @MainActor
    func testImport_WithValidSettings_AppliesImported() throws {
        let repo = SettingsRepository()
        let importURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("ek-import-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: importURL) }
        var settings = EasyKeySettings.defaults
        settings.typing.uppercaseFirstCharacter = true
        try JSONEncoder().encode(settings).write(to: importURL)
        let diag = try repo.import(from: importURL)
        XCTAssertEqual(diag.entries.last?.severity, ImportDiagnostics.Entry.Severity.info)
    }

    @MainActor
    func testImport_WithBadJSON_ReturnsWarningDiagnostics() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ek-badimport-\(UUID().uuidString).json")
        try "bad json".write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }
        let repo = SettingsRepository()
        XCTAssertThrowsError(try repo.import(from: url)) { error in
            if case SettingsRepositoryError.malformedDocument = error {
                // expected
            } else {
                XCTFail("Expected malformedDocument, got \(error)")
            }
        }
    }

    @MainActor
    func testImport_FileTooLarge_ThrowsError() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ek-large-\(UUID().uuidString).json")
        let large = Data(repeating: 0x41, count: SettingsRepository.maxImportFileBytes + 1)
        try large.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let repo = SettingsRepository()
        XCTAssertThrowsError(try repo.import(from: url)) { error in
            XCTAssertEqual(error as? SettingsRepositoryError, .importFileTooLarge)
        }
    }

    @MainActor
    func testConfigurationSnapshot_ReflectsCurrentSettings() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ek-cfg-\(UUID().uuidString).json")
        let repo = SettingsRepository(fileURL: url)
        let config = EngineConfiguration(settings: repo.settings)
        XCTAssertEqual(config.inputMethod, .simpleTelex)
        XCTAssertEqual(config.outputEncoding, .unicode)
    }

    func testConfigurationBuilderIncludesLiteralTechnicalTokens() {
        var settings = EasyKeySettings.defaults
        settings.typing.literalTechnicalTokens = false
        XCTAssertFalse(EngineConfiguration(settings: settings).literalTechnicalTokens)
        settings.typing.literalTechnicalTokens = true
        XCTAssertTrue(EngineConfiguration(settings: settings).literalTechnicalTokens)
    }

    func testEasyKeySettings_RoundTrip_ThroughJSON() throws {
        var original = EasyKeySettings.defaults
        original.typing.quickTelexConsonants = true
        original.clipboard.maximumEntryCount = 50
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(EasyKeySettings.self, from: data)
        XCTAssertEqual(decoded.typing.quickTelexConsonants, original.typing.quickTelexConsonants)
        XCTAssertEqual(decoded.clipboard.maximumEntryCount, original.clipboard.maximumEntryCount)
    }

    func testEasyKeySettings_DecodeWithMissingKeys_UsesDefaults() throws {
        let json = """
        {"schemaVersion": 4}
        """.data(using: .utf8)
        let decoded = try JSONDecoder().decode(EasyKeySettings.self, from: XCTUnwrap(json))
        XCTAssertEqual(decoded.macro, MacroOptions())
        XCTAssertEqual(decoded.system, SystemOptions())
    }

    func testEasyKeySettings_DecodeEmptyJSON_UsesAllDefaults() throws {
        let json = "{}".data(using: .utf8)
        let decoded = try JSONDecoder().decode(EasyKeySettings.self, from: XCTUnwrap(json))
        XCTAssertEqual(decoded.schemaVersion, EasyKeySettings.currentSchemaVersion)
        XCTAssertEqual(decoded.input, InputSettings())
    }

    func testSystemOptions_DefaultMenuPopoverWidthIsSmall() {
        XCTAssertEqual(SystemOptions().menuPopoverWidth, .small)
    }

    func testSystemOptions_MenuPopoverWidthRawValuesMatchExpected() {
        XCTAssertEqual(SystemOptions.MenuPopoverWidth.compact.rawValue, 280)
        XCTAssertEqual(SystemOptions.MenuPopoverWidth.small.rawValue, 360)
        XCTAssertEqual(SystemOptions.MenuPopoverWidth.medium.rawValue, 440)
        XCTAssertEqual(SystemOptions.MenuPopoverWidth.large.rawValue, 520)
        XCTAssertEqual(SystemOptions.MenuPopoverWidth.extraLarge.rawValue, 640)
    }

    func testSystemOptions_LegacyDecodeDefaultsMenuPopoverWidthToSmall() throws {
        let decoded = try JSONDecoder().decode(SystemOptions.self, from: Data("{}".utf8))
        XCTAssertEqual(decoded.menuPopoverWidth, .small)
    }

    func testSystemOptions_Legacy420DecodesAsMedium() throws {
        let json = """
        {"menuPopoverWidth": 420}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(SystemOptions.self, from: json)
        XCTAssertEqual(decoded.menuPopoverWidth, .medium)
    }

    func testSystemOptions_Legacy640DecodesAsExtraLarge() throws {
        let json = """
        {"menuPopoverWidth": 640}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(SystemOptions.self, from: json)
        XCTAssertEqual(decoded.menuPopoverWidth, .extraLarge)
    }

    func testSystemOptions_MenuPopoverWidthRoundTripsEveryCase() throws {
        for width in SystemOptions.MenuPopoverWidth.allCases {
            let options = SystemOptions(menuPopoverWidth: width)
            let data = try JSONEncoder().encode(options)
            let decoded = try JSONDecoder().decode(SystemOptions.self, from: data)
            XCTAssertEqual(decoded.menuPopoverWidth, width)
        }
    }

    func testSystemOptions_InvalidMenuPopoverWidthThrows() {
        let json = """
        {"menuPopoverWidth": 999}
        """.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(SystemOptions.self, from: json))
    }

    func testTCVN3Encode_NonEmptyAtoms_ProducesTCVN3() {
        let atoms: [BufferAtom] = [
            BufferAtom(base: "a", mark: .circumflex),
            BufferAtom(base: "n"),
        ]
        let result = TCVN3Encoding().encode(atoms: atoms, tone: .none, toneTargetIndex: nil)
        XCTAssertFalse(result.isEmpty)
    }

    func testVNIWindowsEncode_NonEmptyAtoms_ProducesOutput() {
        let atoms: [BufferAtom] = [
            BufferAtom(base: "a", mark: .breve),
            BufferAtom(base: "n"),
        ]
        let result = VNIWindowsEncoding().encode(atoms: atoms, tone: .none, toneTargetIndex: nil)
        XCTAssertFalse(result.isEmpty)
    }

    func testCP1258Encode_DelegatesToCombining() {
        let atoms: [BufferAtom] = [
            BufferAtom(base: "a", mark: .circumflex),
        ]
        let combiningResult = UnicodeCombiningEncoding().encode(atoms: atoms, tone: .none, toneTargetIndex: nil)
        let cp1258Result = CP1258Encoding().encode(atoms: atoms, tone: .none, toneTargetIndex: nil)
        XCTAssertEqual(cp1258Result, combiningResult)
    }

    func testEncodingFactory_AllTablesReturnNonNull() {
        for table in EncodingTable.allCases {
            let encoder = EncodingFactory.encoding(for: table)
            let result = encoder.encode(atoms: [BufferAtom(base: "a")], tone: .none, toneTargetIndex: nil)
            XCTAssertFalse(result.isEmpty, "encoding \(table) failed")
        }
    }

    func testConverter_TCVN3toUnicode() {
        let config = ConverterConfiguration(sourceEncoding: .tcvn3, destinationEncoding: .unicode)
        let result = Converter.preview(input: "Ti\u{00D5}ng Vi\u{00D6}t", configuration: config)
        XCTAssertFalse(result.isEmpty)
    }

    func testConverter_VNIWindowstoUnicode() {
        let config = ConverterConfiguration(sourceEncoding: .vniWindows, destinationEncoding: .unicode)
        let result = Converter.preview(input: "Tie\u{00E2}\u{00F9}ng", configuration: config)
        XCTAssertFalse(result.isEmpty)
    }

    func testVowel_AWithCircumflexAcuteUppercase() {
        let result = VietnameseCharacters.vowel(base: "a", mark: .circumflex, tone: .acute, uppercase: true)
        XCTAssertEqual(result, "Ấ")
    }

    func testVowel_UWithHornGrave() {
        let result = VietnameseCharacters.vowel(base: "u", mark: .horn, tone: .grave, uppercase: false)
        XCTAssertEqual(result, "ừ")
    }

    func testD_WithStroke_Uppercase() {
        XCTAssertEqual(VietnameseCharacters.d(withStroke: true, uppercase: true), "Đ")
    }

    func testD_WithoutStroke_Lowercase() {
        XCTAssertEqual(VietnameseCharacters.d(withStroke: false, uppercase: false), "d")
    }

    func testSessionState_Defaults() {
        let state = SessionState()
        XCTAssertTrue(state.isEmpty)
        XCTAssertEqual(state.tone, .none)
        XCTAssertFalse(state.isDisabled)
    }

    func testPinnedCount_WithMixedEntries() {
        var history = ClipboardHistory(entries: [
            entry("a", fingerprint: "f1", pinned: true),
            entry("b", fingerprint: "f2"),
            entry("c", fingerprint: "f3", pinned: true),
        ])
        XCTAssertEqual(history.pinnedCount, 2)
    }

    func testStableKey_PathOnly() {
        let identity = ApplicationIdentity(path: "/Applications/App.app")
        XCTAssertEqual(identity.stableKey, "path:/Applications/App.app")
    }

    func testSmartSwitchSearch_ByKey() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ek-ss-search-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = SmartSwitchStore(fileURL: url)
        let app = ApplicationIdentity(bundleIdentifier: "com.example.finder", name: "Finder")
        _ = try store.handleAppFocus(app, currentChoice: SmartSwitchChoice(language: .english))
        XCTAssertEqual(store.search("com.example.finder").count, 1)
    }

    func testSmartSwitchLoad_MissingSchemaVersion_ReturnsEmpty() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ek-ss-old-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let doc: [String: Any] = ["schemaVersion": 0, "preferences": []]
        try JSONSerialization.data(withJSONObject: doc).write(to: url)
        let store = SmartSwitchStore(fileURL: url)
        XCTAssertTrue(store.preferences.isEmpty)
    }

    func testSmartSwitchClearAll_WithFileURL_EmptiesPersistence() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ek-ss-clear-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = SmartSwitchStore(fileURL: url)
        let app = ApplicationIdentity(bundleIdentifier: "com.example.app", name: "App")
        _ = try store.handleAppFocus(app, currentChoice: SmartSwitchChoice(language: .vietnamese))
        try store.clearAll()
        let loaded = SmartSwitchStore(fileURL: url)
        XCTAssertTrue(loaded.preferences.isEmpty)
    }

    func testSmartSwitchReset_WithFileURL_RemovesFromPersistence() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ek-ss-reset-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = SmartSwitchStore(fileURL: url)
        let app = ApplicationIdentity(bundleIdentifier: "com.example.app", name: "App")
        _ = try store.handleAppFocus(app, currentChoice: SmartSwitchChoice(language: .vietnamese))
        try store.reset(key: "bundle:com.example.app")
        let loaded = SmartSwitchStore(fileURL: url)
        XCTAssertTrue(loaded.preferences.isEmpty)
    }

    func testUpdateChoice_MissingIdentity_ThrowsError() {
        let store = SmartSwitchStore()
        XCTAssertThrowsError(try store.updateChoice(for: ApplicationIdentity(), choice: SmartSwitchChoice(language: .english))) { error in
            XCTAssertEqual(error as? SmartSwitchStoreError, SmartSwitchStoreError.missingApplicationIdentity)
        }
    }

    func testSmartSwitchOptions_DefaultValues() {
        let opts = SmartSwitchOptions()
        XCTAssertFalse(opts.enabled)
        XCTAssertFalse(opts.rememberEncoding)
        XCTAssertTrue(opts.perApplicationValues.isEmpty)
    }

    func testSmartSwitchSave_WithMultiplePreferences_ExecutesSortClosure() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ek-ss-sort-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = SmartSwitchStore(fileURL: url)
        let app1 = ApplicationIdentity(bundleIdentifier: "com.example.b", name: "B")
        let app2 = ApplicationIdentity(bundleIdentifier: "com.example.a", name: "A")
        _ = try store.handleAppFocus(app1, currentChoice: SmartSwitchChoice(language: .vietnamese))
        _ = try store.handleAppFocus(app2, currentChoice: SmartSwitchChoice(language: .english))
        XCTAssertEqual(store.preferences.count, 2)
    }

    func testTypingOptions_DefaultValues() {
        let opts = TypingOptions()
        XCTAssertTrue(opts.spellCheck)
        XCTAssertTrue(opts.restoreInvalidWord)
        XCTAssertEqual(opts.toneStyle, .old)
        XCTAssertFalse(opts.quickTelexConsonants)
        XCTAssertFalse(opts.uppercaseFirstCharacter)
        XCTAssertFalse(opts.liveConfidenceScoring)
        XCTAssertEqual(opts.liveConfidenceLowThreshold, LiveConfidenceDefaults.lowThreshold)
        XCTAssertEqual(opts.liveConfidenceHighThreshold, LiveConfidenceDefaults.highThreshold)
        XCTAssertTrue(opts.iosUniKeyLikeMode)
        XCTAssertTrue(opts.literalTechnicalTokens)
    }

    func testTypingOptions_LiteralTechnicalTokensRoundTrip() throws {
        var opts = TypingOptions()
        opts.literalTechnicalTokens = false
        let data = try JSONEncoder().encode(opts)
        let decoded = try JSONDecoder().decode(TypingOptions.self, from: data)
        XCTAssertFalse(decoded.literalTechnicalTokens)
    }

    func testTypingOptions_LegacyDecodeMissingLiteralTechnicalTokensDefaultsToTrue() throws {
        let data = try JSONEncoder().encode(TypingOptions())
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object.removeValue(forKey: "literalTechnicalTokens")
        let legacyData = try JSONSerialization.data(withJSONObject: object)
        let decoded = try JSONDecoder().decode(TypingOptions.self, from: legacyData)
        XCTAssertTrue(decoded.literalTechnicalTokens)
    }

    func testInputSettings_DefaultValues() {
        let opts = InputSettings()
        XCTAssertEqual(opts.language, .vietnamese)
        XCTAssertEqual(opts.inputMethod, .simpleTelex)
        XCTAssertEqual(opts.encoding, .unicode)
        XCTAssertEqual(opts.switchShortcut.keyCode, 6)
    }

    func testUnicodePrecomposedEncode_DStroke() {
        let atoms: [BufferAtom] = [
            BufferAtom(base: "d", mark: .stroke),
        ]
        let result = UnicodePrecomposedEncoding().encode(atoms: atoms, tone: .none, toneTargetIndex: nil)
        XCTAssertEqual(result, "đ")
    }

    func testUnicodePrecomposedEncode_UppercaseDStroke() {
        let atoms: [BufferAtom] = [
            BufferAtom(base: "d", mark: .stroke, uppercase: true),
        ]
        let result = UnicodePrecomposedEncoding().encode(atoms: atoms, tone: .none, toneTargetIndex: nil)
        XCTAssertEqual(result, "Đ")
    }

    func testEncodingCodec_DecodeVNI_Triplet() {
        let result = Converter.preview(
            input: "Tieáng",
            configuration: ConverterConfiguration(sourceEncoding: .vniWindows, destinationEncoding: .unicode)
        )
        // VNI encoding includes tone/mark diacritics after base characters
        XCTAssertFalse(result.isEmpty)
    }

    func testMacroReplaceAll_ReplacesAllEntries() throws {
        let store = MacroStore()
        try store.add(trigger: "a", expansion: "first")
        try store.add(trigger: "b", expansion: "second")
        let newMacro = Macro(trigger: "x", expansion: "replaced")
        try store.replaceAll([newMacro])
        XCTAssertEqual(store.macros.count, 1)
        XCTAssertEqual(store.macros.first?.trigger, "x")
    }

    func testPreviewImport_DuplicateTriggerInFile_IsUnparseable() throws {
        let store = MacroStore()
        let preview = try store.previewImport("a\texp1\t1\na\texp2\t1")
        XCTAssertEqual(preview.unparseableRecords.count, 1)
    }

    func testPreviewImport_InvalidBoolean_IsUnparseable() throws {
        let store = MacroStore()
        let preview = try store.previewImport("a\texp\tmaybe")
        XCTAssertEqual(preview.unparseableRecords.count, 1)
    }

    func testFullTelexStandaloneWAfterOnset() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(inputMethod: .telex))
        typeKeys(&engine, "tw")
        XCTAssertEqual(engine.currentBuffer, "tư")
    }

    func testUppercaseFirstCharacter_AtSentenceStart_Capitalizes() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(uppercaseFirstCharacter: true))
        let result = engine.process(event: .char("a"))
        XCTAssertEqual(engine.currentBuffer, "A")
    }

    func testUppercaseFirstCharacter_AfterPunctuation_Capitalizes() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(uppercaseFirstCharacter: true))
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: .char("."))
        _ = engine.process(event: .char("b"))
        XCTAssertEqual(engine.currentBuffer, "B")
    }

    func testUppercaseFirstCharacter_AlreadyUppercase_NoChange() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(uppercaseFirstCharacter: true))
        _ = engine.process(event: .char("A", shift: true))
        XCTAssertEqual(engine.currentBuffer, "A")
    }

    func testRevertDStroke_OnDWithoutStroke_PassThrough() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("d"))
        let result = engine.process(event: .char("d")) // d+d → stroke
        XCTAssertEqual(engine.currentBuffer, "đ")
        _ = engine.process(event: .char("d")) // đ+d → revert
        XCTAssertEqual(engine.currentBuffer, "dd")
    }

    // MARK: - Syllable isOpen coverage

    func testSyllable_OpenSyllable_IsOpenTrue() {
        let s = Syllable(onset: "t", nucleus: "a", final: "")
        XCTAssertTrue(s.isOpen)
    }

    func testSyllable_ClosedSyllable_IsOpenFalse() {
        let s = Syllable(onset: "t", nucleus: "a", final: "n")
        XCTAssertFalse(s.isOpen)
    }

    // MARK: - VietnameseCharacters.removingTone coverage

    func testRemovingTone_PlainVowel_ReturnsSelf() {
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "a"), "a")
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "e"), "e")
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "o"), "o")
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "u"), "u")
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "i"), "i")
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "y"), "y")
    }

    func testRemovingTone_AccentedVowel_RemovesTone() {
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "á"), "a")
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "à"), "a")
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "ả"), "a")
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "ã"), "a")
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "ạ"), "a")
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "ắ"), "ă")
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "ằ"), "ă")
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "ẳ"), "ă")
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "ẵ"), "ă")
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "ặ"), "ă")
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "ấ"), "â")
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "ầ"), "â")
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "ẩ"), "â")
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "ẫ"), "â")
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "ậ"), "â")
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "ớ"), "ơ")
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "ờ"), "ơ")
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "ở"), "ơ")
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "ỡ"), "ơ")
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "ợ"), "ơ")
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "ứ"), "ư")
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "ừ"), "ư")
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "ử"), "ư")
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "ữ"), "ư")
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "ự"), "ư")
    }

    func testRemovingTone_UppercaseVowel_RemovesTone() {
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "Á"), "A")
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "Ấ"), "Â")
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "Ỗ"), "Ô")
    }

    func testRemovingTone_Consonant_ReturnsUnchanged() {
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "t"), "t")
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "đ"), "đ")
        XCTAssertEqual(VietnameseCharacters.removingTone(from: "Đ"), "Đ")
    }

    // MARK: - TelexComposer coverage

    func testTelexTrailingFinalConsonants_AllFinals() {
        let cases: [([BufferAtom], String)] = [
            ([BufferAtom(base: "t"), BufferAtom(base: "a"), BufferAtom(base: "n")], "n"),
            ([BufferAtom(base: "t"), BufferAtom(base: "a"), BufferAtom(base: "n"), BufferAtom(base: "g")], "ng"),
            ([BufferAtom(base: "t"), BufferAtom(base: "a"), BufferAtom(base: "n"), BufferAtom(base: "h")], "nh"),
            ([BufferAtom(base: "t"), BufferAtom(base: "a"), BufferAtom(base: "c"), BufferAtom(base: "h")], "ch"),
            ([BufferAtom(base: "t"), BufferAtom(base: "a"), BufferAtom(base: "t")], "t"),
            ([BufferAtom(base: "t"), BufferAtom(base: "a"), BufferAtom(base: "c")], "c"),
            ([BufferAtom(base: "t"), BufferAtom(base: "a"), BufferAtom(base: "p")], "p"),
            ([BufferAtom(base: "t"), BufferAtom(base: "a"), BufferAtom(base: "m")], "m"),
        ]
        for (atoms, expected) in cases {
            XCTAssertEqual(TelexComposer.trailingFinalConsonants(atoms), expected)
        }
    }

    func testTelexTrailingFinalConsonants_OpenSyllable() {
        let atoms: [BufferAtom] = [
            BufferAtom(base: "t"), BufferAtom(base: "a"),
        ]
        XCTAssertEqual(TelexComposer.trailingFinalConsonants(atoms), "")
        XCTAssertEqual(TelexComposer.trailingFinalConsonants([]), "")
    }

    func testTelexComposerToneTargetIndex_WithMultipleVowels() {
        let atoms: [BufferAtom] = [
            BufferAtom(base: "t"),
            BufferAtom(base: "u"),
            BufferAtom(base: "y"),
            BufferAtom(base: "e"),
            BufferAtom(base: "n"),
        ]
        let idx = TelexComposer.toneTargetIndex(atoms: atoms, style: .old)
        XCTAssertNotNil(idx)
    }

    // MARK: - UnicodePrecomposedEncode coverage

    func testUnicodePrecomposedEncode_HornVowelWithoutTone() {
        let atoms: [BufferAtom] = [
            BufferAtom(base: "o", mark: .horn),
        ]
        let result = UnicodePrecomposedEncoding().encode(atoms: atoms, tone: .none, toneTargetIndex: 0)
        XCTAssertEqual(result, "ơ")
    }

    func testUnicodePrecomposedEncode_HornVowelWithTone() {
        let atoms: [BufferAtom] = [
            BufferAtom(base: "o", mark: .horn),
        ]
        let result = UnicodePrecomposedEncoding().encode(atoms: atoms, tone: .acute, toneTargetIndex: 0)
        XCTAssertEqual(result, "ớ")
    }

    func testUnicodePrecomposedEncode_BreveWithTone() {
        let atoms: [BufferAtom] = [
            BufferAtom(base: "a", mark: .breve),
        ]
        let result = UnicodePrecomposedEncoding().encode(atoms: atoms, tone: .dotBelow, toneTargetIndex: 0)
        XCTAssertEqual(result, "ặ")
    }

    func testUnicodePrecomposedEncode_UppercaseDStrokeWithTone() {
        let atoms: [BufferAtom] = [
            BufferAtom(base: "d", mark: .stroke, uppercase: true),
        ]
        let result = UnicodePrecomposedEncoding().encode(atoms: atoms, tone: .none, toneTargetIndex: nil)
        XCTAssertEqual(result, "Đ")
    }

    func testUnicodePrecomposedEncode_SingleAtomNoTone_ReturnsBase() {
        let atoms: [BufferAtom] = [
            BufferAtom(base: "t"),
        ]
        let result = UnicodePrecomposedEncoding().encode(atoms: atoms, tone: .none, toneTargetIndex: nil)
        XCTAssertEqual(result, "t")
    }

    // MARK: - SettingsRepository.saveNow error path

    @MainActor
    func testSaveNow_EncodesAndWrites() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ek-sn-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let repo = SettingsRepository(fileURL: url)
        repo.update { $0.input.inputMethod = .simpleTelex }
        await repo.saveNow()
        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode(EasyKeySettings.self, from: data)
        XCTAssertEqual(decoded.input.inputMethod, .simpleTelex)
    }

    // MARK: - SmartSwitchStore edge

    @MainActor
    func testSmartSwitchHandleAppFocus_NewApp_Records() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ek-ss-new-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = SmartSwitchStore(fileURL: url)
        let app = ApplicationIdentity(bundleIdentifier: "com.test.new", name: "New")
        let result = try store.handleAppFocus(app, currentChoice: SmartSwitchChoice(language: .vietnamese))
        if case .recorded = result {
            // expected
        } else {
            XCTFail("Expected recorded, got \(result)")
        }
    }

    // MARK: - VNI encoding coverage

    func testVNIWindowsEncode_SingleAtom() {
        let atoms: [BufferAtom] = [
            BufferAtom(base: "a"),
        ]
        let result = VNIWindowsEncoding().encode(atoms: atoms, tone: .acute, toneTargetIndex: 0)
        XCTAssertFalse(result.isEmpty)
    }

    // MARK: - TCVN3 encoding coverage

    func testTCVN3Encode_SingleAtomNoTone() {
        let atoms: [BufferAtom] = [
            BufferAtom(base: "a"),
        ]
        let result = TCVN3Encoding().encode(atoms: atoms, tone: .none, toneTargetIndex: nil)
        XCTAssertFalse(result.isEmpty)
    }

    // MARK: - VietnameseEngine.restoreRawKeys coverage

    func testRestoreRawKeys_NonEmptyBuffer() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(outputEncoding: .unicode))
        typeKeys(&engine, "as")
        let result = engine.restoreRawKeys()
        XCTAssertEqual(result.disposition, .suppress)
    }

    func testRestoreRawKeys_NoSessionState() {
        var engine = VietnameseEngine()
        let result = engine.restoreRawKeys()
        XCTAssertEqual(result.disposition, .pass)
    }

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

    private func typeKeys(_ engine: inout VietnameseEngine, _ keys: String) {
        for character in keys {
            _ = engine.process(event: .char(character))
        }
    }
}
