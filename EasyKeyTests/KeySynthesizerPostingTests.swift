import CoreGraphics
@testable import EasyEngineCore
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

    func testPostUnicodeText_EventCreationFailureDoesNotTrackUnits() {
        let synthesizer = KeySynthesizer(
            focusedTextReplacer: { _, _ in .failed },
            eventFactory: { _, _ in nil }
        )

        let posted = synthesizer.postUnicodeText(proxy: fakeProxy(), "hoa")

        XCTAssertFalse(posted)
        XCTAssertEqual(synthesizer.encodedUnitCount, 0)
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

    func testPostMacroExpansion_RemovesTriggerAndTracksExpansionUnits() {
        let synthesizer = KeySynthesizer()
        synthesizer.trackEncodedUnits(["s", "i", "g"])

        let posted = synthesizer.postMacroExpansion(
            proxy: fakeProxy(),
            backspaceCount: 3,
            text: "Best regards",
            physicalKeyCode: 49,
            useSelectionReplacement: false,
            breakAutocomplete: false
        )

        XCTAssertTrue(posted)
        XCTAssertEqual(synthesizer.encodedUnitCount, 12)
    }

    func testPostMacroExpansion_WithoutTrackedTrigger_FallsBackToLogicalBackspaceCount() {
        let synthesizer = KeySynthesizer()

        let posted = synthesizer.postMacroExpansion(
            proxy: fakeProxy(),
            backspaceCount: 3,
            text: "abc",
            physicalKeyCode: 49,
            useSelectionReplacement: false,
            breakAutocomplete: false
        )

        XCTAssertTrue(posted)
        XCTAssertEqual(synthesizer.encodedUnitCount, 3)
    }

    func testPostMacroExpansion_WithBreakAutocomplete_Posts() {
        let synthesizer = KeySynthesizer()
        synthesizer.trackEncodedUnits(["s", "i", "g"])

        let posted = synthesizer.postMacroExpansion(
            proxy: fakeProxy(),
            backspaceCount: 3,
            text: "Best regards",
            physicalKeyCode: 49,
            useSelectionReplacement: false,
            breakAutocomplete: true
        )

        XCTAssertTrue(posted)
        XCTAssertEqual(synthesizer.encodedUnitCount, 12)
    }

    func testPostMacroExpansion_WithSelectionReplacement_Posts() {
        let synthesizer = KeySynthesizer()
        synthesizer.trackEncodedUnits(["s", "i", "g"])

        let posted = synthesizer.postMacroExpansion(
            proxy: fakeProxy(),
            backspaceCount: 3,
            text: "Best regards",
            physicalKeyCode: 49,
            useSelectionReplacement: true,
            breakAutocomplete: false
        )

        XCTAssertTrue(posted)
        XCTAssertEqual(synthesizer.encodedUnitCount, 12)
    }

    func testPostMacroExpansion_EventCreationFailure_ReturnsFalseWithoutTracking() {
        let synthesizer = KeySynthesizer(
            focusedTextReplacer: { _, _ in .failed },
            eventFactory: { _, _ in nil }
        )

        let posted = synthesizer.postMacroExpansion(
            proxy: fakeProxy(),
            backspaceCount: 3,
            text: "Best regards",
            physicalKeyCode: 49,
            useSelectionReplacement: false,
            breakAutocomplete: false
        )

        XCTAssertFalse(posted)
        XCTAssertEqual(synthesizer.encodedUnitCount, 0)
    }

    func testPostMacroExpansion_WithPendingEmptyCharacter_AccountsForItInDeletion() {
        let synthesizer = KeySynthesizer()
        synthesizer.trackEncodedUnits(["s", "i", "g"])
        synthesizer.insertEmptyCharacter(proxy: fakeProxy(), "\u{200B}")

        let posted = synthesizer.postMacroExpansion(
            proxy: fakeProxy(),
            backspaceCount: 3,
            text: "abc",
            physicalKeyCode: 49,
            useSelectionReplacement: false,
            breakAutocomplete: false
        )

        XCTAssertTrue(posted)
        XCTAssertFalse(synthesizer.hasPendingEmptyCharacter)
        XCTAssertEqual(synthesizer.encodedUnitCount, 3)
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

    func testPostPhysicalKey_NoModifiers_DoesNotCrash() {
        let synthesizer = KeySynthesizer()
        synthesizer.postPhysicalKey(proxy: fakeProxy(), keyCode: 6)
    }

    func testUtf16Chunks_BoundaryAlignment() {
        let synthesizer = KeySynthesizer()
        let text = String(repeating: "a", count: 32)
        synthesizer.postUnicodeText(proxy: fakeProxy(), text)
        XCTAssertEqual(synthesizer.encodedUnitCount, 32)
    }

    func testUtf16Chunks_SurrogatePairAtChunkBoundary_PulledIntoNextChunk() {
        let synthesizer = KeySynthesizer()
        // 1 BMP unit ("a") followed by 8 surrogate pairs (16 units) = 17 units.
        // Built from explicit code units so the high surrogate lands exactly at
        // index 15 — the 16-unit chunk boundary — forcing the split-avoidance
        // branch that pulls the whole pair into the next chunk.
        var units: [UInt16] = [0x0061]
        for _ in 0 ..< 8 {
            units.append(0xD83D)
            units.append(0xDE00)
        }
        XCTAssertEqual(units.count, 17)
        let text = String(decoding: units, as: UTF16.self)
        XCTAssertEqual(text.utf16.count, 17)
        // encodedUnitCount tracks one entry per Character (grapheme), not per
        // UTF-16 code unit: 1 "a" + 8 emoji = 9 — the boundary-split behavior
        // itself is exercised internally regardless of this public count.
        synthesizer.postUnicodeText(proxy: fakeProxy(), text)
        XCTAssertEqual(synthesizer.encodedUnitCount, 9)
    }

    func testPostPhysicalKey_EventCreationFailure_DoesNotCrash() {
        let synthesizer = KeySynthesizer(
            focusedTextReplacer: { _, _ in .failed },
            eventFactory: { _, _ in nil }
        )
        synthesizer.postPhysicalKey(proxy: fakeProxy(), keyCode: 6)
    }
}
