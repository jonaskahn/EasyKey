import CoreGraphics
@testable import EasyEngineCore
@testable import EasyKeyKit
import XCTest

final class KeySynthesizerEventOrderingTests: XCTestCase {
    private struct PostedEvent {
        let keyCode: UInt16
        let isKeyDown: Bool
        let flags: CGEventFlags
        let unicode: String
        let wasMarked: Bool
    }

    private var posted: [PostedEvent] = []

    private func makeSynthesizer(
        eventFactory: KeySynthesizer.EventFactory? = nil
    ) -> KeySynthesizer {
        posted = []
        return KeySynthesizer(
            eventFactory: eventFactory,
            eventPoster: { [self] event, _ in
                posted.append(Self.describe(event))
            }
        )
    }

    private static func describe(_ event: CGEvent) -> PostedEvent {
        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let unicode: String
        if event.type == .keyDown || event.type == .keyUp {
            var length = 64
            var units = [UniChar](repeating: 0, count: length)
            event.keyboardGetUnicodeString(maxStringLength: length, actualStringLength: &length, unicodeString: &units)
            unicode = length >= 64 ? "" : String(utf16CodeUnits: &units, count: length)
        } else {
            unicode = ""
        }
        return PostedEvent(
            keyCode: keyCode,
            isKeyDown: event.type == .keyDown,
            flags: event.flags,
            unicode: unicode,
            wasMarked: event.getIntegerValueField(.eventSourceUserData) != 0
        )
    }

    private func fakeProxy() -> CGEventTapProxy {
        unsafeBitCast(UInt(0), to: CGEventTapProxy.self)
    }

    func testPostUnicodeText_KeyDownPrecedesKeyUpAndEventsAreMarkedBeforePosting() {
        let synthesizer = makeSynthesizer()
        XCTAssertTrue(synthesizer.postUnicodeText(proxy: fakeProxy(), "ab"))

        XCTAssertEqual(posted.count, 2, "two utf16 units fit one chunk")
        XCTAssertTrue(posted[0].isKeyDown)
        XCTAssertFalse(posted[1].isKeyDown)
        XCTAssertEqual(posted[0].unicode, "ab")
        XCTAssertTrue(posted.allSatisfy(\.wasMarked))
    }

    func testPostBackspace_PostsDownUpPairsWithBackspaceKeyCode() {
        let synthesizer = makeSynthesizer()
        XCTAssertTrue(synthesizer.postBackspace(proxy: fakeProxy(), count: 2))

        XCTAssertEqual(posted.count, 4)
        XCTAssertEqual(posted.map(\.isKeyDown), [true, false, true, false])
        XCTAssertTrue(posted.allSatisfy { $0.keyCode == 51 })
        XCTAssertTrue(posted.allSatisfy(\.wasMarked))
    }

    func testPostPhysicalKey_AppliesModifiersToBothEvents() {
        let synthesizer = makeSynthesizer()
        XCTAssertTrue(synthesizer.postPhysicalKey(proxy: fakeProxy(), keyCode: 123, modifiers: .maskShift))

        XCTAssertEqual(posted.count, 2)
        XCTAssertEqual(posted.map(\.keyCode), [123, 123])
        XCTAssertTrue(posted.allSatisfy { $0.flags.contains(.maskShift) })
    }

    func testReplaceBackward_BreakAutocomplete_OrderIsBreakThenBreakBackspaceThenDeletionThenInsertion() {
        let synthesizer = makeSynthesizer()
        XCTAssertTrue(synthesizer.postUnicodeText(proxy: fakeProxy(), "b"))

        let strategy = synthesizer.replaceBackward(
            proxy: fakeProxy(),
            deleteCount: 1,
            insert: "a",
            encodedUnits: ["a"],
            breakAutocomplete: true
        )
        XCTAssertEqual(strategy, .breakAutocompleteAndBackspace)

        let tail = posted.suffix(8).map { (keyCode: $0.keyCode, isKeyDown: $0.isKeyDown, unicode: $0.unicode) }
        XCTAssertEqual(tail.count, 8)
        XCTAssertEqual(tail[0].unicode, "\u{202F}", "autocomplete break character posted first")
        XCTAssertTrue(tail[1].isKeyDown == false && tail[1].unicode != "\u{202F}", "break character is set on the key-down only")
        XCTAssertEqual([tail[2], tail[3]].map(\.keyCode), [51, 51], "break backspace after break")
        XCTAssertEqual([tail[4], tail[5]].map(\.keyCode), [51, 51], "logical deletion after break backspace")
        XCTAssertEqual(tail[6].unicode, "a", "insertion last")
        XCTAssertTrue(tail[6].isKeyDown)
        XCTAssertFalse(tail[7].isKeyDown)
    }

    func testReplaceBackward_CombiningWord_CountsGraphemesNotUTF16Units() {
        // Seeds legacy NFD bookkeeping directly on the stack: "tuyền" as
        // t,u,y,ề(e+U+0302+U+0300),n — 5 grapheme clusters but 7 UTF-16
        // units. Backspaces delete grapheme clusters in the receiving app,
        // so the word commit must post exactly 5 backspaces; UTF-16 counting
        // posted 7 and ate the preceding space.
        let synthesizer = makeSynthesizer()
        synthesizer.trackEncodedUnits(["t", "u", "y", "e\u{0302}\u{0300}", "n"])

        let strategy = synthesizer.replaceBackward(
            proxy: fakeProxy(),
            deleteCount: 5,
            insert: "tuyền",
            encodedUnits: []
        )
        XCTAssertEqual(strategy, .physicalBackspace)

        let backspaceKeyDowns = posted.filter { $0.keyCode == 51 && $0.isKeyDown }
        XCTAssertEqual(backspaceKeyDowns.count, 5, "deleting 5 graphemes must post 5 backspaces, not 7")
    }

    func testReplaceBackward_SingleCombiningVowel_PostsOneBackspace() {
        let synthesizer = makeSynthesizer()
        synthesizer.trackEncodedUnits(["e\u{0302}\u{0300}"])

        _ = synthesizer.replaceBackward(
            proxy: fakeProxy(),
            deleteCount: 1,
            insert: "e",
            encodedUnits: ["e"]
        )

        let backspaceKeyDowns = posted.filter { $0.keyCode == 51 && $0.isKeyDown }
        XCTAssertEqual(backspaceKeyDowns.count, 1, "one grapheme must post one backspace, not 3")
    }

    func testReplaceBackward_CodePointUnit_PostsUtf16CountBackspaces() {
        // Seeds legacy NFD bookkeeping directly on the stack. Chrome/Blink
        // web-page fields delete one UTF-16 code unit per backspace: the
        // seeded "tuyền" (t,u,y,ề=e+U+0302+U+0300,n) is 7 code units, so
        // posting only 5 backspaces under-deletes and produces the
        // duplicated-character regression ("ttututuyền").
        let synthesizer = makeSynthesizer()
        synthesizer.backspaceUnit = .codePoint
        synthesizer.trackEncodedUnits(["t", "u", "y", "e\u{0302}\u{0300}", "n"])

        let strategy = synthesizer.replaceBackward(
            proxy: fakeProxy(),
            deleteCount: 5,
            insert: "tuyền",
            encodedUnits: []
        )
        XCTAssertEqual(strategy, .physicalBackspace)

        let backspaceKeyDowns = posted.filter { $0.keyCode == 51 && $0.isKeyDown }
        XCTAssertEqual(backspaceKeyDowns.count, 7, "code-point semantics must post 7 backspaces for 7 UTF-16 units")
    }

    func testAutocompleteBreakCharacter_IsSingleConfiguredConstant() {
        // The omnibox autocomplete-break character is a single named constant
        // so the workaround can be flipped in one place (e.g. to U+200B or
        // U+2060) if a future Chrome changes how it handles the character.
        XCTAssertEqual(KeySynthesizer.autocompleteBreakCharacter.unicodeScalars.count, 1)
        XCTAssertEqual(KeySynthesizer.autocompleteBreakCharacter, "\u{202F}")
    }

    func testPostMacroExpansion_SelectionReplacement_OrderIsSelectionThenInsertionThenDelimiter() {
        let synthesizer = makeSynthesizer()
        XCTAssertTrue(
            synthesizer.postMacroExpansion(
                proxy: fakeProxy(),
                backspaceCount: 1,
                text: "hi",
                physicalKeyCode: 49,
                useSelectionReplacement: true,
                breakAutocomplete: false
            )
        )

        XCTAssertEqual(posted.count, 6)
        XCTAssertEqual(posted[0].keyCode, 123, "selection-left first")
        XCTAssertTrue(posted[0].flags.contains(.maskShift))
        XCTAssertFalse(posted[1].isKeyDown)
        XCTAssertEqual(posted[2].unicode, "hi", "insertion second")
        XCTAssertEqual(posted[4].keyCode, 49, "delimiter last")
        XCTAssertTrue(posted[4].isKeyDown)
        XCTAssertFalse(posted[5].isKeyDown)
    }

    func testPostMacroExpansion_BreakAutocomplete_DelimiterIsPostedLast() {
        let synthesizer = makeSynthesizer()
        XCTAssertTrue(
            synthesizer.postMacroExpansion(
                proxy: fakeProxy(),
                backspaceCount: 1,
                text: "hi",
                physicalKeyCode: 49,
                useSelectionReplacement: false,
                breakAutocomplete: true
            )
        )

        XCTAssertEqual(posted.count, 10)
        let lastTwo = posted.suffix(2)
        XCTAssertEqual(lastTwo.map(\.keyCode), [49, 49], "delimiter key posted last")
        XCTAssertTrue(lastTwo.first?.isKeyDown == true)
        XCTAssertFalse(lastTwo.last?.isKeyDown == true)
        let firstBreak = posted[0]
        XCTAssertEqual(firstBreak.unicode, "\u{202F}")
        XCTAssertEqual(posted[2].keyCode, 51, "break backspace follows break character")
        XCTAssertEqual(posted[4].keyCode, 51, "deletion follows break backspace")
        XCTAssertEqual(posted[6].unicode, "hi", "insertion follows deletion")
    }

    func testEventCreationFailure_PostsNothingAndReturnsFalse() {
        let synthesizer = makeSynthesizer(eventFactory: { _, _ in nil })
        XCTAssertFalse(synthesizer.postBackspace(proxy: fakeProxy(), count: 1))
        XCTAssertFalse(synthesizer.postUnicodeText(proxy: fakeProxy(), "a"))
        XCTAssertEqual(posted.count, 0)
    }

    func testUnicodeChunks_NeverSplitASurrogatePair() {
        let synthesizer = makeSynthesizer()
        let text = String(repeating: "a", count: 15) + "😀" + "b"
        XCTAssertTrue(synthesizer.postUnicodeText(proxy: fakeProxy(), text))

        let chunkStrings = posted.filter(\.isKeyDown).map(\.unicode)
        XCTAssertEqual(chunkStrings.count, 2)
        XCTAssertEqual(chunkStrings[0].utf16.count, 15, "first chunk holds whole units before the emoji")
        XCTAssertEqual(Array(chunkStrings[1].utf16), Array("😀b".utf16), "surrogate pair stays in one chunk")
    }

    func testPostEmptyCharacterBreak_OrdersInsertThenImmediateBackspace() {
        let synthesizer = makeSynthesizer()
        XCTAssertTrue(synthesizer.postEmptyCharacterBreak(proxy: fakeProxy(), "\u{200C}"))

        XCTAssertEqual(posted.count, 4, "insert key-down/up pair then one backspace key-down/up pair")
        XCTAssertEqual(posted[0].isKeyDown, true)
        XCTAssertEqual(posted[0].unicode, "\u{200C}", "break character posted first")
        XCTAssertEqual(posted[1].isKeyDown, false)
        XCTAssertEqual(posted[2].keyCode, 51)
        XCTAssertTrue(posted[2].isKeyDown, "immediate backspace deletes the break character")
        XCTAssertEqual(posted[3].keyCode, 51)
        XCTAssertFalse(posted[3].isKeyDown)
        XCTAssertEqual(synthesizer.encodedUnitCount, 0, "break character is never tracked for deletion")

        // A later replacement must not count a phantom pending unit: one
        // logical unit on the stack deletes with exactly one backspace pair.
        XCTAssertTrue(synthesizer.insert(proxy: fakeProxy(), "x"))
        posted = []
        let strategy = synthesizer.replaceBackward(
            proxy: fakeProxy(),
            deleteCount: 1,
            insert: "y",
            encodedUnits: ["y"],
            breakAutocomplete: false
        )
        XCTAssertEqual(strategy, .physicalBackspace)
        XCTAssertEqual(posted.filter { $0.keyCode == 51 }.count, 2, "exactly one backspace key pair for one logical unit")
    }

    func testInsert_NFDText_PostsPrecomposedAndTracksNFCUnits() {
        let synthesizer = makeSynthesizer()
        synthesizer.backspaceUnit = .codePoint
        XCTAssertTrue(synthesizer.insert(proxy: fakeProxy(), "o\u{031B}\u{0301}", encodedUnits: ["o\u{031B}\u{0301}"]))

        let keyDowns = posted.filter(\.isKeyDown).map(\.unicode).joined()
        XCTAssertEqual(keyDowns, "ớ", "wire text must be precomposed NFC")
        XCTAssertFalse(keyDowns.unicodeScalars.contains { (0x0300 ... 0x036F).contains($0.value) })
        XCTAssertEqual(synthesizer.encodedUnitCount, 1, "deletion bookkeeping follows the normalized form")

        // One normalized unit: replacement deletes it with a single backspace
        // even under .codePoint counting.
        XCTAssertEqual(synthesizer.prepareDelete(deleteCount: 1), 1)
    }

    func testNormalizesUnicodeOutputFalse_LegacyCombiningPassesThrough() {
        let synthesizer = makeSynthesizer()
        synthesizer.normalizesUnicodeOutput = false
        synthesizer.backspaceUnit = .codePoint
        XCTAssertTrue(synthesizer.insert(proxy: fakeProxy(), "o\u{031B}\u{0301}", encodedUnits: ["o\u{031B}\u{0301}"]))

        let keyDowns = posted.filter(\.isKeyDown).map(\.unicode).joined()
        XCTAssertEqual(keyDowns, "o\u{031B}\u{0301}", "legacy code-page output must not be recomposed")
        XCTAssertEqual(synthesizer.encodedUnitCount, 1)

        // NFD bookkeeping preserved: one atom, three UTF-16 units.
        XCTAssertEqual(synthesizer.prepareDelete(deleteCount: 1), 3)
    }

    func testPostMacroExpansion_NFDExpansion_PostsNFCWithMatchingUnits() {
        let synthesizer = makeSynthesizer()
        synthesizer.backspaceUnit = .codePoint
        XCTAssertTrue(synthesizer.postMacroExpansion(
            proxy: fakeProxy(),
            backspaceCount: 0,
            text: "e\u{0302}\u{0300}",
            physicalKeyCode: 49,
            useSelectionReplacement: false,
            breakAutocomplete: false
        ))

        let keyDowns = posted.filter(\.isKeyDown).map(\.unicode).joined()
        let scalars = keyDowns.unicodeScalars.map { String(format: "U+%04X", $0.value) }
        XCTAssertTrue(keyDowns.hasPrefix("ề"), "macro expansion must post precomposed text, got \(scalars)")
        XCTAssertEqual(synthesizer.encodedUnitCount, 1, "macro units track the normalized form")
        XCTAssertEqual(synthesizer.prepareDelete(deleteCount: 1), 1)
    }
}
