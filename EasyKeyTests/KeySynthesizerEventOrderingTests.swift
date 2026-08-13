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

    func testInsertEmptyCharacter_PendingDeletionIsAppliedExactlyOnce() {
        let synthesizer = makeSynthesizer()
        XCTAssertTrue(synthesizer.insertEmptyCharacter(proxy: fakeProxy(), "\u{200C}"))
        XCTAssertTrue(synthesizer.hasPendingEmptyCharacter)
        posted = []

        let strategy = synthesizer.replaceBackward(
            proxy: fakeProxy(),
            deleteCount: 1,
            insert: "x",
            encodedUnits: ["x"],
            breakAutocomplete: false
        )
        XCTAssertEqual(strategy, .physicalBackspace)

        let deletionEvents = posted.filter { $0.keyCode == 51 }
        XCTAssertEqual(deletionEvents.count, 2, "pending empty character contributes exactly one deletion key pair")
        XCTAssertFalse(synthesizer.hasPendingEmptyCharacter)
    }
}
