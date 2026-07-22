@testable import EasyEngineCore
import XCTest

final class VietnameseEngineTests: XCTestCase {
    func testDefaultConfiguration() {
        let engine = VietnameseEngine()
        XCTAssertEqual(engine.configuration.inputMethod, .simpleTelex)
        XCTAssertEqual(engine.configuration.outputEncoding, .unicode)
    }

    func testTelexPassThroughConsonants() {
        var engine = VietnameseEngine()
        let result = engine.process(event: .char("t"))
        XCTAssertEqual(result.disposition, .suppress)
        XCTAssertEqual(engine.currentBuffer, "t")
    }

    func testTelexPassThroughVowels() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("t"))
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: .char("i"))
        XCTAssertEqual(engine.currentBuffer, "tai")
    }

    func testTelexAcuteTone() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("t"))
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: .char("i"))
        _ = engine.process(event: .char("s"))
        XCTAssertEqual(engine.currentBuffer, "tái")
    }

    func testTelexGraveTone() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("t"))
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: .char("i"))
        _ = engine.process(event: .char("f"))
        XCTAssertEqual(engine.currentBuffer, "tài")
    }

    func testTelexHookTone() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("t"))
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: .char("i"))
        _ = engine.process(event: .char("r"))
        XCTAssertEqual(engine.currentBuffer, "tải")
    }

    func testTelexTildeTone() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("t"))
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: .char("i"))
        _ = engine.process(event: .char("x"))
        XCTAssertEqual(engine.currentBuffer, "tãi")
    }

    func testTelexDotBelowTone() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("t"))
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: .char("i"))
        _ = engine.process(event: .char("j"))
        XCTAssertEqual(engine.currentBuffer, "tại")
    }

    func testTelexDoubleAProducesAcircumflex() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: .char("a"))
        XCTAssertEqual(engine.currentBuffer, "â")
    }

    func testTelexDoubleEProducesEcircumflex() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("e"))
        _ = engine.process(event: .char("e"))
        XCTAssertEqual(engine.currentBuffer, "ê")
    }

    func testTelexDoubleOProducesOcircumflex() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("o"))
        _ = engine.process(event: .char("o"))
        XCTAssertEqual(engine.currentBuffer, "ô")
    }

    func testTelexTripleARevertsAcircumflex() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: .char("a"))
        XCTAssertEqual(engine.currentBuffer, "aa")
    }

    func testTelexTripleERevertsEcircumflex() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("s"))
        _ = engine.process(event: .char("e"))
        _ = engine.process(event: .char("e"))
        _ = engine.process(event: .char("e"))
        XCTAssertEqual(engine.currentBuffer, "see")
    }

    func testTelexTripleORevertsOcircumflex() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("o"))
        _ = engine.process(event: .char("o"))
        _ = engine.process(event: .char("o"))
        XCTAssertEqual(engine.currentBuffer, "oo")
    }

    func testTelexQuadrupleARetransformsAcircumflex() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: .char("a"))
        XCTAssertEqual(engine.currentBuffer, "aâ")
    }

    func testTelexDoubleDProducesDstroke() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("d"))
        _ = engine.process(event: .char("d"))
        XCTAssertEqual(engine.currentBuffer, "đ")
    }

    func testTelexOWProducesOhorn() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("o"))
        _ = engine.process(event: .char("w"))
        XCTAssertEqual(engine.currentBuffer, "ơ")
    }

    func testTelexUWProducesUhorn() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("u"))
        _ = engine.process(event: .char("w"))
        XCTAssertEqual(engine.currentBuffer, "ư")
    }

    func testTelexChoWithGraveTone() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "chof")
        XCTAssertEqual(engine.currentBuffer, "chò")
    }

    func testTelexAcircumflexWithAcuteTone() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: .char("s"))
        XCTAssertEqual(engine.currentBuffer, "ấ")
    }

    func testVNIacuteTone() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(inputMethod: .vni))
        _ = engine.process(event: .char("t"))
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: .char("i"))
        _ = engine.process(event: .char("1"))
        XCTAssertEqual(engine.currentBuffer, "tái")
    }

    func testVNIGraveTone() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(inputMethod: .vni))
        _ = engine.process(event: .char("t"))
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: .char("i"))
        _ = engine.process(event: .char("2"))
        XCTAssertEqual(engine.currentBuffer, "tài")
    }

    func testVNICircumflex() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(inputMethod: .vni))
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: .char("6"))
        XCTAssertEqual(engine.currentBuffer, "â")
    }

    func testVNIHornOnO() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(inputMethod: .vni))
        _ = engine.process(event: .char("o"))
        _ = engine.process(event: .char("7"))
        XCTAssertEqual(engine.currentBuffer, "ơ")
    }

    func testVNIBreve() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(inputMethod: .vni))
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: .char("8"))
        XCTAssertEqual(engine.currentBuffer, "ă")
    }

    func testVNIDStroke() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(inputMethod: .vni))
        _ = engine.process(event: .char("d"))
        _ = engine.process(event: .char("9"))
        XCTAssertEqual(engine.currentBuffer, "đ")
    }

    func testSpaceFlushesAndResets() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("t"))
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: .char("i"))
        let result = engine.process(event: KeyEvent(kind: .space))
        XCTAssertEqual(engine.currentBuffer, "")
        XCTAssertEqual(result.sessionEffect, .resetSession)
    }

    func testReturnFlushesAndResets() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("x"))
        _ = engine.process(event: .char("i"))
        _ = engine.process(event: .char("n"))
        let result = engine.process(event: KeyEvent(kind: .return))
        XCTAssertEqual(engine.currentBuffer, "")
        XCTAssertEqual(result.sessionEffect, .resetSession)
    }

    func testArrowKeyResetsSession() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("t"))
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: KeyEvent(kind: .leftArrow))
        XCTAssertEqual(engine.currentBuffer, "")
        XCTAssertEqual(engine.process(event: .char("x")).disposition, .suppress)
        XCTAssertEqual(engine.currentBuffer, "x")
    }

    func testEscapeResetsSession() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("t"))
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: KeyEvent(kind: .escape))
        XCTAssertEqual(engine.currentBuffer, "")
    }

    func testBackspaceRemovesLastAtom() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("t"))
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: .char("i"))
        _ = engine.process(event: KeyEvent(kind: .backspace))
        XCTAssertEqual(engine.currentBuffer, "ta")
    }

    func testBackspaceOnEmptyBufferPasses() {
        var engine = VietnameseEngine()
        let result = engine.process(event: KeyEvent(kind: .backspace))
        XCTAssertEqual(result.disposition, .pass)
    }

    func testBackspaceAfterTransform() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: .char("a"))
        XCTAssertEqual(engine.currentBuffer, "â")
        _ = engine.process(event: KeyEvent(kind: .backspace))
        XCTAssertEqual(engine.currentBuffer, "a")
    }

    func testUppercaseCharacter() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("T", shift: true))
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: .char("i"))
        _ = engine.process(event: .char("f"))
        XCTAssertEqual(engine.currentBuffer, "Tài")
    }

    func testUppercaseLeadingHornTransform() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("U", shift: true))
        _ = engine.process(event: .char("w"))
        _ = engine.process(event: .char("n"))
        _ = engine.process(event: .char("g"))
        XCTAssertEqual(engine.currentBuffer, "Ưng")
    }

    func testUppercaseFirstCharacterCapitalizesAtSessionStart() {
        var configuration = EngineConfiguration()
        configuration.uppercaseFirstCharacter = true
        var engine = VietnameseEngine(configuration: configuration)
        _ = engine.process(event: .char("t"))
        _ = engine.process(event: .char("a"))
        XCTAssertEqual(engine.currentBuffer, "Ta")
    }

    func testUppercaseFirstCharacterCapitalizesAfterSentenceTerminator() {
        var configuration = EngineConfiguration()
        configuration.uppercaseFirstCharacter = true
        var engine = VietnameseEngine(configuration: configuration)
        _ = engine.process(event: .char("h"))
        _ = engine.process(event: .char("i"))
        _ = engine.process(event: .char("."))
        _ = engine.process(event: .char("t"))
        _ = engine.process(event: .char("a"))
        XCTAssertEqual(engine.currentBuffer, "Ta")
    }

    func testUppercaseFirstCharacterDoesNotCapitalizeAfterPlainSpace() {
        var configuration = EngineConfiguration()
        configuration.uppercaseFirstCharacter = true
        var engine = VietnameseEngine(configuration: configuration)
        _ = engine.process(event: .char("t"))
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: KeyEvent(kind: .space))
        _ = engine.process(event: .char("m"))
        _ = engine.process(event: .char("a"))
        XCTAssertEqual(engine.currentBuffer, "ma")
    }

    func testUppercaseFirstCharacterTracksPassThroughSentenceTerminator() {
        var configuration = EngineConfiguration()
        configuration.uppercaseFirstCharacter = true
        var engine = VietnameseEngine(configuration: configuration)
        _ = engine.process(event: .char("h"))
        _ = engine.process(event: KeyEvent(kind: .space))
        _ = engine.process(event: .char("."))

        _ = engine.process(event: .char("t"))

        XCTAssertEqual(engine.currentBuffer, "T")
    }

    func testNavigationResetDoesNotStartNewSentence() {
        var configuration = EngineConfiguration()
        configuration.uppercaseFirstCharacter = true
        var engine = VietnameseEngine(configuration: configuration)
        _ = engine.process(event: .char("h"))
        _ = engine.process(event: KeyEvent(kind: .space))
        _ = engine.process(event: KeyEvent(kind: .leftArrow))

        _ = engine.process(event: .char("t"))

        XCTAssertEqual(engine.currentBuffer, "t")
    }

    func testCompositionResetPreservesSentenceLifecycle() {
        var configuration = EngineConfiguration()
        configuration.uppercaseFirstCharacter = true
        var engine = VietnameseEngine(configuration: configuration)
        _ = engine.process(event: .char("h"))
        _ = engine.process(event: KeyEvent(kind: .space))

        engine.resetComposition()
        _ = engine.process(event: .char("t"))

        XCTAssertEqual(engine.currentBuffer, "t")
    }

    func testUppercaseFirstCharacterDisabledDoesNothing() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("t"))
        _ = engine.process(event: .char("a"))
        XCTAssertEqual(engine.currentBuffer, "ta")
    }

    func testResetClearsState() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("t"))
        _ = engine.process(event: .char("a"))
        engine.reset()
        XCTAssertEqual(engine.currentBuffer, "")
    }

    func testPunctuationBreaksWord() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("c"))
        _ = engine.process(event: .char("h"))
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: .char("o"))
        let result = engine.process(event: .char("."))
        XCTAssertEqual(result.sessionEffect, .resetSession)
        XCTAssertEqual(engine.currentBuffer, "")
    }
}
