@testable import EasyEngineCore
import XCTest

final class ConverterEdgeCaseTests: XCTestCase {
    func testCapitalizeWords() {
        let config = ConverterConfiguration(transforms: [.capitalizeWords])
        let result = Converter.preview(input: "xin chào thế giới", configuration: config)
        XCTAssertEqual(result, "Xin Chào Thế Giới")
    }

    func testCapitalizeWordsSingleWord() {
        let config = ConverterConfiguration(transforms: [.capitalizeWords])
        let result = Converter.preview(input: "xin", configuration: config)
        XCTAssertEqual(result, "Xin")
    }

    func testCapitalizeWordsWithNumbers() {
        let config = ConverterConfiguration(transforms: [.capitalizeWords])
        let result = Converter.preview(input: "abc 123 xyz", configuration: config)
        XCTAssertEqual(result, "Abc 123 Xyz")
    }

    func testCapitalizeSentences() {
        let config = ConverterConfiguration(transforms: [.capitalizeSentences])
        let result = Converter.preview(input: "xin chào. thế giới! việt nam", configuration: config)
        XCTAssertEqual(result, "Xin chào. Thế giới! Việt nam")
    }

    func testCapitalizeSentencesSingleSentence() {
        let config = ConverterConfiguration(transforms: [.capitalizeSentences])
        let result = Converter.preview(input: "xin chào", configuration: config)
        XCTAssertEqual(result, "Xin chào")
    }

    func testRemoveMarks() {
        let config = ConverterConfiguration(transforms: [.removeMarks])
        let result = Converter.preview(input: "việt nam", configuration: config)
        XCTAssertEqual(result, "viet nam")
    }

    func testAllCaps() {
        let config = ConverterConfiguration(transforms: [.allCaps])
        let result = Converter.preview(input: "xin chào", configuration: config)
        XCTAssertEqual(result, "XIN CHÀO")
    }

    func testLowercase() {
        let config = ConverterConfiguration(transforms: [.lowercase])
        let result = Converter.preview(input: "XIN CHÀO", configuration: config)
        XCTAssertEqual(result, "xin chào")
    }

    func testMultipleTransforms() {
        let config = ConverterConfiguration(transforms: [.removeMarks, .allCaps])
        let result = Converter.preview(input: "việt nam", configuration: config)
        XCTAssertEqual(result, "VIET NAM")
    }

    func testAllCapsThenLowercase() {
        let config = ConverterConfiguration(transforms: [.allCaps, .lowercase])
        let result = Converter.preview(input: "Xin Chào", configuration: config)
        XCTAssertEqual(result, "xin chào")
    }

    func testAllTransforms() {
        let config = ConverterConfiguration(transforms: Set(ConverterTransform.allCases))
        let result = Converter.preview(input: "xin chào. thế giới", configuration: config)
        XCTAssertEqual(result, "Xin Chao. The Gioi")
    }

    func testCapitalizeSentencesWithNewline() {
        let config = ConverterConfiguration(transforms: [.capitalizeSentences])
        let result = Converter.preview(input: "line one\nline two", configuration: config)
        XCTAssertEqual(result, "Line one\nline two")
    }

    func testCapitalizeWordsWithHyphen() {
        let config = ConverterConfiguration(transforms: [.capitalizeWords])
        let result = Converter.preview(input: "xin-chào", configuration: config)
        XCTAssertEqual(result, "Xin-Chào")
    }

    func testEncodingCodecEncodeTCVN3() {
        let result = EncodingCodec.encode("việt nam", as: .tcvn3)
        XCTAssertFalse(result.isEmpty)
    }

    func testEncodingCodecEncodeVNIWindows() {
        let result = EncodingCodec.encode("việt nam", as: .vniWindows)
        XCTAssertFalse(result.isEmpty)
    }

    func testEncodingCodecRoundTripTCVN3() {
        let original = "việt nam đất nước"
        let encoded = EncodingCodec.encode(original, as: .tcvn3)
        let decoded = EncodingCodec.decode(encoded, from: .tcvn3)
        XCTAssertEqual(decoded, original)
    }

    func testEncodingCodecRoundTripVNIWindows() {
        let original = "việt nam"
        let encoded = EncodingCodec.encode(original, as: .vniWindows)
        let decoded = EncodingCodec.decode(encoded, from: .vniWindows)
        XCTAssertEqual(decoded, original)
    }

    func testRemoveMarksDecomposedCharacters() {
        let result = EncodingCodec.removeVietnameseMarks(from: "việt nam")
        XCTAssertEqual(result, "viet nam")
    }

    func testRemoveMarksDStroke() {
        let result = EncodingCodec.removeVietnameseMarks(from: "đường")
        XCTAssertEqual(result, "duong")
    }

    func testRemoveMarksNonVietnamese() {
        let result = EncodingCodec.removeVietnameseMarks(from: "hello")
        XCTAssertEqual(result, "hello")
    }
}
