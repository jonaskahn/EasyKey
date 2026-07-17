import CoreGraphics
@testable import EasyKeyKit
import XCTest

final class KeySynthesizerPostingTests: XCTestCase {
    private func fakeProxy() -> CGEventTapProxy {
        unsafeBitCast(UInt(0), to: CGEventTapProxy.self)
    }

    func testPostBackspace_ZeroCount_NoOp() {
        let synthesizer = KeySynthesizer()
        synthesizer.postBackspace(proxy: fakeProxy(), count: 0)
    }

    func testPostBackspace_PositiveCount_Posts() {
        let synthesizer = KeySynthesizer()
        synthesizer.postBackspace(proxy: fakeProxy(), count: 3)
    }

    func testPostUnicodeText_EmptyString_NoOp() {
        let synthesizer = KeySynthesizer()
        synthesizer.postUnicodeText(proxy: fakeProxy(), "")
        XCTAssertEqual(synthesizer.encodedUnitCount, 0)
    }

    func testPostUnicodeText_SimpleText_TracksEncodedUnits() {
        let synthesizer = KeySynthesizer()
        synthesizer.postUnicodeText(proxy: fakeProxy(), "hoa")
        XCTAssertEqual(synthesizer.encodedUnitCount, 3)
    }

    func testPostUnicodeText_LongText_ChunksAcrossMultipleEvents() {
        let synthesizer = KeySynthesizer()
        let longText = String(repeating: "a", count: 40)
        synthesizer.postUnicodeText(proxy: fakeProxy(), longText)
        XCTAssertEqual(synthesizer.encodedUnitCount, 40)
    }

    func testPostUnicodeText_SurrogatePairText_HandlesEmoji() {
        let synthesizer = KeySynthesizer()
        synthesizer.postUnicodeText(proxy: fakeProxy(), "😀😀😀😀😀😀😀😀😀")
        XCTAssertGreaterThan(synthesizer.encodedUnitCount, 0)
    }

    func testPostPhysicalKey_WithModifiers_DoesNotCrash() {
        let synthesizer = KeySynthesizer()
        synthesizer.postPhysicalKey(proxy: fakeProxy(), keyCode: 0, modifiers: .maskShift)
    }

    func testPostShiftLeft_ZeroCount_NoOp() {
        let synthesizer = KeySynthesizer()
        synthesizer.postShiftLeft(proxy: fakeProxy(), count: 0)
    }

    func testPostShiftLeft_PositiveCount_Posts() {
        let synthesizer = KeySynthesizer()
        synthesizer.postShiftLeft(proxy: fakeProxy(), count: 2)
    }

    func testPostCut_DoesNotCrash() {
        let synthesizer = KeySynthesizer()
        synthesizer.postCut(proxy: fakeProxy())
    }

    func testInsert_ClearsPendingEmptyCharacterFirst() {
        let synthesizer = KeySynthesizer()
        synthesizer.insertEmptyCharacter(proxy: fakeProxy(), "\u{200B}")
        XCTAssertTrue(synthesizer.hasPendingEmptyCharacter)

        synthesizer.insert(proxy: fakeProxy(), "a")
        XCTAssertFalse(synthesizer.hasPendingEmptyCharacter)
        XCTAssertEqual(synthesizer.encodedUnitCount, 1)
    }

    func testInsert_WithExplicitEncodedUnits() {
        let synthesizer = KeySynthesizer()
        synthesizer.insert(proxy: fakeProxy(), "ab", encodedUnits: ["a", "b"])
        XCTAssertEqual(synthesizer.encodedUnitCount, 2)
    }

    func testInsertEmptyCharacter_MarksPending() {
        let synthesizer = KeySynthesizer()
        synthesizer.insertEmptyCharacter(proxy: fakeProxy(), "\u{2060}")
        XCTAssertTrue(synthesizer.hasPendingEmptyCharacter)
        XCTAssertEqual(synthesizer.encodedUnitCount, 0)
    }

    func testReplaceBackward_WithoutSelectionOrAutocomplete() {
        let synthesizer = KeySynthesizer()
        synthesizer.trackEncodedUnits(["h", "o"])
        synthesizer.replaceBackward(
            proxy: fakeProxy(),
            deleteCount: 1,
            insert: "oa",
            encodedUnits: ["o", "a"],
            useFocusedTextReplacement: false
        )
        XCTAssertEqual(synthesizer.encodedUnitCount, 3)
    }

    func testReplaceBackward_WithFocusedTextReplacementFallback() {
        let synthesizer = KeySynthesizer()
        synthesizer.trackEncodedUnits(["h", "o"])
        synthesizer.replaceBackward(
            proxy: fakeProxy(),
            deleteCount: 1,
            insert: "oa",
            encodedUnits: ["o", "a"],
            useFocusedTextReplacement: true
        )
        XCTAssertEqual(synthesizer.encodedUnitCount, 3)
    }

    func testReplaceBackward_WithBreakAutocomplete() {
        let synthesizer = KeySynthesizer()
        synthesizer.trackEncodedUnits(["h", "o"])
        synthesizer.replaceBackward(
            proxy: fakeProxy(),
            deleteCount: 1,
            insert: "oa",
            encodedUnits: ["o", "a"],
            useFocusedTextReplacement: false,
            breakAutocomplete: true
        )
        XCTAssertEqual(synthesizer.encodedUnitCount, 3)
    }

    func testReplaceBackward_ZeroDeleteCount_StillInserts() {
        let synthesizer = KeySynthesizer()
        synthesizer.replaceBackward(
            proxy: fakeProxy(),
            deleteCount: 0,
            insert: "x",
            encodedUnits: ["x"],
            useFocusedTextReplacement: false
        )
        XCTAssertEqual(synthesizer.encodedUnitCount, 1)
    }

    func testIsSelfPosted_ForPostedEvent_IsTrue() {
        let synthesizer = KeySynthesizer()
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) else {
            XCTFail("Could not create event")
            return
        }
        synthesizer.postPhysicalKey(proxy: fakeProxy(), keyCode: 0)
        XCTAssertFalse(KeySynthesizer.isSelfPosted(event))
    }

    func testIsSelfPosted_ForUnmarkedEvent_IsFalse() {
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) else {
            XCTFail("Could not create event")
            return
        }
        XCTAssertFalse(KeySynthesizer.isSelfPosted(event))
    }
}
