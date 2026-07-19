@testable import EasyEngineCore
import XCTest

final class VietnameseEngineEdgeCaseTests: XCTestCase {
    func testProcessWhenDisabled() {
        let state = SessionState(isDisabled: true)
        let config = EngineConfiguration()
        let result = TransformEngine.apply(intent: .passThrough("a"), state: state, configuration: config)
        XCTAssertEqual(result.newContent, "a")
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
        XCTAssertEqual(engine.currentBuffer, "a")
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

    func testMarkAddOnEmptyBuffer() {
        var engine = VietnameseEngine()
        let result = engine.process(event: .char("w"))
        XCTAssertEqual(engine.currentBuffer, "w")
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
        XCTAssertEqual(engine.currentBuffer, "d")
    }

    func testQuadrupleDCyclesBackToDstroke() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "dddd")
        XCTAssertEqual(engine.currentBuffer, "đ")
    }

    func testTripleDUppercasePreservesCase() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("D", shift: true))
        _ = engine.process(event: .char("D", shift: true))
        XCTAssertEqual(engine.currentBuffer, "Đ")
        _ = engine.process(event: .char("D", shift: true))
        XCTAssertEqual(engine.currentBuffer, "D")
    }

    func testTripleDRevertsStrokeUnderSimpleTelex() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(inputMethod: .simpleTelex))
        typeKeys(&engine, "ddd")
        XCTAssertEqual(engine.currentBuffer, "d")
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
        XCTAssertEqual(engine.currentBuffer, "ơw")
    }

    func testQuickTelexRepeatedWRestoresVowelAndKeepsLiteralW() {
        for method in [InputMethod.telex, .simpleTelex] {
            var engine = VietnameseEngine(configuration: EngineConfiguration(inputMethod: method, quickTelex: true))
            typeKeys(&engine, "show")
            XCTAssertEqual(engine.currentBuffer, "shơ", "method: \(method)")
            _ = engine.process(event: .char("w"))
            XCTAssertEqual(engine.currentBuffer, "show", "method: \(method)")
        }
    }

    func testQuickTelexStandaloneWCyclesAfterEveryCanonicalOnset() {
        let onsets = VietnameseCharacters.startConsonants.sorted()
        for method in [InputMethod.telex, .simpleTelex] {
            for onset in onsets {
                var engine = VietnameseEngine(configuration: EngineConfiguration(inputMethod: method, quickTelex: true))
                typeKeys(&engine, onset + "w")
                XCTAssertEqual(engine.currentBuffer, onset + "ư", "method: \(method), onset: \(onset)")
                _ = engine.process(event: .char("w"))
                XCTAssertEqual(engine.currentBuffer, onset + "ơ", "method: \(method), onset: \(onset)")
                _ = engine.process(event: .char("w"))
                XCTAssertEqual(engine.currentBuffer, onset + "w", "method: \(method), onset: \(onset)")
                _ = engine.process(event: .char("w"))
                XCTAssertEqual(engine.currentBuffer, onset + "ư", "method: \(method), onset: \(onset)")
            }
        }
    }

    func testQuickTelexStandaloneWCyclesWithEmptyBuffer() {
        for method in [InputMethod.telex, .simpleTelex] {
            var engine = VietnameseEngine(configuration: EngineConfiguration(inputMethod: method, quickTelex: true))
            typeKeys(&engine, "w")
            XCTAssertEqual(engine.currentBuffer, "ư", "method: \(method)")
            typeKeys(&engine, "w")
            XCTAssertEqual(engine.currentBuffer, "ơ", "method: \(method)")
            typeKeys(&engine, "w")
            XCTAssertEqual(engine.currentBuffer, "w", "method: \(method)")
        }
    }

    func testQuickTelexStandaloneWCyclePreservesInitialCapitalization() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(quickTelex: true))
        typeKeys(&engine, "Ww")
        XCTAssertEqual(engine.currentBuffer, "Ơ")
        _ = engine.process(event: .char("w"))
        XCTAssertEqual(engine.currentBuffer, "W")
    }

    func testQuickTelexInvalidOnsetPrefixKeepsWLiteral() {
        for method in [InputMethod.telex, .simpleTelex] {
            var engine = VietnameseEngine(configuration: EngineConfiguration(inputMethod: method, quickTelex: true))
            typeKeys(&engine, "zw")
            XCTAssertEqual(engine.currentBuffer, "zw", "method: \(method)")
        }
    }

    func testQuickTelexExcludesQUAndGIOnsetVowelsFromWTransform() {
        for method in [InputMethod.telex, .simpleTelex] {
            var quEngine = VietnameseEngine(configuration: EngineConfiguration(inputMethod: method, quickTelex: true))
            typeKeys(&quEngine, "quow")
            XCTAssertEqual(quEngine.currentBuffer, "quơ", "method: \(method)")

            var giEngine = VietnameseEngine(configuration: EngineConfiguration(inputMethod: method, quickTelex: true))
            typeKeys(&giEngine, "giw")
            XCTAssertEqual(giEngine.currentBuffer, "giư", "method: \(method)")
        }
    }

    func testWTransformDoesNotReachAcrossConsonantToEarlierVowel() {
        // "alwways" (a typo of "always" with an extra w) previously came out as "ălways":
        // the w-transform's backward vowel scan reached past the "l" consonant and put a
        // breve on the leading "a". It must now stop at the first consonant it hits, so
        // the "a" stays untouched. (The trailing "s" still triggers the *tone* key — a
        // separate, pre-existing Telex/English collision unrelated to this fix — so the
        // buffer is not fully plain ASCII, but the leading "a" must never carry a mark.)
        for quickTelex in [false, true] {
            for method in [InputMethod.telex, .simpleTelex] {
                var engine = VietnameseEngine(configuration: EngineConfiguration(inputMethod: method, quickTelex: quickTelex))
                typeKeys(&engine, "alwways")
                XCTAssertEqual(engine.currentBuffer, "alwwáy", "method: \(method), quickTelex: \(quickTelex)")

                var anwEngine = VietnameseEngine(configuration: EngineConfiguration(inputMethod: method, quickTelex: quickTelex))
                typeKeys(&anwEngine, "anw")
                XCTAssertEqual(anwEngine.currentBuffer, "anw", "method: \(method), quickTelex: \(quickTelex)")

                var amwEngine = VietnameseEngine(configuration: EngineConfiguration(inputMethod: method, quickTelex: quickTelex))
                typeKeys(&amwEngine, "amw")
                XCTAssertEqual(amwEngine.currentBuffer, "amw", "method: \(method), quickTelex: \(quickTelex)")
            }
        }
    }

    func testQuickTelexDisabledPreservesStandardMethodBehavior() {
        for method in [InputMethod.telex, .simpleTelex] {
            var engine = VietnameseEngine(configuration: EngineConfiguration(inputMethod: method))
            typeKeys(&engine, "thw")
            XCTAssertEqual(engine.currentBuffer, "thw", "method: \(method)")

            var showEngine = VietnameseEngine(configuration: EngineConfiguration(inputMethod: method))
            typeKeys(&showEngine, "showw")
            let expected = method == .telex ? "shơw" : "showw"
            XCTAssertEqual(showEngine.currentBuffer, expected, "method: \(method)")

            var quEngine = VietnameseEngine(configuration: EngineConfiguration(inputMethod: method))
            typeKeys(&quEngine, "quw")
            XCTAssertEqual(quEngine.currentBuffer, "quw", "method: \(method)")
        }
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
        XCTAssertEqual(engine.currentBuffer, "a")
        _ = engine.process(event: KeyEvent(kind: .backspace))
        XCTAssertEqual(engine.currentBuffer, "")
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
        XCTAssertEqual(engine.currentBuffer, "a")
    }

    func testRevertDStroke_OnBaseWithoutStroke_PassThrough() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "dd") // đ
        _ = engine.process(event: .char("d")) // now it should revert
        XCTAssertEqual(engine.currentBuffer, "d")
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
}
