import EasyEngineCore
import XCTest

final class EasyKeySettingsDeltaTests: XCTestCase {
    func testDelta_IdenticalSettings_HasNoChanges() {
        let s1 = EasyKeySettings()
        let s2 = EasyKeySettings()
        let delta = SettingsDelta.delta(from: s1, to: s2)
        XCTAssertFalse(delta.hasAnyChange)
    }

    func testDelta_SystemDockIconChange_SetsOnlySystemChanged() {
        var s1 = EasyKeySettings()
        var s2 = EasyKeySettings()
        s2.system.showDockIcon = true

        let delta = SettingsDelta.delta(from: s1, to: s2)
        XCTAssertTrue(delta.hasAnyChange)
        XCTAssertTrue(delta.systemChanged)
        XCTAssertFalse(delta.inputChanged)
        XCTAssertFalse(delta.typingChanged)
        XCTAssertFalse(delta.compatibilityChanged)
        XCTAssertFalse(delta.clipboardChanged)
    }
}
