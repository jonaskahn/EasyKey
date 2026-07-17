import XCTest

final class EasyKeyUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
    }

    override func tearDown() {
        app.terminate()
    }

    func testAppLaunches() {
        app.launch()
        XCTAssertTrue(app.exists)
    }
}
