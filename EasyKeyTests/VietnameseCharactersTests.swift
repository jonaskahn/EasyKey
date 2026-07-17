@testable import EasyEngineCore
import XCTest

final class VietnameseCharactersTests: XCTestCase {
    func testIsVowel_lowercase() {
        for char in "aeiouy" {
            XCTAssertTrue(VietnameseCharacters.isVowel(char), "\(char) should be vowel")
        }
    }

    func testIsVowel_uppercase() {
        for char in "AEIOUY" {
            XCTAssertTrue(VietnameseCharacters.isVowel(char), "\(char) should be vowel")
        }
    }

    func testIsVowel_consonants() {
        for char in "bcdfghjklmnpqrstvwxz" {
            XCTAssertFalse(VietnameseCharacters.isVowel(char), "\(char) should not be vowel")
        }
    }

    func testDWithStroke() {
        XCTAssertEqual(VietnameseCharacters.d(withStroke: true, uppercase: false), "đ")
        XCTAssertEqual(VietnameseCharacters.d(withStroke: true, uppercase: true), "Đ")
    }

    func testDWithoutStroke() {
        XCTAssertEqual(VietnameseCharacters.d(withStroke: false, uppercase: false), "d")
        XCTAssertEqual(VietnameseCharacters.d(withStroke: false, uppercase: true), "D")
    }

    func testBaseVowelUppercase() {
        XCTAssertEqual(VietnameseCharacters.baseVowel("Â"), "a")
        XCTAssertEqual(VietnameseCharacters.baseVowel("Ê"), "e")
        XCTAssertEqual(VietnameseCharacters.baseVowel("Ô"), "o")
        XCTAssertEqual(VietnameseCharacters.baseVowel("Ơ"), "o")
        XCTAssertEqual(VietnameseCharacters.baseVowel("Ư"), "u")
    }

    func testBaseVowelLowercase() {
        XCTAssertEqual(VietnameseCharacters.baseVowel("â"), "a")
        XCTAssertEqual(VietnameseCharacters.baseVowel("ê"), "e")
        XCTAssertEqual(VietnameseCharacters.baseVowel("ô"), "o")
        XCTAssertEqual(VietnameseCharacters.baseVowel("ơ"), "o")
        XCTAssertEqual(VietnameseCharacters.baseVowel("ư"), "u")
        XCTAssertEqual(VietnameseCharacters.baseVowel("ă"), "a")
    }

    func testBaseVowelNil() {
        XCTAssertNil(VietnameseCharacters.baseVowel("b"))
        XCTAssertNil(VietnameseCharacters.baseVowel("d"))
        XCTAssertNil(VietnameseCharacters.baseVowel("đ"))
    }

    func testMarkForVowelAllCases() {
        XCTAssertEqual(VietnameseCharacters.mark(forVowel: "â"), .circumflex)
        XCTAssertEqual(VietnameseCharacters.mark(forVowel: "Â"), .circumflex)

        XCTAssertEqual(VietnameseCharacters.mark(forVowel: "ă"), .breve)
        XCTAssertEqual(VietnameseCharacters.mark(forVowel: "Ă"), .breve)

        XCTAssertEqual(VietnameseCharacters.mark(forVowel: "ơ"), .horn)
        XCTAssertEqual(VietnameseCharacters.mark(forVowel: "ư"), .horn)
        XCTAssertEqual(VietnameseCharacters.mark(forVowel: "Ơ"), .horn)
        XCTAssertEqual(VietnameseCharacters.mark(forVowel: "Ư"), .horn)

        XCTAssertEqual(VietnameseCharacters.mark(forVowel: "a"), .none)
        XCTAssertEqual(VietnameseCharacters.mark(forVowel: "e"), .none)
        XCTAssertEqual(VietnameseCharacters.mark(forVowel: "ê"), .none)
        XCTAssertEqual(VietnameseCharacters.mark(forVowel: "i"), .none)
        XCTAssertEqual(VietnameseCharacters.mark(forVowel: "o"), .none)
        XCTAssertEqual(VietnameseCharacters.mark(forVowel: "ô"), .none)
        XCTAssertEqual(VietnameseCharacters.mark(forVowel: "u"), .none)
        XCTAssertEqual(VietnameseCharacters.mark(forVowel: "y"), .none)
    }

    func testVowelWithAllCombinations() {
        for base in "aeiouy" {
            for mark in DiacriticalMark.allCases where mark != .stroke {
                for tone in Tone.allCases {
                    let lower = VietnameseCharacters.vowel(
                        base: Character(String(base)),
                        mark: mark,
                        tone: tone,
                        uppercase: false
                    )
                    let upper = VietnameseCharacters.vowel(
                        base: Character(String(base)),
                        mark: mark,
                        tone: tone,
                        uppercase: true
                    )
                    if lower == nil || upper == nil {
                        XCTFail("Missing vowel for base=\(base) mark=\(mark) tone=\(tone)")
                    }
                }
            }
        }
    }

    func testVowelWithNilBase() {
        XCTAssertNil(VietnameseCharacters.vowel(base: "b", mark: .none, tone: .none, uppercase: false))
    }

    func testVowelWithStroke() {
        let result = VietnameseCharacters.vowel(base: "a", mark: .stroke, tone: .none, uppercase: false)
        XCTAssertNil(result)
    }

    func testToneMarkKeys() {
        XCTAssertEqual(VietnameseCharacters.toneMarkKeys[.acute], ["s", "S"])
        XCTAssertEqual(VietnameseCharacters.toneMarkKeys[.grave], ["f", "F"])
        XCTAssertEqual(VietnameseCharacters.toneMarkKeys[.hook], ["r", "R"])
        XCTAssertEqual(VietnameseCharacters.toneMarkKeys[.tilde], ["x", "X"])
        XCTAssertEqual(VietnameseCharacters.toneMarkKeys[.dotBelow], ["j", "J"])
    }

    func testToneNumberKeys() {
        XCTAssertEqual(VietnameseCharacters.toneNumberKeys["1"], .acute)
        XCTAssertEqual(VietnameseCharacters.toneNumberKeys["2"], .grave)
        XCTAssertEqual(VietnameseCharacters.toneNumberKeys["3"], .hook)
        XCTAssertEqual(VietnameseCharacters.toneNumberKeys["4"], .tilde)
        XCTAssertEqual(VietnameseCharacters.toneNumberKeys["5"], .dotBelow)
    }

    func testDiacriticNumberKeys() {
        XCTAssertEqual(VietnameseCharacters.diacriticNumberKeys["6"], .circumflex)
        XCTAssertEqual(VietnameseCharacters.diacriticNumberKeys["7"], .horn)
        XCTAssertEqual(VietnameseCharacters.diacriticNumberKeys["8"], .breve)
        XCTAssertEqual(VietnameseCharacters.diacriticNumberKeys["9"], .stroke)
    }

    func testStartConsonantsAreCanonicalVietnameseOnsets() {
        let single = Set([
            "b", "c", "d", "đ", "g", "h", "k", "l", "m", "n", "p", "q", "r", "s", "t", "v", "x",
        ])
        let combined = Set([
            "ch", "gh", "gi", "kh", "ng", "ngh", "nh", "ph", "th", "tr", "qu",
        ])

        XCTAssertEqual(VietnameseCharacters.startConsonants, single.union(combined))
        XCTAssertFalse(VietnameseCharacters.startConsonants.contains("dg"))
        XCTAssertFalse(VietnameseCharacters.startConsonants.contains("dh"))
    }
}
