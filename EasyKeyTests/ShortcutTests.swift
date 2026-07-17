@testable import EasyEngineCore
import XCTest

final class ShortcutTests: XCTestCase {
    func testDisplayLabelAllModifiers() {
        let shortcut = Shortcut(keyCode: 36, modifiers: [.command, .option, .shift, .control])
        let label = shortcut.displayLabel
        XCTAssertTrue(label.contains("^"))
        XCTAssertTrue(label.contains("\u{2325}"))
        XCTAssertTrue(label.contains("\u{21E7}"))
        XCTAssertTrue(label.contains("\u{2318}"))
        XCTAssertTrue(label.contains("Return"))
    }

    func testDisplayLabelCommandOnly() {
        let shortcut = Shortcut(keyCode: 12, modifiers: [.command])
        let label = shortcut.displayLabel
        XCTAssertTrue(label.contains("\u{2318}"))
        XCTAssertTrue(label.contains("Q"))
    }

    func testDisplayLabelOptionOnly() {
        let shortcut = Shortcut(keyCode: 12, modifiers: [.option])
        let label = shortcut.displayLabel
        XCTAssertTrue(label.contains("\u{2325}"))
        XCTAssertTrue(label.contains("Q"))
    }

    func testDisplayLabelShiftOnly() {
        let shortcut = Shortcut(keyCode: 12, modifiers: [.shift])
        let label = shortcut.displayLabel
        XCTAssertTrue(label.contains("\u{21E7}"))
        XCTAssertTrue(label.contains("Q"))
    }

    func testDisplayLabelControlOnly() {
        let shortcut = Shortcut(keyCode: 12, modifiers: [.control])
        let label = shortcut.displayLabel
        XCTAssertTrue(label.contains("^"))
        XCTAssertTrue(label.contains("Q"))
    }

    func testDisplayLabelUsesReadableLetterName() {
        XCTAssertEqual(Shortcut(keyCode: 6, modifiers: []).displayLabel, "Z")
    }

    func testDisplayLabelUsesReadableSpecialKeyName() {
        XCTAssertEqual(Shortcut(keyCode: 49, modifiers: [.command]).displayLabel, "\u{2318} + Space")
    }

    func testDisplayLabelSeparatesMultipleModifiersAndKey() {
        let shortcut = Shortcut(keyCode: 6, modifiers: [.option, .shift, .command])
        XCTAssertEqual(shortcut.displayLabel, "\u{2325} + \u{21E7} + \u{2318} + Z")
    }

    func testDisplayLabelDistinguishesKeypadKeys() {
        XCTAssertEqual(Shortcut(keyCode: 88, modifiers: []).displayLabel, "Keypad 6")
    }

    func testDisplayLabelFallsBackForUnknownKeyCode() {
        XCTAssertEqual(Shortcut(keyCode: 200, modifiers: []).displayLabel, "Key 200")
    }

    func testDisplayLabelNone() {
        let shortcut = Shortcut.none
        XCTAssertFalse(shortcut.isActive)
        XCTAssertEqual(shortcut.displayLabel, "")
    }

    func testIsActiveNoKeyButModifiers() {
        let shortcut = Shortcut(keyCode: 0, modifiers: [.command])
        XCTAssertTrue(shortcut.isActive)
    }

    func testIsActiveWithKeyNoModifiers() {
        let shortcut = Shortcut(keyCode: 36, modifiers: [])
        XCTAssertTrue(shortcut.isActive)
    }

    func testIsActiveNeither() {
        let shortcut = Shortcut(keyCode: 0, modifiers: [])
        XCTAssertFalse(shortcut.isActive)
    }

    func testEquatable() {
        let shortcutA = Shortcut(keyCode: 36, modifiers: [.command])
        let shortcutB = Shortcut(keyCode: 36, modifiers: [.command])
        XCTAssertEqual(shortcutA, shortcutB)
    }
}
