@testable import EasyEngineCore
import XCTest

final class MacroSamplesTests: XCTestCase {
    func testEveryPackHasAtLeastTenSamples() {
        for pack in MacroSamplePack.allCases {
            XCTAssertGreaterThanOrEqual(
                pack.macros.count,
                10,
                "Pack \(pack.rawValue) must ship at least 10 samples"
            )
        }
    }

    func testPackCategories() {
        XCTAssertEqual(MacroSamplePack.english.category, .english)
        XCTAssertEqual(MacroSamplePack.vietnamese.category, .vietnamese)
        XCTAssertEqual(MacroSamplePack.nineX.category, .nineX)
        XCTAssertEqual(MacroSamplePack.genZ.category, .genZ)
    }

    func testSampleFieldsAreValid() {
        for pack in MacroSamplePack.allCases {
            for macro in pack.macros {
                XCTAssertFalse(macro.trigger.isEmpty, "Empty trigger in \(pack.rawValue)")
                XCTAssertFalse(macro.expansion.isEmpty, "Empty expansion for \(macro.trigger)")
                XCTAssertLessThanOrEqual(macro.trigger.count, MacroStore.maximumTriggerLength)
                XCTAssertLessThanOrEqual(macro.expansion.count, MacroStore.maximumExpansionLength)
                XCTAssertFalse(macro.trigger.contains("\t"), "Tab in trigger \(macro.trigger)")
                XCTAssertFalse(macro.trigger.contains("\n"), "Newline in trigger \(macro.trigger)")
                XCTAssertFalse(macro.expansion.contains("\t"), "Tab in expansion for \(macro.trigger)")
                XCTAssertFalse(macro.expansion.contains("\n"), "Newline in expansion for \(macro.trigger)")
                XCTAssertEqual(macro.category, pack.category)
                XCTAssertTrue(macro.isEnabled)
            }
        }
    }

    func testPacksHaveNoDuplicateTriggersWithinACategory() {
        for pack in MacroSamplePack.allCases {
            let triggers = pack.macros.map { $0.trigger.lowercased() }
            XCTAssertEqual(Set(triggers).count, triggers.count, "Duplicate trigger in \(pack.rawValue)")
        }
    }

    func testCategoryMatching() {
        XCTAssertTrue(MacroCategory.nineX.matches(.vietnamese))
        XCTAssertFalse(MacroCategory.nineX.matches(.english))
        XCTAssertTrue(MacroCategory.genZ.matches(.english))
        XCTAssertFalse(MacroCategory.genZ.matches(.vietnamese))
        XCTAssertTrue(MacroCategory.both.matches(.vietnamese))
        XCTAssertTrue(MacroCategory.both.matches(.english))
    }

    func testInsertSamplesAddsAllAndPersists() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let fileURL = directory.appendingPathComponent("macros.json")
        let store = MacroStore(fileURL: fileURL)
        let pack = MacroSamplePack.english
        let added = try store.insertSamples(pack.macros)
        XCTAssertEqual(added, pack.macros.count)
        XCTAssertEqual(store.macros.count, pack.macros.count)

        let reloaded = MacroStore(fileURL: fileURL)
        XCTAssertEqual(reloaded.macros.count, pack.macros.count)
        XCTAssertEqual(Set(reloaded.macros.map(\.trigger)), Set(pack.macros.map(\.trigger)))
    }

    func testInsertSamplesSkipsExistingTriggers() throws {
        let store = MacroStore()
        _ = try store.insertSamples(MacroSamplePack.english.macros)
        XCTAssertEqual(try store.insertSamples(MacroSamplePack.english.macros), 0)
        XCTAssertEqual(store.macros.count, MacroSamplePack.english.macros.count)
    }

    func testInsertSamplesAllowsSameTriggerAcrossCategories() throws {
        let store = MacroStore()
        let added = try store.insertSamples(
            MacroSamplePack.vietnamese.macros + MacroSamplePack.nineX.macros
        )
        let expected = MacroSamplePack.vietnamese.macros.count + MacroSamplePack.nineX.macros.count
        XCTAssertEqual(added, expected, "j is shared but categories differ")
    }

    func testInsertSamplesKeepsExistingMacros() throws {
        let store = MacroStore()
        _ = try store.add(trigger: "sig", expansion: "best regards")
        let added = try store.insertSamples(MacroSamplePack.genZ.macros)
        XCTAssertEqual(added, MacroSamplePack.genZ.macros.count)
        XCTAssertEqual(store.macros.count, MacroSamplePack.genZ.macros.count + 1)
        XCTAssertNotNil(store.macros.first { $0.trigger == "sig" })
    }
}
