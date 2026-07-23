import CoreGraphics
@testable import EasyKey
import EasyKeyKit
import XCTest

final class SynthesizePasteIsolationTests: XCTestCase {
    func testSynthesizePaste_EventIsMarkedAsSelfPosted() {
        let source = CGEventSource(stateID: .privateState)
        let vKey: CGKeyCode = 9
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: true) else {
            XCTFail("Failed to create CGEvent")
            return
        }
        KeySynthesizer.markAsSelfPosted(down)

        XCTAssertTrue(
            KeySynthesizer.isSelfPosted(down),
            "Event marked with KeySynthesizer.markAsSelfPosted must be recognized as self-posted"
        )
    }
}
