@testable import EasyEngineCore
import XCTest

final class AppLogTests: XCTestCase {
    func testCategories_AllHaveNonEmptyRawValues() {
        for category in AppLog.Category.allCases {
            XCTAssertFalse(category.rawValue.isEmpty)
        }
    }

    func testLogger_ReturnsSameSubsystem() {
        let logger = AppLog.logger(.keyboard)
        XCTAssertEqual(AppLog.subsystem, "one.ifelse.easykey")
        _ = logger
    }

    func testLoggingHelpers_DoNotThrow() {
        AppLog.debug(.engine, "debug probe")
        AppLog.info(.settings, "info probe")
        AppLog.notice(.update, "notice probe")
        AppLog.error(.app, "error probe")
    }
}
