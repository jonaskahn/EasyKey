@testable import EasyEngineCore
import XCTest

final class VietnameseEngineTonePlacementTests: XCTestCase {
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

    func testSimpleTelexTonesOnly() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(inputMethod: .simpleTelex))
        typeKeys(&engine, "taif")
        XCTAssertEqual(engine.currentBuffer, "tài")
    }

    func testSimpleTelexKeepsPairDiacritics() {
        var engine = VietnameseEngine(configuration: EngineConfiguration(inputMethod: .simpleTelex))
        typeKeys(&engine, "aa")
        XCTAssertEqual(engine.currentBuffer, "â")
    }

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
        XCTAssertEqual(result, .passThrough)
        XCTAssertEqual(engine.currentBuffer, "")
    }

    func testControlModifierOnEmptyBufferPasses() {
        var engine = VietnameseEngine()
        let result = engine.process(event: KeyEvent(kind: .character("a"), control: true))
        XCTAssertEqual(result.disposition, .pass)
    }

    func testUnicodeCombiningEncoding() throws {
        var engine = VietnameseEngine(configuration: EngineConfiguration(outputEncoding: .cp1258))
        typeKeys(&engine, "vis")
        let buffer = engine.currentBuffer
        XCTAssertTrue(try buffer.unicodeScalars.contains(XCTUnwrap(Unicode.Scalar(0x0301))))
    }

    func testVietnameseCharactersMarkForVowel() {
        XCTAssertEqual(VietnameseCharacters.mark(forVowel: "â"), .circumflex)
        XCTAssertEqual(VietnameseCharacters.mark(forVowel: "ă"), .breve)
        XCTAssertEqual(VietnameseCharacters.mark(forVowel: "ơ"), .horn)
        XCTAssertEqual(VietnameseCharacters.mark(forVowel: "ư"), .horn)
        XCTAssertEqual(VietnameseCharacters.mark(forVowel: "a"), .none)
    }

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

    func testVerifiedSpecificationExamples() {
        let examples: [(String, String)] = [
            ("vieejt", "việt"),
            ("vietj", "việt"),
            ("vieetj", "việt"),
            ("dduwowcj", "được"),
            ("dduocwj", "được"),
            ("nguwowif", "người"),
            ("nguoiwf", "người"),
            ("truwowngf", "trường"),
            ("truongwf", "trường"),
            ("Nguyeenx", "Nguyễn"),
            ("Nguyexn", "Nguyễn"),
            ("khuyeens", "khuyến"),
            ("khuyru", "khuỷu"),
            ("ngoawnf", "ngoằn"),
            ("cuar", "của"),
            ("mias", "mía"),
            ("quar", "quả"),
            ("gif", "gì"),
            ("xooong", "xoong"),
            ("cana", "cân"),
            ("ddeem", "đêm"),
        ]

        for (input, expected) in examples {
            var engine = VietnameseEngine()
            typeKeys(&engine, input)
            XCTAssertEqual(engine.currentBuffer, expected, "input: \(input)")
        }
    }

    func testOldAndNewToneStylesOnlyDivergeForOpenOAOEUY() {
        let examples: [(String, String, String)] = [
            ("hoaf", "hòa", "hoà"),
            ("khoer", "khỏe", "khoẻ"),
            ("thuyr", "thủy", "thuỷ"),
        ]

        for (input, oldExpected, newExpected) in examples {
            var oldEngine = VietnameseEngine(configuration: EngineConfiguration(toneStyle: .old))
            typeKeys(&oldEngine, input)
            XCTAssertEqual(oldEngine.currentBuffer, oldExpected, "old input: \(input)")

            var newEngine = VietnameseEngine(configuration: EngineConfiguration(toneStyle: .new))
            typeKeys(&newEngine, input)
            XCTAssertEqual(newEngine.currentBuffer, newExpected, "new input: \(input)")
        }

        for input in ["hoanf", "suyts", "ngoays"] {
            var oldEngine = VietnameseEngine(configuration: EngineConfiguration(toneStyle: .old))
            var newEngine = VietnameseEngine(configuration: EngineConfiguration(toneStyle: .new))
            typeKeys(&oldEngine, input)
            typeKeys(&newEngine, input)
            XCTAssertEqual(oldEngine.currentBuffer, newEngine.currentBuffer, "input: \(input)")
        }
    }

    func testSimpleTelexDifferenceIsStandaloneWAndBracketsOnly() {
        for input in ["caan", "trangw", "ddeem", "nhoo", "mow", "tuw", "ddau", "uowj"] {
            var full = VietnameseEngine()
            var simple = VietnameseEngine(configuration: EngineConfiguration(inputMethod: .simpleTelex))
            typeKeys(&full, input)
            typeKeys(&simple, input)
            XCTAssertEqual(full.currentBuffer, simple.currentBuffer, "input: \(input)")
        }

        var fullW = VietnameseEngine()
        var simpleW = VietnameseEngine(configuration: EngineConfiguration(inputMethod: .simpleTelex))
        typeKeys(&fullW, "tw")
        typeKeys(&simpleW, "tw")
        XCTAssertEqual(fullW.currentBuffer, "tư")
        XCTAssertEqual(simpleW.currentBuffer, "tw")
    }

    func testLegalUOExceptionsRemainUPlainOHorn() {
        let examples: [(String, String)] = [
            ("thuowr", "thuở"),
            ("quow", "quơ"),
            ("huow", "huơ"),
            ("khuow", "khuơ"),
        ]

        for (input, expected) in examples {
            var engine = VietnameseEngine()
            typeKeys(&engine, input)
            XCTAssertEqual(engine.currentBuffer, expected, "input: \(input)")
        }
    }

    func testCheckedFinalRejectsInvalidToneKey() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "tacr")
        XCTAssertEqual(engine.currentBuffer, "tacr")

        var kFinal = VietnameseEngine()
        typeKeys(&kFinal, "takr")
        XCTAssertEqual(kFinal.currentBuffer, "takr")

        var valid = VietnameseEngine()
        typeKeys(&valid, "tacs")
        XCTAssertEqual(valid.currentBuffer, "tác")
    }

    func testCheckedFinalTypedAfterInvalidToneAutoRestoresRawWord() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "tarc")
        let output = engine.process(event: KeyEvent(kind: .space))
        XCTAssertEqual(output.edits, [.replaceBackward(deleteCount: 3, insert: "tarc"), .insert(" ")])
    }

    func testZRemovesCurrentTone() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "tasz")
        XCTAssertEqual(engine.currentBuffer, "ta")
    }

    func testRestoreRawKeysKeepsFollowingInputLiteral() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "fix")
        let output = engine.restoreRawKeys()
        XCTAssertEqual(output.disposition, .suppress)
        XCTAssertEqual(engine.currentBuffer, "fix")
        typeKeys(&engine, "ed")
        XCTAssertEqual(engine.currentBuffer, "fixed")
    }

    func testAutoRestoreAtBoundaryUsesRawKeystrokesForInvalidWord() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "fix")
        let deleteCount = engine.currentBuffer.count
        let output = engine.process(event: KeyEvent(kind: .space))
        XCTAssertEqual(
            output.edits,
            [.replaceBackward(deleteCount: deleteCount, insert: "fix"), .insert(" ")]
        )
    }

    func testStandaloneGiWordRemainsComposedAtBoundary() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "gif")
        let output = engine.process(event: KeyEvent(kind: .space))
        XCTAssertEqual(output.edits, [.replaceBackward(deleteCount: 2, insert: "gì"), .insert(" ")])
    }

    func testValidVietnameseWordIsNotAutoRestoredAtBoundary() {
        var engine = VietnameseEngine()
        typeKeys(&engine, "vieetj")
        let output = engine.process(event: KeyEvent(kind: .space))
        XCTAssertEqual(output.edits, [.replaceBackward(deleteCount: 4, insert: "việt"), .insert(" ")])
    }
}
