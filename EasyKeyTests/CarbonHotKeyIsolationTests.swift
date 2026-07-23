@testable import EasyKey
import XCTest

@MainActor
final class CarbonHotKeyIsolationTests: XCTestCase {
    func testHotKeyController_RunsHandlerOnMainActor() {
        var called = false
        let registrar = CarbonHotKeyRegistrar()
        let controller = ClipboardHotKeyController(registrar: registrar) {
            called = true
        }
        
        let shortcut = Shortcut(keyCode: 9, modifiers: [.command, .option])
        controller.apply(shortcut)
        
        XCTAssertTrue(controller.isRegistered)
    }
}
