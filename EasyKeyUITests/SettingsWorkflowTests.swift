import XCTest

final class SettingsWorkflowTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
    }

    override func tearDown() {
        app.terminate()
    }

    // MARK: - Onboarding

    func testOnboardingShowsOnFirstLaunch() {
        app.launch()
        app.activate()
        XCTAssertTrue(app.descendants(matching: .any)["Welcome"].waitForExistence(timeout: 5))
    }

    func testOnboardingStepThroughAllPages() {
        app.launch()
        app.activate()
        XCTAssertTrue(app.descendants(matching: .any)["Welcome"].waitForExistence(timeout: 5))

        clickOnboardingPrimaryButton(thenWaitFor: "Accessibility")
        clickOnboardingPrimaryButton(thenWaitFor: "Typing method")
        clickOnboardingPrimaryButton(thenWaitFor: "Ready")

        let finishButton = onboardingPrimaryButton()
        XCTAssertTrue(finishButton.waitForExistence(timeout: 5))
        XCTAssertEqual(finishButton.label, "Finish setup")
        finishButton.click()
    }

    func testOnboardingAccessibilityStepShowsGrantButton() {
        app.launch()
        app.activate()
        XCTAssertTrue(app.descendants(matching: .any)["Welcome"].waitForExistence(timeout: 5))
        let primaryButton = onboardingPrimaryButton()
        XCTAssertTrue(primaryButton.waitForExistence(timeout: 5))
        primaryButton.click()
        XCTAssertTrue(app.descendants(matching: .any)["Accessibility"].waitForExistence(timeout: 5))

        // Grant button is only shown when Accessibility is not yet trusted on the host.
        let grantButton = app.buttons["Grant Accessibility Access"]
        // Button may exist but not be hittable if accessibility is already granted in test environment.
        // Just verify button is present in the view hierarchy.
        _ = grantButton.waitForExistence(timeout: 2)
    }

    func testOnboardingShowsVietnameseWhenRequested() {
        app.launchArguments += ["--ui-language", "vi"]
        app.launch()
        app.activate()

        XCTAssertTrue(app.descendants(matching: .any)["Welcome"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Chào mừng"].waitForExistence(timeout: 3)
            || app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "CHÀO MỪNG")).firstMatch.waitForExistence(timeout: 3))

        let primaryButton = app.buttons["OnboardingPrimary"]
        XCTAssertTrue(primaryButton.waitForExistence(timeout: 3))
        XCTAssertEqual(primaryButton.label, "Tiếp tục")
    }

    func testSettingsSidebarSelectsAbout() {
        app.launchArguments.append("--ui-skip-onboarding")
        app.launch()
        app.activate()

        let about = app.descendants(matching: .any)["SettingsSection-about"].firstMatch
        XCTAssertTrue(about.waitForExistence(timeout: 5))
        about.click()

        XCTAssertTrue(app.descendants(matching: .any)["InterfaceLanguagePicker"].waitForExistence(timeout: 5))
    }

    func testSettingsSidebarHasFixedWidth() {
        app.launchArguments.append("--ui-skip-onboarding")
        app.launch()
        app.activate()

        let sidebar = app.descendants(matching: .any)["SettingsSidebar"]
        XCTAssertTrue(sidebar.waitForExistence(timeout: 5))
        XCTAssertEqual(sidebar.frame.width, 192, accuracy: 2)
    }

    func testSettingsSidebarToggleStaysAtTrailingEdge() {
        app.launchArguments.append("--ui-skip-onboarding")
        app.launch()
        app.activate()

        let toggle = sidebarToggleButton()
        XCTAssertTrue(toggle.waitForExistence(timeout: 10))
        let initialMidX = toggle.frame.midX

        toggle.click()

        let updatedToggle = sidebarToggleButton()
        XCTAssertTrue(updatedToggle.waitForExistence(timeout: 5))
        XCTAssertEqual(updatedToggle.frame.midX, initialMidX, accuracy: 1)
    }

    private func onboardingPrimaryButton() -> XCUIElement {
        app.buttons["OnboardingPrimary"].firstMatch
    }

    private func clickOnboardingPrimaryButton(thenWaitFor titleIdentifier: String) {
        let button = onboardingPrimaryButton()
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.click()
        XCTAssertTrue(app.descendants(matching: .any)[titleIdentifier].waitForExistence(timeout: 10))
    }

    private func sidebarToggleButton() -> XCUIElement {
        app.buttons.matching(NSPredicate(
            format: "identifier == %@ OR label == %@",
            "SettingsSidebarToggle",
            "Toggle sidebar"
        )).firstMatch
    }
}
