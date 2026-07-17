@testable import EasyEngineCore
import XCTest

final class MacroStoreEdgeCaseTests: XCTestCase {
    func testExportTSVFormat() throws {
        let store = MacroStore()
        _ = try store.add(trigger: "sig", expansion: "best regards")
        _ = try store.add(trigger: "addr", expansion: "Hanoi")

        let tsv = store.exportTSV()
        XCTAssertTrue(tsv.contains("trigger\texpansion\tenabled"))
        XCTAssertTrue(tsv.contains("sig\tbest regards\t1"))
        XCTAssertTrue(tsv.contains("addr\tHanoi\t1"))
    }

    func testExportToFile() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = MacroStore()
        _ = try store.add(trigger: "sig", expansion: "best regards")

        let url = directory.appendingPathComponent("macros.tsv")
        try store.export(to: url)
        let content = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(content.contains("sig\tbest regards\t1"))
    }

    func testPreviewImportFromFile() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let url = directory.appendingPathComponent("import.tsv")
        let tsv = "trigger\texpansion\tenabled\nhello\tworld\t1\nfoo\tbar\t0"
        try tsv.write(to: url, atomically: true, encoding: .utf8)

        let store = MacroStore()
        let preview = try store.previewImport(from: url)
        XCTAssertEqual(preview.additions.count, 2)
        XCTAssertEqual(preview.additions.map(\.trigger), ["hello", "foo"])
    }

    func testPreviewImportInvalidFile() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let url = directory.appendingPathComponent("bad.xyz")
        let invalid = Data([0xFF, 0xFE, 0xFD])
        try invalid.write(to: url)

        let store = MacroStore()
        XCTAssertThrowsError(try store.previewImport(from: url))
    }

    func testApplySkipConflict() throws {
        let store = MacroStore()
        _ = try store.add(trigger: "sig", expansion: "original")
        let preview = try store.previewImport("trigger\texpansion\tenabled\nsig\timported\t1")

        try store.apply(preview, resolving: [preview.conflicts[0].imported.id: .skip])
        XCTAssertEqual(store.expansion(for: "sig", autoCapitalize: false), "original")
    }

    func testApplyRenameConflict() throws {
        let store = MacroStore()
        _ = try store.add(trigger: "sig", expansion: "original")
        let preview = try store.previewImport("trigger\texpansion\tenabled\nsig\timported\t1")

        try store.apply(preview, resolving: [preview.conflicts[0].imported.id: .rename])
        let macros = store.macros
        XCTAssertEqual(macros.count, 2)
    }

    func testReplaceAll() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let fileURL = directory.appendingPathComponent("macros.json")
        let store = MacroStore(fileURL: fileURL)
        _ = try store.add(trigger: "old", expansion: "outdated")

        let newMacro = Macro(trigger: "new", expansion: "fresh")
        try store.replaceAll([newMacro])
        XCTAssertEqual(store.macros.map(\.trigger), ["new"])
    }

    func testExportTSVWithDisabledMacro() throws {
        let store = MacroStore()
        _ = try store.add(trigger: "active", expansion: "yes", isEnabled: true)
        _ = try store.add(trigger: "off", expansion: "no", isEnabled: false)

        let tsv = store.exportTSV()
        XCTAssertTrue(tsv.contains("active\tyes\t1"))
        XCTAssertTrue(tsv.contains("off\tno\t0"))
    }

    func testEditNonExistentMacro() {
        let store = MacroStore()
        XCTAssertThrowsError(try store.edit(id: UUID(), trigger: "x", expansion: "y", isEnabled: true)) {
            XCTAssertEqual($0 as? MacroStoreError, .unknownMacro)
        }
    }

    func testDeleteNonExistentMacro() {
        let store = MacroStore()
        XCTAssertThrowsError(try store.delete(id: UUID())) {
            XCTAssertEqual($0 as? MacroStoreError, .unknownMacro)
        }
    }

    func testDuplicateCaseInsensitiveDuringEdit() throws {
        let store = MacroStore()
        _ = try store.add(trigger: "KEY", expansion: "value")

        let macro = try store.add(trigger: "other", expansion: "other")
        XCTAssertThrowsError(try store.edit(id: macro.id, trigger: "key", expansion: "new", isEnabled: true)) {
            XCTAssertEqual($0 as? MacroStoreError, .duplicateTrigger)
        }
    }

    func testExpansionCaseInsensitiveMatch() throws {
        let store = MacroStore()
        _ = try store.add(trigger: "SIG", expansion: "signature")

        XCTAssertEqual(store.expansion(for: "sig", autoCapitalize: false), "signature")
        XCTAssertEqual(store.expansion(for: "SIG", autoCapitalize: false), "signature")
    }

    func testExpansionNoMatch() throws {
        let store = MacroStore()
        _ = try store.add(trigger: "sig", expansion: "best regards")
        XCTAssertNil(store.expansion(for: "unknown", autoCapitalize: false))
    }

    func testExpansionAutoCapitalizeAllCaps() throws {
        let store = MacroStore()
        _ = try store.add(trigger: "sig", expansion: "best regards")
        XCTAssertEqual(store.expansion(for: "SIG", autoCapitalize: true), "BEST REGARDS")
    }

    func testExpansionAutoCapitalizeFirstChar() throws {
        let store = MacroStore()
        _ = try store.add(trigger: "sig", expansion: "best regards")
        XCTAssertEqual(store.expansion(for: "Sig", autoCapitalize: true), "Best regards")
    }

    func testExpansionAutoCapitalizeDisabled() throws {
        let store = MacroStore()
        _ = try store.add(trigger: "sig", expansion: "best regards")
        XCTAssertEqual(store.expansion(for: "Sig", autoCapitalize: false), "best regards")
    }

    func testMatchCapitalizationAllUpper() {
        let result = MacroStore.matchCapitalization(of: "SIG", in: "best regards")
        XCTAssertEqual(result, "BEST REGARDS")
    }

    func testMatchCapitalizationTitleCase() {
        let result = MacroStore.matchCapitalization(of: "Sig", in: "best regards")
        XCTAssertEqual(result, "Best regards")
    }

    func testMatchCapitalizationNoLetters() {
        let result = MacroStore.matchCapitalization(of: "123", in: "hello")
        XCTAssertEqual(result, "hello")
    }

    func testLoadFromPersistence() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let fileURL = directory.appendingPathComponent("macros.json")
        let store = MacroStore(fileURL: fileURL)
        _ = try store.add(trigger: "persist", expansion: "works")

        let reloaded = MacroStore(fileURL: fileURL)
        XCTAssertEqual(reloaded.macros.count, 1)
        XCTAssertEqual(reloaded.macros.first?.trigger, "persist")
    }

    func testPreviewImportDuplicateInFile() throws {
        let store = MacroStore()
        let preview = try store.previewImport("trigger\texpansion\tenabled\ndup\tfirst\t1\ndup\tsecond\t1")

        XCTAssertEqual(preview.additions.count, 1)
        XCTAssertEqual(preview.unparseableRecords.count, 1)
    }

    func testPersistenceWithNoFile() {
        let store = MacroStore(fileURL: nil)
        _ = try? store.add(trigger: "x", expansion: "y")
        XCTAssertEqual(store.macros.count, 1)
    }
}
