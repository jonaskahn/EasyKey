import CoreGraphics
@testable import EasyKeyKit
import XCTest

final class KeySynthesizerTests: XCTestCase {
    func testPrepareDelete_RemovesLogicalUnits() {
        let synthesizer = KeySynthesizer()
        synthesizer.trackEncodedUnits(["h", "o", "a"])

        XCTAssertEqual(synthesizer.prepareDelete(deleteCount: 2), 2)
        XCTAssertEqual(synthesizer.encodedUnitCount, 1)
    }

    func testResetEncodedUnits_ClearsStack() {
        let synthesizer = KeySynthesizer()
        synthesizer.trackEncodedUnits(["a"])

        synthesizer.resetEncodedUnits()

        XCTAssertEqual(synthesizer.encodedUnitCount, 0)
        XCTAssertEqual(synthesizer.prepareDelete(deleteCount: 1), 0)
    }

    /// Seeds legacy NFD bookkeeping directly on the stack: the unit-length
    /// contract (.grapheme vs .codePoint) is independent of the wire
    /// normalization applied at emission.
    func testPrepareDelete_SeedsNFDUnits_CountsPerBackspaceUnit() {
        let synthesizer = KeySynthesizer()
        synthesizer.backspaceUnit = .codePoint
        synthesizer.trackEncodedUnits(["e\u{302}\u{300}"])

        XCTAssertEqual(synthesizer.prepareDelete(deleteCount: 1), 3)
    }

    func testSelectionReplacement_WithoutFocusedReplacement() {
        let synthesizer = KeySynthesizer()
        synthesizer.trackEncodedUnits(["t", "u", "y", "e", "n"])

        let strategy = synthesizer.replaceBackward(
            proxy: fakeProxy(),
            deleteCount: 4,
            insert: "uyền",
            encodedUnits: ["u", "y", "ề", "n"],
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

    private func fakeProxy() -> CGEventTapProxy {
        unsafeBitCast(UInt(0), to: CGEventTapProxy.self)
    }
}
