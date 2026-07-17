@testable import EasyEngineCore
import XCTest

final class VietnameseEncodingTests: XCTestCase {
    func testTCVN3Encoding() {
        let encoder = TCVN3Encoding()
        let atoms = [BufferAtom(base: "v"), BufferAtom(base: "i")]
        let result = encoder.encode(atoms: atoms, tone: .acute, toneTargetIndex: 1)
        XCTAssertFalse(result.isEmpty)
        XCTAssertNotEqual(result, "ví")
    }

    func testVNIWindowsEncoding() {
        let encoder = VNIWindowsEncoding()
        let atoms = [BufferAtom(base: "v"), BufferAtom(base: "i")]
        let result = encoder.encode(atoms: atoms, tone: .acute, toneTargetIndex: 1)
        XCTAssertFalse(result.isEmpty)
    }

    func testUnicodeCombiningEncoding() throws {
        let encoder = UnicodeCombiningEncoding()
        let atoms = [BufferAtom(base: "v"), BufferAtom(base: "i")]
        let result = encoder.encode(atoms: atoms, tone: .acute, toneTargetIndex: 1)
        let scalars = result.unicodeScalars
        XCTAssertTrue(try scalars.contains(XCTUnwrap(Unicode.Scalar(0x0301))))
    }

    func testUnicodeCombiningEncodingDStroke() {
        let encoder = UnicodeCombiningEncoding()
        let atoms = [BufferAtom(base: "d", mark: .stroke)]
        let result = encoder.encode(atoms: atoms, tone: .none, toneTargetIndex: nil)
        XCTAssertEqual(result, "đ")
    }

    func testUnicodeCombiningEncodingMarkOnly() throws {
        let encoder = UnicodeCombiningEncoding()
        let atoms = [BufferAtom(base: "a", mark: .circumflex)]
        let result = encoder.encode(atoms: atoms, tone: .none, toneTargetIndex: nil)
        let scalars = result.unicodeScalars
        XCTAssertTrue(try scalars.contains(XCTUnwrap(Unicode.Scalar(0x0302))))
    }

    func testUnicodeCombiningEncodingToneAndMark() throws {
        let encoder = UnicodeCombiningEncoding()
        let atoms = [BufferAtom(base: "a", mark: .circumflex)]
        let result = encoder.encode(atoms: atoms, tone: .acute, toneTargetIndex: 0)
        let scalars = result.unicodeScalars
        XCTAssertTrue(try scalars.contains(XCTUnwrap(Unicode.Scalar(0x0302))))
        XCTAssertTrue(try scalars.contains(XCTUnwrap(Unicode.Scalar(0x0301))))
    }

    func testEncodingFactory() {
        XCTAssertTrue(EncodingFactory.encoding(for: .unicode) is UnicodePrecomposedEncoding)
        XCTAssertTrue(EncodingFactory.encoding(for: .unicodeCombining) is UnicodeCombiningEncoding)
        XCTAssertTrue(EncodingFactory.encoding(for: .tcvn3) is TCVN3Encoding)
        XCTAssertTrue(EncodingFactory.encoding(for: .vniWindows) is VNIWindowsEncoding)
        XCTAssertTrue(EncodingFactory.encoding(for: .cp1258) is CP1258Encoding)
    }

    func testCP1258EncodingUsesCombining() throws {
        let encoder = EncodingFactory.encoding(for: .cp1258)
        let atoms = [BufferAtom(base: "v"), BufferAtom(base: "i")]
        let result = encoder.encode(atoms: atoms, tone: .acute, toneTargetIndex: 1)
        let scalars = result.unicodeScalars
        XCTAssertTrue(try scalars.contains(XCTUnwrap(Unicode.Scalar(0x0301))))
    }

    func testUnicodePrecomposedUppercaseVowel() {
        let encoder = UnicodePrecomposedEncoding()
        let atoms = [BufferAtom(base: "a", uppercase: true)]
        let result = encoder.encode(atoms: atoms, tone: .acute, toneTargetIndex: 0)
        XCTAssertEqual(result, "Á")
    }

    func testUnicodePrecomposedDStroke() {
        let encoder = UnicodePrecomposedEncoding()
        let atoms = [BufferAtom(base: "d", mark: .stroke)]
        let result = encoder.encode(atoms: atoms, tone: .none, toneTargetIndex: nil)
        XCTAssertEqual(result, "đ")
    }

    func testUnicodePrecomposedDStrokeUppercase() {
        let encoder = UnicodePrecomposedEncoding()
        let atoms = [BufferAtom(base: "D", mark: .stroke, uppercase: true)]
        let result = encoder.encode(atoms: atoms, tone: .none, toneTargetIndex: nil)
        XCTAssertEqual(result, "Đ")
    }
}
