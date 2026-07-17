@testable import EasyKey
import XCTest

@MainActor
final class LoginItemControllerTests: XCTestCase {
    func testInitialStatus_IsDisabled() {
        let controller = LoginItemController()
        XCTAssertEqual(controller.status, .disabled)
    }

    func testConfigure_Enabled_UpdatesStatusWithoutCrashing() {
        let controller = LoginItemController()
        controller.configure(enabled: true)
        XCTAssertTrue([.enabled, .unsupported, .failed].contains(controller.status))
    }

    func testConfigure_Disabled_UpdatesStatusWithoutCrashing() {
        let controller = LoginItemController()
        controller.configure(enabled: false)
        XCTAssertTrue([.disabled, .unsupported, .failed].contains(controller.status))
    }

    func testLocalizedTitle_ForEveryStatus() {
        let localization = LocalizationStore.shared
        for status in [
            LoginItemController.Status.disabled,
            .enabled,
            .unsupported,
            .failed,
        ] {
            XCTAssertFalse(status.localizedTitle(using: localization).isEmpty)
            XCTAssertFalse(status.localizedTitle.isEmpty)
        }
    }
}
