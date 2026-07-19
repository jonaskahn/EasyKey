@testable import EasyKeyKit
import XCTest

final class FocusedElementInspectorExtendedTests: XCTestCase {
    func testReplacement_HandlesEmptyDeletedUnitLengths() {
        let result = FocusedElementInspector.replacement(
            value: "hello",
            selectedRange: NSRange(location: 1, length: 2),
            deletedUnitLengths: [],
            replacement: "a"
        )
        XCTAssertEqual(result?.value, "halo")
        XCTAssertEqual(result?.caretRange, NSRange(location: 2, length: 0))
    }

    func testReplacement_HandlesAllEmpty() {
        let result = FocusedElementInspector.replacement(
            value: "",
            selectedRange: NSRange(location: 0, length: 0),
            deletedUnitLengths: [],
            replacement: ""
        )
        XCTAssertEqual(result?.value, "")
        XCTAssertEqual(result?.caretRange, NSRange(location: 0, length: 0))
    }

    func testReplacement_DeletesFullValue() {
        let result = FocusedElementInspector.replacement(
            value: "abc",
            selectedRange: NSRange(location: 0, length: 3),
            deletedUnitLengths: [],
            replacement: ""
        )
        XCTAssertEqual(result?.value, "")
        XCTAssertEqual(result?.caretRange, NSRange(location: 0, length: 0))
    }

    func testReplacement_SelectsFullAndReplaces() {
        let result = FocusedElementInspector.replacement(
            value: "abc def",
            selectedRange: NSRange(location: 0, length: 7),
            deletedUnitLengths: [],
            replacement: "replaced"
        )
        XCTAssertEqual(result?.value, "replaced")
        XCTAssertEqual(result?.caretRange, NSRange(location: 8, length: 0))
    }

    func testReplacement_DeletesWithMultipleSizedUnits() {
        let result = FocusedElementInspector.replacement(
            value: "abcdef",
            selectedRange: NSRange(location: 6, length: 0),
            deletedUnitLengths: [3, 1, 2],
            replacement: "x"
        )
        XCTAssertEqual(result?.value, "x")
        XCTAssertEqual(result?.caretRange, NSRange(location: 1, length: 0))
    }

    func testReplacement_OverflowDeletedLength() {
        XCTAssertNil(FocusedElementInspector.replacement(
            value: "abc",
            selectedRange: NSRange(location: 0, length: 0),
            deletedUnitLengths: [Int.max, 1],
            replacement: "x"
        ))
    }

    func testReplacement_RejectsSelectionBeyondValueEnd() {
        XCTAssertNil(FocusedElementInspector.replacement(
            value: "abc",
            selectedRange: NSRange(location: 1, length: 0),
            deletedUnitLengths: [2],
            replacement: "x"
        ))
    }

    func testReplacement_SelectionLocationEqualsValueLength() {
        let result = FocusedElementInspector.replacement(
            value: "abc",
            selectedRange: NSRange(location: 3, length: 0),
            deletedUnitLengths: [1],
            replacement: "d"
        )
        XCTAssertEqual(result?.value, "abd")
        XCTAssertEqual(result?.caretRange, NSRange(location: 3, length: 0))
    }

    func testReplacement_EmojiHandling() {
        let result = FocusedElementInspector.replacement(
            value: "hello 🌍",
            selectedRange: NSRange(location: 8, length: 0),
            deletedUnitLengths: [2],
            replacement: "world"
        )
        XCTAssertEqual(result?.value, "hello world")
    }

    func testReplacement_MaxSelectionLength() {
        let result = FocusedElementInspector.replacement(
            value: "hi",
            selectedRange: NSRange(location: 2, length: 0),
            deletedUnitLengths: [2],
            replacement: "hello"
        )
        XCTAssertEqual(result?.value, "hello")
        XCTAssertEqual(result?.caretRange, NSRange(location: 5, length: 0))
    }

    func testFocusedTextReplacementResult_Equality() {
        XCTAssertEqual(FocusedElementInspector.FocusedTextReplacementResult.succeeded, .succeeded)
        XCTAssertEqual(FocusedElementInspector.FocusedTextReplacementResult.failed, .failed)
        XCTAssertEqual(FocusedElementInspector.FocusedTextReplacementResult.valueChangedCaretUnknown, .valueChangedCaretUnknown)
        XCTAssertNotEqual(FocusedElementInspector.FocusedTextReplacementResult.succeeded, .failed)
    }

    func testTextReplacement_Equality() {
        let t1 = FocusedElementInspector.TextReplacement(value: "a", caretRange: NSRange(location: 1, length: 0))
        let t2 = FocusedElementInspector.TextReplacement(value: "a", caretRange: NSRange(location: 1, length: 0))
        let t3 = FocusedElementInspector.TextReplacement(value: "b", caretRange: NSRange(location: 1, length: 0))
        XCTAssertEqual(t1, t2)
        XCTAssertNotEqual(t1, t3)
    }
}
