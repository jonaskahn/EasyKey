import CoreGraphics
@testable import EasyKeyKit
import XCTest

final class KeySynthesizerTests: XCTestCase {
    func testPrepareDelete_WithPendingEmptyCharacter_AddsOnePhysicalUnitWithoutStackPop() {
        let synthesizer = KeySynthesizer()
        synthesizer.trackEncodedUnits(["h"])
        synthesizer.markPendingEmptyCharacter()

        let physical = synthesizer.prepareDelete(deleteCount: 1)

        XCTAssertEqual(physical, 2)
        XCTAssertEqual(synthesizer.encodedUnitCount, 0)
        XCTAssertFalse(synthesizer.hasPendingEmptyCharacter)
    }

    func testPrepareDelete_FromHToHoWithPendingEmpty_KeepsStackAligned() {
        let synthesizer = KeySynthesizer()
        synthesizer.trackEncodedUnits(["h"])
        synthesizer.markPendingEmptyCharacter()

        let physical = synthesizer.prepareDelete(deleteCount: 1)

        XCTAssertEqual(physical, 2)
        XCTAssertEqual(synthesizer.encodedUnitCount, 0)

        synthesizer.trackEncodedUnits(["h", "o"])
        synthesizer.markPendingEmptyCharacter()

        XCTAssertEqual(synthesizer.encodedUnitCount, 2)
        XCTAssertTrue(synthesizer.hasPendingEmptyCharacter)
    }

    func testPrepareDelete_HoaCompositionWithPendingEmpty_StaysAlignedWithAtoms() {
        let synthesizer = KeySynthesizer()
        let steps: [(deleteCount: Int, units: [String])] = [
            (0, ["h"]),
            (1, ["h", "o"]),
            (2, ["h", "o", "a"]),
            (3, ["h", "o", "á"]),
        ]

        var hadPending = false
        for (index, step) in steps.enumerated() {
            let physical = synthesizer.prepareDelete(deleteCount: step.deleteCount)
            let expectedPhysical = step.deleteCount + (hadPending ? 1 : 0)

            XCTAssertEqual(
                physical,
                expectedPhysical,
                "Step \(index) (\(step.units.joined())): physical delete skew"
            )
            XCTAssertEqual(synthesizer.encodedUnitCount, 0)
            XCTAssertFalse(synthesizer.hasPendingEmptyCharacter)

            synthesizer.trackEncodedUnits(step.units)
            synthesizer.markPendingEmptyCharacter()
            hadPending = true

            XCTAssertEqual(synthesizer.encodedUnitCount, step.units.count)
            XCTAssertTrue(synthesizer.hasPendingEmptyCharacter)
        }
    }

    func testResetEncodedUnits_WithPendingEmpty_ClearsStackAndFlag() {
        let synthesizer = KeySynthesizer()
        synthesizer.trackEncodedUnits(["a"])
        synthesizer.markPendingEmptyCharacter()

        synthesizer.resetEncodedUnits()

        XCTAssertEqual(synthesizer.encodedUnitCount, 0)
        XCTAssertFalse(synthesizer.hasPendingEmptyCharacter)
        XCTAssertEqual(synthesizer.prepareDelete(deleteCount: 1), 0)
    }

    func testPrepareDelete_WithoutPending_RemovesOnlyLogicalUnits() {
        let synthesizer = KeySynthesizer()
        synthesizer.trackEncodedUnits(["h", "o", "a"])

        XCTAssertEqual(synthesizer.prepareDelete(deleteCount: 2), 2)
        XCTAssertEqual(synthesizer.encodedUnitCount, 1)
        XCTAssertFalse(synthesizer.hasPendingEmptyCharacter)
    }

    func testFocusedReplacementSuccessKeepsEncodedStackAligned() {
        var receivedLengths: [Int] = []
        let synthesizer = KeySynthesizer { lengths, text in
            receivedLengths = lengths
            return text == "uye\u{302}\u{300}n" ? .succeeded : .failed
        }
        synthesizer.trackEncodedUnits(["t", "u", "y", "e", "n"])

        let strategy = synthesizer.replaceBackward(
            proxy: fakeProxy(),
            deleteCount: 4,
            insert: "uye\u{302}\u{300}n",
            encodedUnits: ["u", "y", "e\u{302}\u{300}", "n"],
            useFocusedTextReplacement: true
        )

        XCTAssertEqual(strategy, .atomicFocusedText)
        XCTAssertEqual(receivedLengths, [1, 1, 1, 1])
        XCTAssertEqual(synthesizer.encodedUnitCount, 5)
        XCTAssertEqual(synthesizer.prepareDelete(deleteCount: 4), 6)
        XCTAssertEqual(synthesizer.encodedUnitCount, 1)
    }

    func testFocusedReplacementFailureUsesPhysicalFallbackAndKeepsStackAligned() {
        let synthesizer = KeySynthesizer { _, _ in .failed }
        synthesizer.trackEncodedUnits(["t", "u", "y", "e", "n"])

        let strategy = synthesizer.replaceBackward(
            proxy: fakeProxy(),
            deleteCount: 4,
            insert: "uyền",
            encodedUnits: ["u", "y", "ề", "n"],
            useFocusedTextReplacement: true
        )

        XCTAssertEqual(strategy, .breakAutocompleteAndBackspace)
        XCTAssertEqual(synthesizer.encodedUnitCount, 5)
    }

    func testFocusedReplacementWithUnknownCaretResetsStackWithoutFallback() {
        let synthesizer = KeySynthesizer { _, _ in .valueChangedCaretUnknown }
        synthesizer.trackEncodedUnits(["t", "u"])

        let strategy = synthesizer.replaceBackward(
            proxy: fakeProxy(),
            deleteCount: 1,
            insert: "ư",
            encodedUnits: ["ư"],
            useFocusedTextReplacement: true
        )

        XCTAssertEqual(strategy, .atomicFocusedTextCaretUnknown)
        XCTAssertEqual(synthesizer.encodedUnitCount, 0)
    }

    func testSelectionReplacement_UsedWhenFocusedReplacementFails() {
        let synthesizer = KeySynthesizer { _, _ in .failed }
        synthesizer.trackEncodedUnits(["t", "u", "y", "e", "n"])

        let strategy = synthesizer.replaceBackward(
            proxy: fakeProxy(),
            deleteCount: 4,
            insert: "uyền",
            encodedUnits: ["u", "y", "ề", "n"],
            useFocusedTextReplacement: true,
            useSelectionReplacement: true
        )

        XCTAssertEqual(strategy, .selectionReplacement)
        XCTAssertEqual(synthesizer.encodedUnitCount, 5)
    }

    func testPrepareDeleteForSelection_CountsGraphemesNotUTF16() {
        let synthesizer = KeySynthesizer()
        synthesizer.trackEncodedUnits(["u", "y", "e\u{302}\u{300}", "n"])

        XCTAssertEqual(synthesizer.prepareDeleteForSelection(deleteCount: 4), 4)
        XCTAssertEqual(synthesizer.encodedUnitCount, 0)
    }

    func testPrepareDeleteForSelection_WithPendingEmptyCharacter_AddsOne() {
        let synthesizer = KeySynthesizer()
        synthesizer.trackEncodedUnits(["h"])
        synthesizer.markPendingEmptyCharacter()

        XCTAssertEqual(synthesizer.prepareDeleteForSelection(deleteCount: 1), 2)
        XCTAssertFalse(synthesizer.hasPendingEmptyCharacter)
    }

    private func fakeProxy() -> CGEventTapProxy {
        unsafeBitCast(UInt(0), to: CGEventTapProxy.self)
    }
}
