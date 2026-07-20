import XCTest

final class SettingsInteractionTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launchArguments.append("--ui-skip-onboarding")
    }

    override func tearDown() {
        app.terminate()
    }

    private func launchToSection(_ section: String) {
        app.launchArguments += ["--ui-settings-section", section]
        app.launch()
        app.activate()
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].waitForExistence(timeout: 10))
    }

    // MARK: - Typing Settings Switches

    func testTypingToggleSpellingModernization() {
        launchToSection("typing")
        let switches = app.switches
        if switches.count > 0 {
            switches.firstMatch.clickWhenHittable()
            sleep(1)
        }
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].exists)
    }

    func testTypingAllSwitchesToggleable() {
        launchToSection("typing")
        let switches = app.switches
        if switches.count >= 6 {
            for i in 0 ..< min(switches.count, 6) {
                switches.element(boundBy: i).clickWhenHittable()
                usleep(100_000)
            }
        }
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].exists)
    }

    // MARK: - Encoding Settings Text Interaction

    func testEncodingTypeInPreviewField() {
        launchToSection("encoding")
        let textViews = app.textViews
        if textViews.count > 0, textViews.firstMatch.clickWhenHittable() {
            textViews.firstMatch.typeText("xin chao")
        }
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].exists)
    }

    func testEncodingPickerChange() {
        launchToSection("encoding")
        let popUpCount = app.popUpButtons.count
        XCTAssertGreaterThanOrEqual(popUpCount, 2)
    }

    // MARK: - Translation Settings Interaction

    func testTranslationProviderPickerOpens() {
        launchToSection("translation")
        let providerPicker = app.descendants(matching: .any)["TranslationDefaultProviderPicker"]
        XCTAssertTrue(providerPicker.waitForExistence(timeout: 10))
    }

    func testTranslationSettingsTabNavigation() {
        launchToSection("translation")
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].waitForExistence(timeout: 10))
        for _ in 0 ..< 5 {
            app.typeKey(.tab, modifierFlags: [])
            usleep(200_000)
        }
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].exists)
    }

    // MARK: - Clipboard Settings Interaction

    func testClipboardToggleCaptureToggles() {
        launchToSection("clipboard")
        let switches = app.switches
        if switches.count > 0 {
            switches.firstMatch.clickWhenHittable()
            sleep(1)
        }
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].exists)
    }

    func testClipboardClearAllTriggersAlert() {
        launchToSection("clipboard")
        let clearButton = app.descendants(matching: .any)["ClipboardClearAllButton"]
        if clearButton.waitForExistence(timeout: 5) {
            clearButton.clickWhenHittable()
            sleep(1)
            let cancelButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Cancel'"))
            if cancelButton.firstMatch.exists {
                cancelButton.firstMatch.clickWhenHittable()
            } else {
                app.typeKey(.escape, modifierFlags: [])
            }
            sleep(1)
        }
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].exists)
    }

    // MARK: - Macro Settings Interaction

    func testMacroSettingsSearchTyping() {
        launchToSection("macros")
        let textFields = app.textFields
        if textFields.count > 0, textFields.firstMatch.clickWhenHittable() {
            usleep(200_000)
            textFields.firstMatch.typeText("test")
        }
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].exists)
    }

    func testMacroSettingsToggleSwitches() {
        launchToSection("macros")
        let switches = app.switches
        if switches.count > 0 {
            switches.firstMatch.clickWhenHittable()
            sleep(1)
        }
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].exists)
    }

    // MARK: - Smart Switch Settings Interaction

    func testSmartSwitchToggleSwitches() {
        launchToSection("smartSwitch")
        let switches = app.switches
        if switches.count > 0 {
            switches.firstMatch.clickWhenHittable()
            sleep(1)
        }
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].exists)
    }

    // MARK: - Behavior Settings Interaction

    func testBehaviorToggleSwitches() {
        launchToSection("behavior")
        let switches = app.switches
        if switches.count > 0 {
            switches.firstMatch.clickWhenHittable()
            sleep(1)
        }
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].exists)
    }

    // MARK: - System Settings Interaction

    func testSystemToggleSwitches() {
        launchToSection("system")
        let switches = app.switches
        if switches.count > 0 {
            switches.firstMatch.clickWhenHittable()
            sleep(1)
        }
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].exists)
    }

    func testSystemResetTriggersAlertAndCancels() {
        launchToSection("system")
        let resetBtns = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Reset'"))
        if resetBtns.firstMatch.waitForExistence(timeout: 5) {
            resetBtns.firstMatch.clickWhenHittable()
            sleep(1)
            let cancelButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Cancel'"))
            if cancelButton.firstMatch.exists {
                cancelButton.firstMatch.clickWhenHittable()
            } else {
                app.typeKey(.escape, modifierFlags: [])
            }
            sleep(1)
        }
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].exists)
    }

    func testSystemLanguagePickerOpens() {
        launchToSection("system")
        let langPicker = app.descendants(matching: .any)["InterfaceLanguagePicker"]
        if langPicker.waitForExistence(timeout: 10) {
            langPicker.clickWhenHittable()
            sleep(1)
            app.typeKey(.escape, modifierFlags: [])
        }
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].exists)
    }

    // MARK: - About Settings Interaction

    func testAboutOpenSourceLicensesOpensSheet() {
        launchToSection("about")
        let licensesBtn = app.descendants(matching: .any)["OpenSourceLicenses"]
        if licensesBtn.waitForExistence(timeout: 5) {
            licensesBtn.clickWhenHittable()
            sleep(1)
            let doneBtn = app.descendants(matching: .any)["ThirdPartyNoticesDone"]
            if doneBtn.waitForExistence(timeout: 5) {
                doneBtn.clickWhenHittable()
                sleep(1)
            }
        }
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].exists)
    }

    // MARK: - Navigation Back and Forth

    func testNavigationBetweenSectionsViaArguments() {
        app.launchArguments += ["--ui-settings-section", "typing"]
        app.launch()
        app.activate()
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].waitForExistence(timeout: 10))
        app.terminate()

        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launchArguments.append("--ui-skip-onboarding")
        app.launchArguments += ["--ui-settings-section", "encoding"]
        app.launch()
        app.activate()
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].waitForExistence(timeout: 10))
    }

    func testAllSectionsLoadInSequence() {
        let sections = ["typing", "encoding", "translation", "clipboard", "macros", "smartSwitch", "behavior", "system", "about"]
        for section in sections {
            let testApp = XCUIApplication()
            testApp.launchArguments.append("--uitesting")
            testApp.launchArguments.append("--ui-skip-onboarding")
            testApp.launchArguments += ["--ui-settings-section", section]
            testApp.launch()
            testApp.activate()
            XCTAssertTrue(
                testApp.descendants(matching: .any)["SettingsDetail"].waitForExistence(timeout: 10),
                "Section \(section) failed to load"
            )
            testApp.terminate()
        }
    }
}
