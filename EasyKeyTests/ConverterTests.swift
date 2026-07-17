@testable import EasyEngineCore
import XCTest

final class ConverterTests: XCTestCase {
    func testRoundTripAcrossEveryEncodingPair() {
        let fixture = "Việt Nam: ă â ê ô ơ ư đ"
        for source in EncodingTable.allCases {
            let sourceText = Converter.preview(
                input: fixture,
                configuration: ConverterConfiguration(sourceEncoding: .unicode, destinationEncoding: source)
            )
            for destination in EncodingTable.allCases {
                let converted = Converter.preview(
                    input: sourceText,
                    configuration: ConverterConfiguration(sourceEncoding: source, destinationEncoding: destination)
                )
                let roundTrip = Converter.preview(
                    input: converted,
                    configuration: ConverterConfiguration(sourceEncoding: destination, destinationEncoding: .unicode)
                )
                XCTAssertEqual(roundTrip, fixture, "\(source) -> \(destination)")
            }
        }
    }

    func testTransformsPreserveUnrecognizedText() {
        let config = ConverterConfiguration(
            transforms: [.removeMarks, .capitalizeSentences]
        )
        XCTAssertEqual(Converter.preview(input: "xin chào. thế giới! x\u{0301}", configuration: config), "Xin chao. The gioi! X\u{0301}")
    }

    func testClipboardConversionKeepsHTMLData() {
        let html = Data("<b>việt</b>".utf8)
        let clipboard = TestClipboard(plainText: "việt", html: html)
        Converter.convertClipboard(clipboard, configuration: ConverterConfiguration(transforms: [.allCaps]))

        XCTAssertEqual(clipboard.plainText, "VIỆT")
        XCTAssertEqual(clipboard.html, html)
    }
}

private final class TestClipboard: ConverterClipboard {
    var plainText: String?
    var html: Data?

    init(plainText: String?, html: Data?) {
        self.plainText = plainText
        self.html = html
    }
}
