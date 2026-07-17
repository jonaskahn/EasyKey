@testable import EasyEngineCore
import XCTest

final class MacroStoreTests: XCTestCase {
    func testAdd_MultipleTriggers_SortsByTriggerAscending() throws {
        let store = MacroStore()
        let later = try store.add(trigger: "zulu", expansion: "last")
        let first = try store.add(trigger: "alpha", expansion: "first")

        XCTAssertEqual(store.macros.map(\.id), [first.id, later.id])
    }

    func testSearch_PartialExpansion_ReturnsMatchingMacro() throws {
        let store = MacroStore()
        let first = try store.add(trigger: "alpha", expansion: "first")
        _ = try store.add(trigger: "zulu", expansion: "last")

        XCTAssertEqual(store.search("irs").map(\.id), [first.id])
    }

    func testEdit_ExistingMacro_UpdatesExpansionAndEnabled() throws {
        let store = MacroStore()
        let later = try store.add(trigger: "zulu", expansion: "last")

        let edited = try store.edit(id: later.id, trigger: "zulu", expansion: "edited", isEnabled: false)
        XCTAssertFalse(edited.isEnabled)
        XCTAssertEqual(edited.expansion, "edited")
    }

    func testDelete_ExistingMacro_RemovesFromStore() throws {
        let store = MacroStore()
        let later = try store.add(trigger: "zulu", expansion: "last")
        let first = try store.add(trigger: "alpha", expansion: "first")

        try store.delete(id: first.id)
        XCTAssertEqual(store.macros.map(\.id), [later.id])
    }

    func testAdd_EmptyTrigger_ThrowsEmptyTrigger() throws {
        let store = MacroStore()
        XCTAssertThrowsError(try store.add(trigger: "", expansion: "value")) {
            XCTAssertEqual($0 as? MacroStoreError, .emptyTrigger)
        }
    }

    func testAdd_EmptyExpansion_ThrowsEmptyExpansion() throws {
        let store = MacroStore()
        XCTAssertThrowsError(try store.add(trigger: "key", expansion: "")) {
            XCTAssertEqual($0 as? MacroStoreError, .emptyExpansion)
        }
    }

    func testAdd_DuplicateTriggerIgnoringCase_ThrowsDuplicateTrigger() throws {
        let store = MacroStore()
        _ = try store.add(trigger: "key", expansion: "value")
        XCTAssertThrowsError(try store.add(trigger: "KEY", expansion: "other")) {
            XCTAssertEqual($0 as? MacroStoreError, .duplicateTrigger)
        }
    }

    func testExpansion_AutoCapitalize_MatchesTypedTriggerCase() throws {
        let store = MacroStore()
        _ = try store.add(trigger: "sig", expansion: "best regards")

        XCTAssertEqual(store.expansion(for: "sig", autoCapitalize: true), "best regards")
        XCTAssertEqual(store.expansion(for: "Sig", autoCapitalize: true), "Best regards")
        XCTAssertEqual(store.expansion(for: "SIG", autoCapitalize: true), "BEST REGARDS")
    }

    func testChangeActiveEncoding_UnicodeToCombining_RebuildsEncodedExpansion() throws {
        let store = MacroStore(activeEncoding: .unicode)
        let macro = try store.add(trigger: "viet", expansion: "việt")

        XCTAssertEqual(store.encodedExpansion(for: macro.id), "việt")
        store.changeActiveEncoding(to: .unicodeCombining)
        XCTAssertEqual(store.encodedExpansion(for: macro.id), "vie\u{0323}\u{0302}t")
    }

    func testPreviewImport_MixedRows_SeparatesAdditionsConflictsAndUnparseable() throws {
        let store = MacroStore()
        _ = try store.add(trigger: "sig", expansion: "old")
        let preview = try store.previewImport("trigger\texpansion\tenabled\nsig\tnew\t1\naddr\tHanoi\t0\nbroken")

        XCTAssertEqual(preview.additions.map(\.trigger), ["addr"])
        XCTAssertEqual(preview.conflicts.count, 1)
        XCTAssertEqual(preview.unparseableRecords, ["broken"])
    }

    func testApply_ReplaceConflict_UpdatesExpansionAndExportsTSV() throws {
        let store = MacroStore()
        _ = try store.add(trigger: "sig", expansion: "old")
        let preview = try store.previewImport("trigger\texpansion\tenabled\nsig\tnew\t1\naddr\tHanoi\t0\nbroken")

        try store.apply(preview, resolving: [preview.conflicts[0].imported.id: .replace])
        XCTAssertEqual(store.expansion(for: "sig", autoCapitalize: false), "new")
        XCTAssertTrue(store.exportTSV().contains("addr\tHanoi\t0"))
    }

    func testPreviewLegacyImport_MixedLines_FlagsUnparseableRecords() throws {
        let preview = try MacroStore().previewLegacyImport("sig => Best regards\nnot a macro")

        XCTAssertEqual(preview.additions.map(\.trigger), ["sig"])
        XCTAssertEqual(preview.unparseableRecords, ["not a macro"])
    }
}
