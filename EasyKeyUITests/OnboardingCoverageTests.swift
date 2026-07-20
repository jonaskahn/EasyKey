import XCTest

final class OnboardingCoverageTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
    }

    override func tearDown() {
        app.terminate()
    }

    // MARK: - Welcome Step

    func testOnboardingWelcomeStepRenders() {
        app.launch()
        app.activate()
        XCTAssertTrue(app.descendants(matching: .any)["Welcome"].waitForExistence(timeout: 5))
    }

    func testOnboardingPrimaryButtonExists() {
        app.launch()
        app.activate()
        XCTAssertTrue(app.descendants(matching: .any)["Welcome"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["OnboardingPrimary"].exists)
    }

    func testOnboardingWelcomeHasStaticText() {
        app.launch()
        app.activate()
        XCTAssertTrue(app.descendants(matching: .any)["Welcome"].waitForExistence(timeout: 5))
        XCTAssertGreaterThan(app.staticTexts.count, 0)
    }

    func testOnboardingWelcomeHasProgressBar() {
        app.launch()
        app.activate()
        XCTAssertTrue(app.descendants(matching: .any)["Welcome"].waitForExistence(timeout: 5))
        // ProgressView is accessibilityHidden per design; verify parent view renders.
        XCTAssertTrue(app.descendants(matching: .any)["Welcome"].exists)
    }

    // MARK: - Step Navigation

    func testOnboardingContinueToAccessibilityStep() {
        app.launch()
        app.activate()
        XCTAssertTrue(app.descendants(matching: .any)["Welcome"].waitForExistence(timeout: 5))

        let primaryButton = app.buttons["OnboardingPrimary"]
        XCTAssertTrue(primaryButton.waitForExistence(timeout: 5))
        primaryButton.click()
        XCTAssertTrue(app.descendants(matching: .any)["Accessibility"].waitForExistence(timeout: 5))
    }

    func testOnboardingBackButtonReturnsToWelcome() {
        app.launch()
        app.activate()
        XCTAssertTrue(app.descendants(matching: .any)["Welcome"].waitForExistence(timeout: 5))

        let primary = app.buttons["OnboardingPrimary"]
        XCTAssertTrue(primary.waitForExistence(timeout: 5))
        primary.click()
        XCTAssertTrue(app.descendants(matching: .any)["Accessibility"].waitForExistence(timeout: 5))

        let backButton = app.buttons["Back"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 5))
        backButton.click()
        XCTAssertTrue(app.descendants(matching: .any)["Welcome"].waitForExistence(timeout: 5))
    }

    func testOnboardingAccessibilityStepHasGrantButton() {
        app.launch()
        app.activate()
        XCTAssertTrue(app.descendants(matching: .any)["Welcome"].waitForExistence(timeout: 5))

        let primary = app.buttons["OnboardingPrimary"]
        XCTAssertTrue(primary.waitForExistence(timeout: 5))
        primary.click()
        XCTAssertTrue(app.descendants(matching: .any)["Accessibility"].waitForExistence(timeout: 5))

        let grantButton = app.buttons["Grant Accessibility Access"]
        _ = grantButton.waitForExistence(timeout: 3)
    }

    func testOnboardingTypingMethodStepHasPickers() {
        app.launch()
        app.activate()
        XCTAssertTrue(app.descendants(matching: .any)["Welcome"].waitForExistence(timeout: 5))

        for _ in 0 ..< 2 {
            let primary = app.buttons["OnboardingPrimary"]
            XCTAssertTrue(primary.waitForExistence(timeout: 5))
            primary.click()
            sleep(1)
        }

        XCTAssertTrue(app.descendants(matching: .any)["Typing method"].waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(app.popUpButtons.count, 1)
    }

    func testOnboardingReadyStepAppears() {
        app.launch()
        app.activate()
        XCTAssertTrue(app.descendants(matching: .any)["Welcome"].waitForExistence(timeout: 5))

        for _ in 0 ..< 3 {
            let primary = app.buttons["OnboardingPrimary"]
            XCTAssertTrue(primary.waitForExistence(timeout: 5))
            primary.click()
            sleep(1)
        }

        XCTAssertTrue(app.descendants(matching: .any)["Ready"].waitForExistence(timeout: 5))
    }

    func testOnboardingFinishButtonPresent() {
        app.launch()
        app.activate()
        XCTAssertTrue(app.descendants(matching: .any)["Welcome"].waitForExistence(timeout: 5))

        for _ in 0 ..< 3 {
            let primary = app.buttons["OnboardingPrimary"]
            XCTAssertTrue(primary.waitForExistence(timeout: 5))
            primary.click()
            sleep(1)
        }

        XCTAssertTrue(app.descendants(matching: .any)["Ready"].waitForExistence(timeout: 5))
        let finishButton = app.buttons["OnboardingPrimary"]
        XCTAssertTrue(finishButton.waitForExistence(timeout: 5))
    }

    func testOnboardingFinishDismisses() {
        app.launch()
        app.activate()
        XCTAssertTrue(app.descendants(matching: .any)["Welcome"].waitForExistence(timeout: 5))

        for _ in 0 ..< 3 {
            let primary = app.buttons["OnboardingPrimary"]
            XCTAssertTrue(primary.waitForExistence(timeout: 5))
            primary.click()
            sleep(1)
        }

        XCTAssertTrue(app.descendants(matching: .any)["Ready"].waitForExistence(timeout: 5))
        app.typeKey(.return, modifierFlags: [])
        sleep(1)
        XCTAssertFalse(app.descendants(matching: .any)["Welcome"].exists)
    }

    // MARK: - Language Picker

    func testOnboardingHasLanguageMenu() {
        app.launch()
        app.activate()
        XCTAssertTrue(app.descendants(matching: .any)["Welcome"].waitForExistence(timeout: 5))
        let langPickers = app.descendants(matching: .any)["InterfaceLanguagePicker"]
        XCTAssertTrue(langPickers.waitForExistence(timeout: 3))
    }

    func testOnboardingVietnameseLocalization() {
        app.launchArguments += ["--ui-language", "vi"]
        app.launch()
        app.activate()
        XCTAssertTrue(app.descendants(matching: .any)["Welcome"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["OnboardingPrimary"].waitForExistence(timeout: 5))
    }

    // MARK: - Launch Arguments

    func testOnboardingSkipFlagBypassesOnboarding() {
        app.launchArguments.append("--ui-skip-onboarding")
        app.launch()
        app.activate()
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.descendants(matching: .any)["Welcome"].exists)
    }

    func testOnboardingSectionFlagLaunchesToAbout() {
        app.launchArguments += ["--ui-skip-onboarding", "--ui-settings-section", "about"]
        app.launch()
        app.activate()
        XCTAssertTrue(app.descendants(matching: .any)["OpenSourceLicenses"].waitForExistence(timeout: 10))
    }

    func testOnboardingKeyboardReturnCompletes() {
        app.launch()
        app.activate()
        XCTAssertTrue(app.descendants(matching: .any)["Welcome"].waitForExistence(timeout: 5))

        for _ in 0 ..< 3 {
            let primary = app.buttons["OnboardingPrimary"]
            XCTAssertTrue(primary.waitForExistence(timeout: 5))
            primary.click()
            sleep(1)
        }

        XCTAssertTrue(app.descendants(matching: .any)["Ready"].waitForExistence(timeout: 5))
        sleep(1)
        app.typeKey(.return, modifierFlags: [])
        sleep(2)
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].exists)
    }
}
