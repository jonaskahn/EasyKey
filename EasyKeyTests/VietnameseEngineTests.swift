@testable import EasyEngineCore
import XCTest

final class VietnameseEngineTests: XCTestCase {
    // MARK: - Configuration

    func testDefaultConfiguration() {
        let engine = VietnameseEngine()
        XCTAssertEqual(engine.configuration.inputMethod, .telex)
        XCTAssertEqual(engine.configuration.outputEncoding, .unicode)
    }

    // MARK: - Telex: basic pass-through

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

    // MARK: - Telex: tones

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

    // MARK: - Telex: diacritical transforms

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
        XCTAssertEqual(engine.currentBuffer, "a")
    }

    func testTelexTripleERevertsEcircumflex() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("s"))
        _ = engine.process(event: .char("e"))
        _ = engine.process(event: .char("e"))
        _ = engine.process(event: .char("e"))
        XCTAssertEqual(engine.currentBuffer, "se")
    }

    func testTelexTripleORevertsOcircumflex() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("o"))
        _ = engine.process(event: .char("o"))
        _ = engine.process(event: .char("o"))
        XCTAssertEqual(engine.currentBuffer, "o")
    }

    func testTelexQuadrupleARetransformsAcircumflex() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: .char("a"))
        XCTAssertEqual(engine.currentBuffer, "â")
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

    // MARK: - Telex: combined transforms

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

    // MARK: - VNI: tones

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

    // MARK: - VNI: diacritics

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

    // MARK: - Word boundaries

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

    // MARK: - Movement keys

    func testArrowKeyResetsSession() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("t"))
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: KeyEvent(kind: .leftArrow))
        XCTAssertEqual(engine.currentBuffer, "")
        XCTAssertEqual(engine.process(event: .char("x")).disposition, .suppress)
        XCTAssertEqual(engine.currentBuffer, "x")
    }

    // MARK: - Escape

    func testEscapeResetsSession() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("t"))
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: KeyEvent(kind: .escape))
        XCTAssertEqual(engine.currentBuffer, "")
    }

    // MARK: - Backspace

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

    // MARK: - Uppercase

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

    // MARK: - Uppercase first character (sentence auto-capitalization)

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

    func testUppercaseFirstCharacterDisabledDoesNothing() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("t"))
        _ = engine.process(event: .char("a"))
        XCTAssertEqual(engine.currentBuffer, "ta")
    }

    // MARK: - Reset

    func testResetClearsState() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("t"))
        _ = engine.process(event: .char("a"))
        engine.reset()
        XCTAssertEqual(engine.currentBuffer, "")
    }

    // MARK: - Punctuation breaks word

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
