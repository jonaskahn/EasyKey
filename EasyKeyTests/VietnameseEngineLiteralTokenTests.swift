@testable import EasyEngineCore
import XCTest

final class VietnameseEngineLiteralTokenTests: XCTestCase {
    private func typeKeys(_ engine: inout VietnameseEngine, _ keys: String) -> [EngineOutput] {
        keys.map { engine.process(event: .char($0)) }
    }

    private func literalEngine(
        literalTechnicalTokens: Bool = true,
        uppercaseFirstCharacter: Bool = false
    ) -> VietnameseEngine {
        VietnameseEngine(
            configuration: EngineConfiguration(
                uppercaseFirstCharacter: uppercaseFirstCharacter,
                literalTechnicalTokens: literalTechnicalTokens
            )
        )
    }

    // MARK: - Prefixes

    func testSlashCommandTypesLiterally() {
        var engine = literalEngine()
        let outputs = typeKeys(&engine, "/status")
        XCTAssertTrue(outputs.allSatisfy { $0.disposition == .suppress })
        XCTAssertEqual(
            outputs.map(\.edits),
            ["/", "s", "t", "a", "t", "u", "s"].map { [.insert($0)] }
        )
        XCTAssertTrue(engine.state.isEmpty)
    }

    func testAtMentionTypesLiterally() {
        var engine = literalEngine()
        _ = typeKeys(&engine, "@user")
        XCTAssertEqual(engine.state.rawText, "")
        XCTAssertEqual(engine.currentBuffer, "")
    }

    func testHashReferenceTypesLiterally() {
        var engine = literalEngine()
        _ = typeKeys(&engine, "#123")
        XCTAssertTrue(engine.state.isEmpty)
    }

    func testShellModeTypesLiterally() {
        var engine = literalEngine()
        _ = typeKeys(&engine, "!ls")
        XCTAssertTrue(engine.state.isEmpty)
    }

    func testShortcodeTypesLiterally() {
        var engine = literalEngine()
        _ = typeKeys(&engine, ":smile:")
        XCTAssertTrue(engine.state.isEmpty)
    }

    // MARK: - Vietnamese-sensitive content

    func testTelexSensitiveTokenStaysLiteral() {
        var engine = literalEngine()
        _ = typeKeys(&engine, "/tooi")
        XCTAssertEqual(engine.state.rawText, "")
        XCTAssertEqual(engine.currentBuffer, "")
    }

    func testVietnameseResumesAfterWhitespace() {
        var engine = literalEngine()
        _ = typeKeys(&engine, "/status")
        let space = engine.process(event: KeyEvent(kind: .space))
        XCTAssertEqual(space.disposition, .pass)

        _ = typeKeys(&engine, "tooi")
        XCTAssertEqual(engine.currentBuffer, "tôi")
        XCTAssertEqual(engine.state.rawText, "tooi")
    }

    func testVietnameseResumesAfterReturnAndTab() {
        var engine = literalEngine()
        _ = typeKeys(&engine, "@user")
        XCTAssertEqual(engine.process(event: KeyEvent(kind: .return)).disposition, .pass)
        _ = typeKeys(&engine, "tooi")
        XCTAssertEqual(engine.currentBuffer, "tôi")

        var tabEngine = literalEngine()
        _ = typeKeys(&tabEngine, "@user")
        XCTAssertEqual(tabEngine.process(event: KeyEvent(kind: .tab)).disposition, .pass)
        _ = typeKeys(&tabEngine, "tooi")
        XCTAssertEqual(tabEngine.currentBuffer, "tôi")
    }

    // MARK: - Token contents

    func testPunctuationInsideTokenStaysLiteral() {
        var engine = literalEngine()
        _ = typeKeys(&engine, "/usr/local/bin")
        XCTAssertTrue(engine.state.isEmpty)
    }

    func testUppercaseInsideMentionStaysLiteral() {
        var engine = literalEngine()
        _ = typeKeys(&engine, "@")
        _ = engine.process(event: .char("U", shift: true))
        _ = typeKeys(&engine, "ser")
        XCTAssertTrue(engine.state.isEmpty)
        XCTAssertEqual(engine.currentBuffer, "")
    }

    func testMidWordSlashDoesNotTriggerLiteralMode() {
        var engine = literalEngine()
        _ = typeKeys(&engine, "hello")
        let slash = engine.process(event: .char("/"))
        XCTAssertEqual(slash.sessionEffect, .resetSession)

        _ = typeKeys(&engine, "tooi")
        XCTAssertEqual(engine.currentBuffer, "tôi")
    }

    func testPrefixAfterComposedWordBoundaryIsLiteral() {
        var engine = literalEngine()
        _ = typeKeys(&engine, "chao")
        _ = engine.process(event: KeyEvent(kind: .space))
        _ = typeKeys(&engine, "@user")
        XCTAssertTrue(engine.state.isEmpty)
        XCTAssertEqual(engine.currentBuffer, "")
    }

    // MARK: - Backspace

    func testBackspaceDeletesLiteralCharactersOneAtATime() {
        var engine = literalEngine()
        _ = typeKeys(&engine, "/statu")
        let backspace = engine.process(event: KeyEvent(kind: .backspace))
        XCTAssertEqual(backspace.disposition, .suppress)
        XCTAssertEqual(backspace.edits, [.deleteBackward(1)])
    }

    func testBackspacingThroughPrefixExitsLiteralMode() {
        var engine = literalEngine()
        _ = typeKeys(&engine, "/tooi")
        for _ in 0 ..< 5 {
            _ = engine.process(event: KeyEvent(kind: .backspace))
        }
        _ = typeKeys(&engine, "tooi")
        XCTAssertEqual(engine.currentBuffer, "tôi")
    }

    func testBackspaceAfterLiteralTokenDoesNotAffectComposition() {
        var engine = literalEngine()
        _ = typeKeys(&engine, "/tooi")
        _ = engine.process(event: KeyEvent(kind: .space))
        _ = typeKeys(&engine, "t")
        let backspace = engine.process(event: KeyEvent(kind: .backspace))
        XCTAssertEqual(backspace.disposition, .suppress)
        XCTAssertEqual(engine.currentBuffer, "")
        XCTAssertTrue(engine.state.isEmpty)
    }

    // MARK: - Reset and modifiers

    func testArrowKeyResetsLiteralMode() {
        var engine = literalEngine()
        _ = typeKeys(&engine, "/stat")
        _ = engine.process(event: KeyEvent(kind: .rightArrow))
        _ = typeKeys(&engine, "tooi")
        XCTAssertEqual(engine.currentBuffer, "tôi")
    }

    func testModifierCharacterKeepsLiteralModeActive() {
        var engine = literalEngine()
        _ = typeKeys(&engine, "@u")
        let modified = engine.process(event: KeyEvent(kind: .character("X"), control: true))
        XCTAssertEqual(modified.disposition, .pass)
        let outputs = typeKeys(&engine, "ser")
        XCTAssertTrue(outputs.allSatisfy { $0.disposition == .suppress })
        XCTAssertTrue(engine.state.isEmpty)
    }

    // MARK: - Sentence context

    func testLoneExclamationStillStartsNewSentence() {
        var engine = literalEngine(uppercaseFirstCharacter: true)
        _ = typeKeys(&engine, "!")
        _ = engine.process(event: KeyEvent(kind: .space))
        _ = typeKeys(&engine, "xin")
        XCTAssertEqual(engine.currentBuffer, "Xin")
    }

    // MARK: - Disabled option

    func testDisabledOptionComposesAsBefore() {
        var engine = literalEngine(literalTechnicalTokens: false)
        let slash = engine.process(event: .char("/"))
        XCTAssertEqual(slash.disposition, .pass)

        _ = typeKeys(&engine, "tooi")
        XCTAssertEqual(engine.currentBuffer, "tôi")
    }

    func testDisabledOptionStillHandlesMentionContentAsVietnamese() {
        var engine = literalEngine(literalTechnicalTokens: false)
        _ = typeKeys(&engine, "@tooi")
        XCTAssertEqual(engine.currentBuffer, "tôi")
        XCTAssertEqual(engine.state.rawText, "tooi")
    }
}
