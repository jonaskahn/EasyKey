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

        XCTAssertNotEqual(
            down.getIntegerValueField(.eventSourceUserData),
            0,
            "Event marked with KeySynthesizer.markAsSelfPosted must carry the self-posted marker"
        )
        XCTAssertFalse(
            KeySynthesizer.isSelfPosted(down),
            "isSelfPosted additionally requires a private event source, which the system only attributes to events actually posted to a tap"
        )
    }
}
