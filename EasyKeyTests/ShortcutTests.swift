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

    func testKeyCodeZeroWithModifiersRepresentsAKey() {
        let shortcut = Shortcut(keyCode: 0, modifiers: [.command])
        XCTAssertTrue(shortcut.isActive)
        XCTAssertFalse(shortcut.isModifierOnly)
        XCTAssertEqual(shortcut.displayLabel, "\u{2318} + A")
    }

    func testModifierOnlyShortcutHasExplicitSemantics() {
        let shortcut = Shortcut.modifiersOnly([.command])
        XCTAssertTrue(shortcut.isActive)
        XCTAssertTrue(shortcut.isModifierOnly)
        XCTAssertEqual(shortcut.displayLabel, "\u{2318}")
    }

    func testIsActiveWithKeyNoModifiers() {
        let shortcut = Shortcut(keyCode: 36, modifiers: [])
        XCTAssertTrue(shortcut.isActive)
    }

    func testIsActiveNeither() {
        XCTAssertFalse(Shortcut.none.isActive)
    }

    func testCodingPreservesModifierOnlyAndLegacyAKeySemantics() throws {
        let modifierOnly = Shortcut.modifiersOnly([.option])
        let roundTrip = try JSONDecoder().decode(Shortcut.self, from: JSONEncoder().encode(modifierOnly))
        XCTAssertTrue(roundTrip.isModifierOnly)

        let legacyAKey = try JSONDecoder().decode(
            Shortcut.self,
            from: Data(#"{"keyCode":0,"modifiers":8}"#.utf8)
        )
        XCTAssertFalse(legacyAKey.isModifierOnly)
        XCTAssertEqual(legacyAKey.displayLabel, "\u{2318} + A")
    }

    func testEquatable() {
        let shortcutA = Shortcut(keyCode: 36, modifiers: [.command])
        let shortcutB = Shortcut(keyCode: 36, modifiers: [.command])
        XCTAssertEqual(shortcutA, shortcutB)
    }
}
