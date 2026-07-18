@testable import EasyKeyKit
import XCTest

final class FocusedElementInspectorTests: XCTestCase {
    func testReplacement_ReplacesLogicalUnitsBeforeSelectionAndSelectedSuffix() {
        let result = FocusedElementInspector.replacement(
            value: "ttttuyền",
            selectedRange: NSRange(location: 4, length: 4),
            deletedUnitLengths: [1, 1, 1, 1],
            replacement: "tuyền"
        )

        XCTAssertEqual(result?.value, "tuyền")
        XCTAssertEqual(result?.caretRange, NSRange(location: 5, length: 0))
    }

    func testReplacement_UsesUTF16UnitLengthsAndCaretOffset() {
        let result = FocusedElementInspector.replacement(
            value: "x😀ab rest",
            selectedRange: NSRange(location: 5, length: 0),
            deletedUnitLengths: [2, 1, 1],
            replacement: "ế"
        )

        XCTAssertEqual(result?.value, "xế rest")
        XCTAssertEqual(result?.caretRange, NSRange(location: 2, length: 0))
    }

    func testReplacement_RejectsOutOfBoundsSelection() {
        XCTAssertNil(FocusedElementInspector.replacement(
            value: "abc",
            selectedRange: NSRange(location: 2, length: 2),
            deletedUnitLengths: [1],
            replacement: "x"
        ))
    }

    func testReplacement_RejectsDeleteBeforeBeginning() {
        XCTAssertNil(FocusedElementInspector.replacement(
            value: "abc",
            selectedRange: NSRange(location: 1, length: 0),
            deletedUnitLengths: [1, 1],
            replacement: "x"
        ))
    }

    func testReplacement_RejectsNegativeSelectionLocation() {
        XCTAssertNil(FocusedElementInspector.replacement(
            value: "abc",
            selectedRange: NSRange(location: -1, length: 0),
            deletedUnitLengths: [],
            replacement: "x"
        ))
    }

    func testReplacement_RejectsNegativeSelectionLength() {
        XCTAssertNil(FocusedElementInspector.replacement(
            value: "abc",
            selectedRange: NSRange(location: 0, length: -1),
            deletedUnitLengths: [],
            replacement: "x"
        ))
    }

    func testReplacement_RejectsSelectionStartingPastEnd() {
        XCTAssertNil(FocusedElementInspector.replacement(
            value: "abc",
            selectedRange: NSRange(location: 4, length: 0),
            deletedUnitLengths: [],
            replacement: "x"
        ))
    }

    func testReplacement_RejectsNegativeDeletedUnitLength() {
        XCTAssertNil(FocusedElementInspector.replacement(
            value: "abc",
            selectedRange: NSRange(location: 2, length: 0),
            deletedUnitLengths: [1, -1],
            replacement: "x"
        ))
    }

    func testReplacement_InsertsAtCaretWithoutDeletion() {
        let result = FocusedElementInspector.replacement(
            value: "abc",
            selectedRange: NSRange(location: 1, length: 0),
            deletedUnitLengths: [],
            replacement: "😀"
        )

        XCTAssertEqual(result?.value, "a😀bc")
        XCTAssertEqual(result?.caretRange, NSRange(location: 3, length: 0))
    }

    func testIsChromiumAddressBar_DoesNotCrash() {
        _ = FocusedElementInspector.isChromiumAddressBar()
    }

    func testIsChromiumAddressBar_CalledRepeatedly_IsStable() {
        let first = FocusedElementInspector.isChromiumAddressBar()
        let second = FocusedElementInspector.isChromiumAddressBar()
        XCTAssertEqual(first, second)
    }
}
