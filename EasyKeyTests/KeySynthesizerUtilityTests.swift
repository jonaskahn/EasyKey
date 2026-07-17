@testable import EasyKeyKit
import XCTest

final class KeySynthesizerUtilityTests: XCTestCase {
    func testTrackEncodedUnits() {
        let synthesizer = KeySynthesizer()
        synthesizer.trackEncodedUnits(["a", "b", "c"])
        XCTAssertEqual(synthesizer.encodedUnitCount, 3)
    }

    func testTrackEncodedUnitsMultiByte() {
        let synthesizer = KeySynthesizer()
        synthesizer.trackEncodedUnits(["việt", "nam"])
        XCTAssertEqual(synthesizer.encodedUnitCount, 2)
    }

    func testTrackEncodedUnitsEmpty() {
        let synthesizer = KeySynthesizer()
        synthesizer.trackEncodedUnits([])
        XCTAssertEqual(synthesizer.encodedUnitCount, 0)
    }

    func testMarkPendingEmptyCharacter() {
        let synthesizer = KeySynthesizer()
        XCTAssertFalse(synthesizer.hasPendingEmptyCharacter)
        synthesizer.markPendingEmptyCharacter()
        XCTAssertTrue(synthesizer.hasPendingEmptyCharacter)
    }

    func testResetEncodedUnits() {
        let synthesizer = KeySynthesizer()
        synthesizer.trackEncodedUnits(["a", "b"])
        synthesizer.markPendingEmptyCharacter()
        XCTAssertEqual(synthesizer.encodedUnitCount, 2)
        XCTAssertTrue(synthesizer.hasPendingEmptyCharacter)

        synthesizer.resetEncodedUnits()
        XCTAssertEqual(synthesizer.encodedUnitCount, 0)
        XCTAssertFalse(synthesizer.hasPendingEmptyCharacter)
    }

    func testPrepareDeleteNoPending() {
        let synthesizer = KeySynthesizer()
        synthesizer.trackEncodedUnits(["a", "b", "c"])

        let physical = synthesizer.prepareDelete(deleteCount: 1)
        XCTAssertEqual(physical, 1)
        XCTAssertEqual(synthesizer.encodedUnitCount, 2)
    }

    func testPrepareDeleteAll() {
        let synthesizer = KeySynthesizer()
        synthesizer.trackEncodedUnits(["a", "b", "c"])

        let physical = synthesizer.prepareDelete(deleteCount: 3)
        XCTAssertEqual(physical, 3)
        XCTAssertEqual(synthesizer.encodedUnitCount, 0)
    }

    func testPrepareDeleteMoreThanAvailable() {
        let synthesizer = KeySynthesizer()
        synthesizer.trackEncodedUnits(["a"])

        let physical = synthesizer.prepareDelete(deleteCount: 5)
        XCTAssertEqual(physical, 1)
        XCTAssertEqual(synthesizer.encodedUnitCount, 0)
    }

    func testPrepareDeleteZero() {
        let synthesizer = KeySynthesizer()
        synthesizer.trackEncodedUnits(["a"])

        let physical = synthesizer.prepareDelete(deleteCount: 0)
        XCTAssertEqual(physical, 0)
        XCTAssertEqual(synthesizer.encodedUnitCount, 1)
    }

    func testMultipleOperations() {
        let synthesizer = KeySynthesizer()
        synthesizer.trackEncodedUnits(["h", "o"])
        synthesizer.markPendingEmptyCharacter()

        let physical = synthesizer.prepareDelete(deleteCount: 2)
        XCTAssertEqual(physical, 3)
        XCTAssertEqual(synthesizer.encodedUnitCount, 0)
        XCTAssertFalse(synthesizer.hasPendingEmptyCharacter)

        synthesizer.trackEncodedUnits(["n", "e", "w"])
        XCTAssertEqual(synthesizer.encodedUnitCount, 3)

        synthesizer.resetEncodedUnits()
        XCTAssertEqual(synthesizer.encodedUnitCount, 0)
    }
}
