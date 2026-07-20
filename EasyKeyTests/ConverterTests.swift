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
}
