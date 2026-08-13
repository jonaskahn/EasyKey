@testable import EasyEngineCore
@testable import EasyKeyKit
import XCTest

final class MacroExpanderCoverageTests: XCTestCase {
    func testWithModifiers_ResetsTriggerAndReturnsNil() {
        var expander = MacroExpander()
        expander.update(macros: [Macro(trigger: "btw", expansion: "by the way")])
        let result = expander.consume(
            character: "b",
            keyCode: 49,
            modifiers: [.shift],
            options: MacroOptions(enabled: true),
            language: .vietnamese
        )
        XCTAssertNil(result)
    }

    func testWhitespaceCharacter_ResetsTrigger() {
        var expander = MacroExpander()
        expander.update(macros: [Macro(trigger: "btw", expansion: "by the way")])
        _ = expander.consume(character: "b", keyCode: 0, modifiers: [], options: MacroOptions(enabled: true), language: .vietnamese)
        let result = expander.consume(
            character: " ",
            keyCode: 49,
            modifiers: [],
            options: MacroOptions(enabled: true),
            language: .vietnamese
        )
        XCTAssertNil(result)
    }

    func testTriggerExceedsMaxLength_Trims() {
        var expander = MacroExpander()
        let longTrigger = String(repeating: "x", count: MacroStore.maximumTriggerLength + 10)
        expander.update(macros: [Macro(trigger: longTrigger, expansion: "test")])
        for ch in longTrigger {
            _ = expander.consume(character: ch, keyCode: 0, modifiers: [], options: MacroOptions(enabled: true), language: .vietnamese)
        }
    }

    func testDisabledMacro_NoMatch() {
        var expander = MacroExpander()
        expander.update(macros: [Macro(trigger: "btw", expansion: "by the way", isEnabled: false)])
        for ch in "btw" {
            _ = expander.consume(character: ch, keyCode: 0, modifiers: [], options: MacroOptions(enabled: true), language: .vietnamese)
        }
        let result = expander.consume(
            character: "\n",
            keyCode: 36,
            modifiers: [],
            options: MacroOptions(enabled: true),
            language: .vietnamese
        )
        XCTAssertNil(result)
    }

    func testAutoCapitalize_AppliesCapitalization() {
        var expander = MacroExpander()
        expander.update(macros: [Macro(trigger: "btw", expansion: "by the way")])
        for ch in "Btw" {
            _ = expander.consume(
                character: ch,
                keyCode: 0,
                modifiers: [],
                options: MacroOptions(enabled: true, autoCapitalize: true),
                language: .vietnamese
            )
        }
        let result = expander.consume(
            character: "\n",
            keyCode: 36,
            modifiers: [],
            options: MacroOptions(enabled: true, autoCapitalize: true),
            language: .vietnamese
        )
        XCTAssertEqual(result?.text, "By the way")
    }

    func testNotEnabled_ReturnsNil() {
        var expander = MacroExpander()
        expander.update(macros: [])
        let result = expander.consume(
            character: "b",
            keyCode: 49,
            modifiers: [],
            options: MacroOptions(enabled: false),
            language: .vietnamese
        )
        XCTAssertNil(result)
    }

    func testReset_ClearsTrigger() {
        var expander = MacroExpander()
        expander.update(macros: [Macro(trigger: "btw", expansion: "by the way")])
        _ = expander.consume(character: "b", keyCode: 0, modifiers: [], options: MacroOptions(enabled: true), language: .vietnamese)
        expander.reset()
    }

    func testWhitespaceCharacter_OnNonDelimiterKeyCode_ResetsTrigger() {
        var expander = MacroExpander()
        expander.update(macros: [Macro(trigger: "btw", expansion: "by the way")])
        _ = expander.consume(character: "b", keyCode: 0, modifiers: [], options: MacroOptions(enabled: true), language: .vietnamese)
        let result = expander.consume(
            character: " ",
            keyCode: 0,
            modifiers: [],
            options: MacroOptions(enabled: true),
            language: .vietnamese
        )
        XCTAssertNil(result)

        _ = expander.consume(character: "b", keyCode: 0, modifiers: [], options: MacroOptions(enabled: true), language: .vietnamese)
        _ = expander.consume(character: "t", keyCode: 0, modifiers: [], options: MacroOptions(enabled: true), language: .vietnamese)
        _ = expander.consume(character: "w", keyCode: 0, modifiers: [], options: MacroOptions(enabled: true), language: .vietnamese)
        let matched = expander.consume(
            character: "\n",
            keyCode: 36,
            modifiers: [],
            options: MacroOptions(enabled: true),
            language: .vietnamese
        )
        XCTAssertEqual(matched?.text, "by the way")
    }

    private func expand(_ expander: inout MacroExpander, trigger: String, language: InputLanguage) -> MacroExpansion? {
        for character in trigger {
            _ = expander.consume(
                character: character,
                keyCode: 0,
                modifiers: [],
                options: MacroOptions(enabled: true),
                language: language
            )
        }
        return expander.consume(
            character: "\n",
            keyCode: 36,
            modifiers: [],
            options: MacroOptions(enabled: true),
            language: language
        )
    }

    func testBothCategory_ExpandsInVietnameseAndEnglish() {
        var expander = MacroExpander()
        expander.update(macros: [Macro(trigger: "btw", expansion: "by the way", category: .both)])
        XCTAssertNotNil(expand(&expander, trigger: "btw", language: .vietnamese))
        XCTAssertNotNil(expand(&expander, trigger: "btw", language: .english))
    }

    func testEnglishCategory_ExpandsOnlyInEnglish() {
        var expander = MacroExpander()
        expander.update(macros: [Macro(trigger: "btw", expansion: "by the way", category: .english)])
        XCTAssertNil(expand(&expander, trigger: "btw", language: .vietnamese))
        XCTAssertNotNil(expand(&expander, trigger: "btw", language: .english))
    }

    func testVietnameseCategory_ExpandsOnlyInVietnamese() {
        var expander = MacroExpander()
        expander.update(macros: [Macro(trigger: "btw", expansion: "by the way", category: .vietnamese)])
        XCTAssertNotNil(expand(&expander, trigger: "btw", language: .vietnamese))
        XCTAssertNil(expand(&expander, trigger: "btw", language: .english))
    }

    func testSameTriggerDifferentCategories_MatchesByLanguage() {
        var expander = MacroExpander()
        expander.update(macros: [
            Macro(trigger: "cmp", expansion: "git commit", category: .english),
            Macro(trigger: "cmp", expansion: "xin chào", category: .vietnamese),
        ])
        XCTAssertEqual(expand(&expander, trigger: "cmp", language: .vietnamese)?.text, "xin chào")
        XCTAssertEqual(expand(&expander, trigger: "cmp", language: .english)?.text, "git commit")
    }
}
