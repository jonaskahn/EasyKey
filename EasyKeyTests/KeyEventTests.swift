@testable import EasyEngineCore
import XCTest

final class KeyEventTests: XCTestCase {
    func testIsUppercaseShiftWithoutCapsLock() {
        let event = KeyEvent(kind: .character("a"), shift: true, capsLock: false)
        XCTAssertTrue(event.isUppercase)
    }

    func testIsUppercaseCapsLockWithoutShift() {
        let event = KeyEvent(kind: .character("a"), shift: false, capsLock: true)
        XCTAssertTrue(event.isUppercase)
    }

    func testIsUppercaseShiftWithCapsLock() {
        let event = KeyEvent(kind: .character("a"), shift: true, capsLock: true)
        XCTAssertFalse(event.isUppercase)
    }

    func testIsUppercaseNeither() {
        let event = KeyEvent(kind: .character("a"), shift: false, capsLock: false)
        XCTAssertFalse(event.isUppercase)
    }

    func testHasModifiersNone() {
        let event = KeyEvent(kind: .character("a"))
        XCTAssertFalse(event.hasModifiers)
    }

    func testHasModifiersControl() {
        let event = KeyEvent(kind: .character("a"), control: true)
        XCTAssertTrue(event.hasModifiers)
    }

    func testHasModifiersOption() {
        let event = KeyEvent(kind: .character("a"), option: true)
        XCTAssertTrue(event.hasModifiers)
    }

    func testHasModifiersCommand() {
        let event = KeyEvent(kind: .character("a"), command: true)
        XCTAssertTrue(event.hasModifiers)
    }

    func testHasModifiersMultiple() {
        let event = KeyEvent(kind: .character("a"), control: true, option: true, command: true)
        XCTAssertTrue(event.hasModifiers)
    }

    func testCharHelperDefaults() {
        let event = KeyEvent.char("x")
        XCTAssertEqual(event.kind, .character("x"))
        XCTAssertFalse(event.shift)
        XCTAssertFalse(event.capsLock)
    }

    func testCharHelperWithShift() {
        let event = KeyEvent.char("X", shift: true)
        XCTAssertTrue(event.shift)
    }

    func testCharHelperWithCapsLock() {
        let event = KeyEvent.char("a", capsLock: true)
        XCTAssertTrue(event.capsLock)
    }
}
