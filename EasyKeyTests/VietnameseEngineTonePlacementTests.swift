@testable import EasyEngineCore
import XCTest

final class VietnameseEngineTonePlacementTests: XCTestCase {
    // MARK: - Tone placement in diphthongs

    func testToneOnSingleVowel() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "cas")
        XCTAssertEqual(engine.currentBuffer, "cá")
    }

    func testToneOnOi() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "tois")
        XCTAssertEqual(engine.currentBuffer, "tói")
    }

    func testToneOnAo() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "chaof")
        XCTAssertEqual(engine.currentBuffer, "chào")
    }

    func testToneOnAu() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "caur")
        XCTAssertEqual(engine.currentBuffer, "cảu")
    }

    func testToneOnAi() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "mais")
        XCTAssertEqual(engine.currentBuffer, "mái")
    }

    func testToneOnEo() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "keox")
        XCTAssertEqual(engine.currentBuffer, "kẽo")
    }

    func testToneOnOcircumflexI() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "doois")
        XCTAssertEqual(engine.currentBuffer, "dối")
    }

    func testToneOnUa() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "duaf")
        XCTAssertEqual(engine.currentBuffer, "dùa")
    }

    func testToneOnIa() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "kiaf")
        XCTAssertEqual(engine.currentBuffer, "kìa")
    }

    func testToneOnUaClosedSyllable() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "hoanf")
        XCTAssertEqual(engine.currentBuffer, "hoàn")
    }

    // MARK: - End consonants

    func testEndConsonantC() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "anc")
        XCTAssertEqual(engine.currentBuffer, "anc")
    }

    func testEndConsonantN() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "vifn")
        XCTAssertEqual(engine.currentBuffer, "vìn")
    }

    func testEndConsonantNg() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "vifng")
        XCTAssertEqual(engine.currentBuffer, "vìng")
    }

    func testEndConsonantCh() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "majch")
        XCTAssertEqual(engine.currentBuffer, "mạch")
    }

    func testEndConsonantT() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "motj")
        XCTAssertEqual(engine.currentBuffer, "mọt")
    }

    // MARK: - Common Vietnamese words (Telex)

    func testVietnamWord() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "vieetj")
        XCTAssertEqual(engine.currentBuffer, "việt")
        _ = engine.process(event: KeyEvent(kind: .space))
        typeKeys(&engine, "nam")
        XCTAssertEqual(engine.currentBuffer, "nam")
    }

    func testXinChao() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "xin")
        _ = engine.process(event: KeyEvent(kind: .space))
        typeKeys(&engine, "chaof")
        XCTAssertEqual(engine.currentBuffer, "chào")
    }

    func testCamOn() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "camr")
        _ = engine.process(event: KeyEvent(kind: .space))
        typeKeys(&engine, "own")
        XCTAssertEqual(engine.currentBuffer, "ơn")
    }

    // MARK: - Simple Telex

    func testSimpleTelexTonesOnly() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(inputMethod: .simpleTelex))
        typeKeys(&engine, "taif")
        XCTAssertEqual(engine.currentBuffer, "tài")
    }

    func testSimpleTelexNoDiacritics() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(inputMethod: .simpleTelex))
        typeKeys(&engine, "aa")
        XCTAssertEqual(engine.currentBuffer, "aa")
    }

    // MARK: - Edge cases

    func testToneKeyWithNoVowelFallsBack() {
        var engine = VietnameseEngine()
        let result = engine.process(event: .char("s"))
        XCTAssertEqual(engine.currentBuffer, "s")
        XCTAssertEqual(result.disposition, .suppress)
    }

    func testRepeatedToneKeys() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "tasf")
        XCTAssertEqual(engine.currentBuffer, "tà")
    }

    func testRepeatedToneKeyReplacesPreviousTone() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "arr")
        XCTAssertEqual(engine.currentBuffer, "ar")
    }

    func testBackspaceRemovesTone() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "tas")
        XCTAssertEqual(engine.currentBuffer, "tá")
        _ = engine.process(event: KeyEvent(kind: .backspace))
        XCTAssertEqual(engine.currentBuffer, "ta")
    }

    func testConsecutiveSpaces() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("a"))
        _ = engine.process(event: KeyEvent(kind: .space))
        let result = engine.process(event: KeyEvent(kind: .space))
        XCTAssertEqual(result.disposition, .pass)
    }

    func testControlModifierFlushesAndPasses() {
        var engine = VietnameseEngine()
        _ = engine.process(event: .char("a"))
        let result = engine.process(event: KeyEvent(kind: .character("a"), control: true))
        XCTAssertEqual(result.disposition, .suppress)
        XCTAssertEqual(engine.currentBuffer, "")
    }

    func testControlModifierOnEmptyBufferPasses() {
        var engine = VietnameseEngine()
        let result = engine.process(event: KeyEvent(kind: .character("a"), control: true))
        XCTAssertEqual(result.disposition, .pass)
    }

    // MARK: - Encoding

    func testUnicodeCombiningEncoding() throws {
        var engine = VietnameseEngine(configuration: EngineConfiguration(outputEncoding: .cp1258))
        typeKeys(&engine, "vis")
        let buffer = engine.currentBuffer
        XCTAssertTrue(try buffer.unicodeScalars.contains(XCTUnwrap(Unicode.Scalar(0x0301))))
    }

    // MARK: - Character tables

    func testVietnameseCharactersBaseVowel() {
        XCTAssertEqual(VietnameseCharacters.baseVowel("â"), "a")
        XCTAssertEqual(VietnameseCharacters.baseVowel("ă"), "a")
        XCTAssertEqual(VietnameseCharacters.baseVowel("ê"), "e")
        XCTAssertEqual(VietnameseCharacters.baseVowel("ô"), "o")
        XCTAssertEqual(VietnameseCharacters.baseVowel("ơ"), "o")
        XCTAssertEqual(VietnameseCharacters.baseVowel("ư"), "u")
        XCTAssertEqual(VietnameseCharacters.baseVowel("a"), "a")
        XCTAssertNil(VietnameseCharacters.baseVowel("b"))
    }

    func testVietnameseCharactersMarkForVowel() {
        XCTAssertEqual(VietnameseCharacters.mark(forVowel: "â"), .circumflex)
        XCTAssertEqual(VietnameseCharacters.mark(forVowel: "ă"), .breve)
        XCTAssertEqual(VietnameseCharacters.mark(forVowel: "ơ"), .horn)
        XCTAssertEqual(VietnameseCharacters.mark(forVowel: "ư"), .horn)
        XCTAssertEqual(VietnameseCharacters.mark(forVowel: "a"), .none)
    }

    // MARK: - Tone placement on marked vowels

    func testToneOnOcircumflexInBuon() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "buoonf")
        XCTAssertEqual(engine.currentBuffer, "buồn")
    }

    func testToneOnOhornInCo() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "cowr")
        XCTAssertEqual(engine.currentBuffer, "cở")
    }

    func testToneOnPlainClosingOffglide() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "hauf")
        XCTAssertEqual(engine.currentBuffer, "hàu")
    }

    func testToneOnAyPlacesToneOnA() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "hayx")
        XCTAssertEqual(engine.currentBuffer, "hãy")
    }

    func testToneOnAyCircumflexPlacesToneOnA() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "taayr")
        XCTAssertEqual(engine.currentBuffer, "tẩy")
    }

    func testToneOnUyPlacesToneOnY() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "quys")
        XCTAssertEqual(engine.currentBuffer, "quý")
    }

    // MARK: - W key transforms last vowel

    func testWTransformsLastVowelToHorn() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "Cuiw")
        XCTAssertEqual(engine.currentBuffer, "Cưi")
    }

    func testWTransformsOToOhorn() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "cow")
        XCTAssertEqual(engine.currentBuffer, "cơ")
    }

    func testWTransformsAToAbreve() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "caw")
        XCTAssertEqual(engine.currentBuffer, "că")
    }
}
