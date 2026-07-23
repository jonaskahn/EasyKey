@testable import EasyEngineCore
import XCTest

final class VietnameseEngineEdgeCaseTests: XCTestCase {
    func testProcessWhenDisabled() {
        var engine = VietnameseEngine()
        engine.state.isDisabled = true
        let result = engine.process(event: .char("a"))
        XCTAssertEqual(result, .passThrough)
    }

    func testForwardDeleteResets() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("a"))
        let result = engine.process(event: KeyEvent(kind: .forwardDelete))
        XCTAssertEqual(result.disposition, .pass)
        XCTAssertEqual(engine.currentBuffer, "")
    }

    func testOtherKindResets() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("a"))
        let result = engine.process(event: KeyEvent(kind: .other))
        XCTAssertEqual(result.disposition, .pass)
        XCTAssertEqual(engine.currentBuffer, "")
    }

    func testTabFlushesBuffer() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("a"))
        let result = engine.process(event: KeyEvent(kind: .tab))
        XCTAssertEqual(result.sessionEffect, .resetSession)
        XCTAssertEqual(engine.currentBuffer, "")
    }

    func testBackspaceRemovesMark() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(outputEncoding: .unicode))
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: .char("a"))
        XCTAssertEqual(engine.currentBuffer, "â")
        _ = engine.process(event: KeyEvent(kind: .backspace))
        XCTAssertEqual(engine.currentBuffer, "a")
    }

    func testBackspaceRemovesOnlyToneWhenMarkExists() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(outputEncoding: .unicode))
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: .char("s"))
        XCTAssertEqual(engine.currentBuffer, "ấ")
        _ = engine.process(event: KeyEvent(kind: .backspace))
        XCTAssertEqual(engine.currentBuffer, "â")
    }

    func testBackspaceOnLastAtomAfterToneRemoval() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("t"))
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: .char("s"))
        XCTAssertEqual(engine.currentBuffer, "tá")
        _ = engine.process(event: KeyEvent(kind: .backspace))
        XCTAssertEqual(engine.currentBuffer, "ta")
        _ = engine.process(event: KeyEvent(kind: .backspace))
        XCTAssertEqual(engine.currentBuffer, "t")
        _ = engine.process(event: KeyEvent(kind: .backspace))
        XCTAssertEqual(engine.currentBuffer, "")
    }

    func testCommaBreaksWord() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("a"))
        let result = engine.process(event: .char(","))
        XCTAssertEqual(result.sessionEffect, .resetSession)
        XCTAssertEqual(engine.currentBuffer, "")
    }

    func testSemicolonBreaksWord() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("a"))
        let result = engine.process(event: .char(";"))
        XCTAssertEqual(result.sessionEffect, .resetSession)
    }

    func testExclamationMarkBreaksWord() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("a"))
        let result = engine.process(event: .char("!"))
        XCTAssertEqual(result.sessionEffect, .resetSession)
    }

    func testQuestionMarkBreaksWord() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("a"))
        let result = engine.process(event: .char("?"))
        XCTAssertEqual(result.sessionEffect, .resetSession)
    }

    func testProcessMovementKeys() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("a"))
        for kind: KeyEvent.Kind in [.rightArrow, .upArrow, .downArrow] {
            var testEngine = engine
            let result = testEngine.process(event: KeyEvent(kind: kind))
            XCTAssertEqual(result.disposition, .pass)
            XCTAssertEqual(testEngine.currentBuffer, "")
        }
    }

    func testModifierKeyWithEmptyBuffer() {
        var engine = VietnameseEngine()
        let result = engine.process(event: KeyEvent(kind: .character("a"), command: true))
        XCTAssertEqual(result.disposition, .pass)
    }

    func testModifiedCharactersPassThroughAndResetNonEmptyBuffer() {
        let events = [
            KeyEvent(kind: .character("b"), control: true),
            KeyEvent(kind: .character("b"), option: true),
            KeyEvent(kind: .character("b"), command: true),
        ]

        for event in events {
            var engine = VietnameseEngine()
            _ = engine.process(event: .char("t"))
            _ = engine.process(event: .char("a"))

            let result = engine.process(event: event)

            XCTAssertEqual(result, .passThrough)
            XCTAssertEqual(engine.currentBuffer, "")
        }
    }

    func testWordBoundarySpaceWithEmptyBuffer() {
        var engine = VietnameseEngine()
        let result = engine.process(event: KeyEvent(kind: .space))
        XCTAssertEqual(result.disposition, .pass)
    }

    func testWordBoundaryReturnWithEmptyBuffer() {
        var engine = VietnameseEngine()
        let result = engine.process(event: KeyEvent(kind: .return))
        XCTAssertEqual(result.disposition, .pass)
    }

    func testDoubleVowelTransformOnEmtpyBuffer() {
        var engine = VietnameseEngine()
        let result = engine.process(event: .char("a"))
        XCTAssertEqual(engine.currentBuffer, "a")
    }

    func testTransformDStrokeOnNonD() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("b"))
        let result = engine.process(event: .char("d"))
        XCTAssertEqual(engine.currentBuffer, "bd")
    }

    func testTransformHornGuardClauseFails() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: .char("w"))
        XCTAssertEqual(engine.currentBuffer, "ă")
    }

    func testBackspaceStepByStepVietnameseWord() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(outputEncoding: .unicode))
        typeKeys(&engine, "vieetj")
        XCTAssertEqual(engine.currentBuffer, "việt")

        _ = engine.process(event: KeyEvent(kind: .backspace))
        XCTAssertEqual(engine.currentBuffer, "viêt")

        _ = engine.process(event: KeyEvent(kind: .backspace))
        XCTAssertEqual(engine.currentBuffer, "viê")

        _ = engine.process(event: KeyEvent(kind: .backspace))
        XCTAssertEqual(engine.currentBuffer, "vie")
    }

    func testUnicodePrecomposedBackspaceTone() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(outputEncoding: .unicode))
        typeKeys(&engine, "xis")
        XCTAssertEqual(engine.currentBuffer, "xí")
        _ = engine.process(event: KeyEvent(kind: .backspace))
        XCTAssertEqual(engine.currentBuffer, "xi")
    }

    func testEmptyStateBackspaceOnAllPaths() {
        var engine = VietnameseEngine()
        for _ in 0 ..< 5 {
            let result = engine.process(event: KeyEvent(kind: .backspace))
            XCTAssertEqual(result.disposition, .pass)
        }
    }

    func testToneRepeatReturnsToNormal() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "tas")
        XCTAssertEqual(engine.currentBuffer, "tá")
        _ = engine.process(event: .char("s"))
        XCTAssertEqual(engine.currentBuffer, "tas")
    }

    func testStandaloneWOnEmptyBuffer() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(inputMethod: .telex))
        let result = engine.process(event: .char("w"))
        XCTAssertEqual(engine.currentBuffer, "ư")
        XCTAssertEqual(result.disposition, .suppress)
    }

    func testToneOnEmptyBuffer() {
        var engine = VietnameseEngine()
        let result = engine.process(event: .char("s"))
        XCTAssertEqual(engine.currentBuffer, "s")
        XCTAssertEqual(result.disposition, .suppress)
    }

    func testDStrokeOnEmptyBuffer() {
        var engine = VietnameseEngine()
        let result = engine.process(event: .char("d"))
        XCTAssertEqual(engine.currentBuffer, "d")
    }

    func testTripleDRevertsStrokeToLiteralD() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("d"))
        _ = engine.process(event: .char("d"))
        XCTAssertEqual(engine.currentBuffer, "đ")
        _ = engine.process(event: .char("d"))
        XCTAssertEqual(engine.currentBuffer, "dd")
    }

    func testQuadrupleDCyclesBackToDstroke() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "dddd")
        XCTAssertEqual(engine.currentBuffer, "dđ")
    }

    func testTripleDUppercasePreservesCase() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("D", shift: true))
        _ = engine.process(event: .char("D", shift: true))
        XCTAssertEqual(engine.currentBuffer, "Đ")
        _ = engine.process(event: .char("D", shift: true))
        XCTAssertEqual(engine.currentBuffer, "DD")
    }

    func testTripleDRevertsStrokeUnderSimpleTelex() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(inputMethod: .simpleTelex))
        typeKeys(&engine, "ddd")
        XCTAssertEqual(engine.currentBuffer, "dd")
    }

    func testDoubleVowelOnWrongBase() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("o"))
        _ = engine.process(event: .char("a"))
        XCTAssertEqual(engine.currentBuffer, "oa")
    }

    func testWTransformOnHornMarkedVowel() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("o"))
        _ = engine.process(event: .char("w"))
        XCTAssertEqual(engine.currentBuffer, "ơ")
        _ = engine.process(event: .char("w"))
        XCTAssertEqual(engine.currentBuffer, "ow")
    }

    func testSimpleTelexKeepsStandaloneWLiteral() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(inputMethod: .simpleTelex))
        typeKeys(&engine, "tw")
        XCTAssertEqual(engine.currentBuffer, "tw")
    }

    func testFullTelexTransformsStandaloneWAfterOnset() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(inputMethod: .telex))
        typeKeys(&engine, "thw")
        XCTAssertEqual(engine.currentBuffer, "thư")
    }

    func testFullTelexBracketShortcuts() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(inputMethod: .telex))
        typeKeys(&engine, "m[")
        XCTAssertEqual(engine.currentBuffer, "mơ")
    }

    func testSimpleTelexTreatsBracketsAsWordBoundaries() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(inputMethod: .simpleTelex))
        typeKeys(&engine, "m")
        let result = engine.process(event: .char("["))
        XCTAssertEqual(result.sessionEffect, .resetSession)
    }

    func testQuickTelexConsonantsAreOptional() {
        var disabled = VietnameseEngine()
        typeKeys(&disabled, "cc")
        XCTAssertEqual(disabled.currentBuffer, "cc")

        var enabled = VietnameseEngine(configuration: EngineConfiguration(quickTelexConsonants: true))
        typeKeys(&enabled, "cc")
        XCTAssertEqual(enabled.currentBuffer, "ch")
    }

    func testQuGlideIsNotHorned() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "quow")
        XCTAssertEqual(engine.currentBuffer, "quơ")
    }

    func testWTransformDoesNotReachAcrossConsonantToEarlierVowel() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "anw")
        XCTAssertEqual(engine.currentBuffer, "anw")
    }

    func testUnicodeCombiningEncodingOutput() throws {
        var engine = VietnameseEngine(configuration: EngineConfiguration(outputEncoding: .unicodeCombining))
        typeKeys(&engine, "vis")
        let buffer = engine.currentBuffer
        XCTAssertTrue(try buffer.unicodeScalars.contains(XCTUnwrap(Unicode.Scalar(0x0301))))
    }

    func testTCVN3Encoding() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(outputEncoding: .tcvn3))
        typeKeys(&engine, "vis")
        let buffer = engine.currentBuffer
        XCTAssertFalse(buffer.isEmpty)
    }

    func testVNIWindowsEncoding() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(outputEncoding: .vniWindows))
        typeKeys(&engine, "vis")
        let buffer = engine.currentBuffer
        XCTAssertFalse(buffer.isEmpty)
    }

    private func typeKeys(_ engine: inout VietnameseEngine, _ keys: String) {
        for character in keys {
            _ = engine.process(event: .char(character))
        }
    }

    func testProcess_WhenDisabled_PassesThrough() {
        var engine = VietnameseEngine()
        engine.state = SessionState(isDisabled: true)
        let result = engine.process(event: .char("a"))
        XCTAssertEqual(result, .passThrough)
    }

    func testProcessBackspace_RemovingMarkWhenToneExists_RemovesMarkOnly() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(outputEncoding: .unicode))
        typeKeys(&engine, "aa") // â
        typeKeys(&engine, "s") // ấ
        _ = engine.process(event: KeyEvent(kind: .backspace))
        XCTAssertEqual(engine.currentBuffer, "â")
        _ = engine.process(event: KeyEvent(kind: .backspace))
        XCTAssertEqual(engine.currentBuffer, "a")
    }

    func testProcessBackspace_RemovingToneWithoutMark_KeepsAtom() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "as") // á
        _ = engine.process(event: KeyEvent(kind: .backspace))
        XCTAssertEqual(engine.currentBuffer, "a")
    }

    func testRevertDoubleVowel_OnNonCircumflexMark_PassThrough() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "aa") // â, mark is circumflex
        _ = engine.process(event: .char("a")) // revertDoubleVowel: base "a", mark is circumflex → removes mark
        XCTAssertEqual(engine.currentBuffer, "aa")
    }

    func testRevertDStroke_OnBaseWithoutStroke_PassThrough() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "dd") // đ
        _ = engine.process(event: .char("d")) // now it should revert
        XCTAssertEqual(engine.currentBuffer, "dd")
    }

    func testProcessBackspace_ToneAfterRemoveLast_IsCleared() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "as") // á
        // First backspace removes tone
        _ = engine.process(event: KeyEvent(kind: .backspace))
        XCTAssertEqual(engine.currentBuffer, "a")
        // Second backspace removes atom "a"
        _ = engine.process(event: KeyEvent(kind: .backspace))
        XCTAssertEqual(engine.currentBuffer, "")
    }

    func testVNIDropsInvalidToneNumberKey() {
        let config = EngineConfiguration(inputMethod: .vni)
        var engine = VietnameseEngine(configuration: config)
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: .char("c"))
        _ = engine.process(event: .char("2")) // 2 (hỏi) is invalid for checked final 'c'
        XCTAssertEqual(engine.currentBuffer, "ac")
    }

    func testVNIUndoSemantics_OnValidAndInvalidTone() {
        let config = EngineConfiguration(inputMethod: .vni)
        var engine1 = VietnameseEngine(configuration: config)
        typeKeys(&engine1, "a11")
        XCTAssertEqual(engine1.currentBuffer, "a1")

        var engine2 = VietnameseEngine(configuration: config)
        typeKeys(&engine2, "ac22")
        XCTAssertEqual(engine2.currentBuffer, "ac")
    }

    func testSentenceStartCleared_OnBackspaceOrReset() {
        let config = EngineConfiguration(uppercaseFirstCharacter: true)
        var engine = VietnameseEngine(configuration: config)
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: .char("."))
        _ = engine.process(event: .char(" "))
        // atSentenceStart is true; next char 'w' uppercases to 'W'
        _ = engine.process(event: .char("w"))
        XCTAssertEqual(engine.currentBuffer, "W")

        // Backspace to empty buffer clears sentence start
        _ = engine.process(event: KeyEvent(kind: .backspace))
        XCTAssertEqual(engine.currentBuffer, "")
        _ = engine.process(event: .char("w"))
        XCTAssertEqual(engine.currentBuffer, "w")

        // Reset (arrow key) clears sentence start
        _ = engine.process(event: .char("."))
        _ = engine.process(event: .char(" "))
        _ = engine.process(event: KeyEvent(kind: .leftArrow))
        _ = engine.process(event: .char("w"))
        XCTAssertEqual(engine.currentBuffer, "w")
    }

    func testRestoreRawKeys_ClearsForceRawOnNextCharacter() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "tieesng")
        XCTAssertEqual(engine.currentBuffer, "tiếng")
        
        engine.restoreRawKeys()
        XCTAssertEqual(engine.currentBuffer, "tieesng")
        
        // Typing a character after restore commits the raw word and starts a new composition
        _ = engine.process(event: .char("s"))
        XCTAssertEqual(engine.currentBuffer, "s")
    }
}
