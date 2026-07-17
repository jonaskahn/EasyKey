@testable import EasyEngineCore
import XCTest

final class SimpleTelexRulesTests: XCTestCase {
    func testToneKeys() {
        XCTAssertEqual(SimpleTelexRules.intent(forCharacter: "s", previousChar: "a"), .addTone(.acute))
        XCTAssertEqual(SimpleTelexRules.intent(forCharacter: "f", previousChar: "a"), .addTone(.grave))
        XCTAssertEqual(SimpleTelexRules.intent(forCharacter: "r", previousChar: "a"), .addTone(.hook))
        XCTAssertEqual(SimpleTelexRules.intent(forCharacter: "x", previousChar: "a"), .addTone(.tilde))
        XCTAssertEqual(SimpleTelexRules.intent(forCharacter: "j", previousChar: "a"), .addTone(.dotBelow))
    }

    func testUppercaseToneKeys() {
        XCTAssertEqual(SimpleTelexRules.intent(forCharacter: "S", previousChar: "a"), .addTone(.acute))
        XCTAssertEqual(SimpleTelexRules.intent(forCharacter: "F", previousChar: "a"), .addTone(.grave))
    }

    func testDStroke() {
        XCTAssertEqual(SimpleTelexRules.intent(forCharacter: "d", previousChar: "d"), .transformDStroke)
        XCTAssertEqual(SimpleTelexRules.intent(forCharacter: "D", previousChar: "d"), .transformDStroke)
    }

    func testDStrokeNotDoubleD() {
        let result = SimpleTelexRules.intent(forCharacter: "d", previousChar: "a")
        if case .passThrough = result {} else {
            XCTAssertEqual(result, .passThrough("d"))
        }
    }

    func testPassThrough() {
        let result = SimpleTelexRules.intent(forCharacter: "a", previousChar: "a")
        if case .passThrough = result {} else {
            XCTFail("Expected passThrough")
        }
    }

    func testPassThroughConsonants() {
        let result = SimpleTelexRules.intent(forCharacter: "b", previousChar: nil)
        if case .passThrough = result {} else {
            XCTFail("Expected passThrough")
        }
    }

    func testNilPreviousChar() {
        let result = SimpleTelexRules.intent(forCharacter: "d", previousChar: nil)
        if case .passThrough = result {} else {
            XCTFail("Expected passThrough")
        }
    }
}
