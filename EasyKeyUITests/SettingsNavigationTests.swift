import XCTest

final class SettingsNavigationTests: XCTestCase {
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

    private func launchApp() {
        app.launch()
        app.activate()
        app.ensureKeyWindow()
    }

    // MARK: - Sidebar Rendering

    func testSidebarIsPresent() {
        launchApp()
        XCTAssertTrue(app.descendants(matching: .any)["SettingsSidebar"].waitForExistence(timeout: 10))
    }

    func testSidebarHasFixedWidth() {
        launchApp()
        let sidebar = app.descendants(matching: .any)["SettingsSidebar"]
        XCTAssertTrue(sidebar.waitForExistence(timeout: 10))
        XCTAssertEqual(sidebar.frame.width, 192, accuracy: 2)
    }

    func testSidebarCanStartHidden() {
        app.launchArguments += ["--ui-sidebar-hidden"]
        launchApp()
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.descendants(matching: .any)["SettingsSidebar"].exists)
    }

    func testSidebarToggleHidesAndShows() {
        launchApp()
        XCTAssertTrue(app.descendants(matching: .any)["SettingsSidebar"].waitForExistence(timeout: 10))

        let toggle = app.descendants(matching: .any)["SettingsSidebarToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 10))

        toggle.clickWhenHittable()
        sleep(1)
        XCTAssertFalse(app.descendants(matching: .any)["SettingsSidebar"].exists)

        toggle.clickWhenHittable()
        sleep(1)
        XCTAssertTrue(app.descendants(matching: .any)["SettingsSidebar"].waitForExistence(timeout: 5))
    }

    // MARK: - Section Navigation via Launch Arguments

    func testNavigateToTypingSection() {
        app.launchArguments += ["--ui-settings-section", "typing"]
        launchApp()
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.descendants(matching: .any)["SettingsSection-typing"].exists)
    }

    func testNavigateToEncodingSection() {
        app.launchArguments += ["--ui-settings-section", "encoding"]
        launchApp()
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.descendants(matching: .any)["SettingsSection-encoding"].exists)
    }

    func testNavigateToTranslationSection() {
        app.launchArguments += ["--ui-settings-section", "translation"]
        launchApp()
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.descendants(matching: .any)["SettingsSection-translation"].exists)
    }

    func testNavigateToClipboardSection() {
        app.launchArguments += ["--ui-settings-section", "clipboard"]
        launchApp()
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.descendants(matching: .any)["SettingsSection-clipboard"].exists)
    }

    func testNavigateToMacrosSection() {
        app.launchArguments += ["--ui-settings-section", "macros"]
        launchApp()
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.descendants(matching: .any)["SettingsSection-macros"].exists)
    }

    func testNavigateToSmartSwitchSection() {
        app.launchArguments += ["--ui-settings-section", "smartSwitch"]
        launchApp()
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.descendants(matching: .any)["SettingsSection-smartSwitch"].exists)
    }

    func testNavigateToBehaviorSection() {
        app.launchArguments += ["--ui-settings-section", "behavior"]
        launchApp()
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.descendants(matching: .any)["SettingsSection-behavior"].exists)
    }

    func testNavigateToSystemSection() {
        app.launchArguments += ["--ui-settings-section", "system"]
        launchApp()
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.descendants(matching: .any)["SettingsSection-system"].exists)
    }

    func testNavigateToAboutSection() {
        app.launchArguments += ["--ui-settings-section", "about"]
        launchApp()
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.descendants(matching: .any)["SettingsSection-about"].exists)
    }

    // MARK: - Section Content Verification

    func testTypingSectionHasDetailContent() {
        app.launchArguments += ["--ui-settings-section", "typing"]
        launchApp()
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].waitForExistence(timeout: 10))
        XCTAssertGreaterThan(app.staticTexts.count, 0)
    }

    func testEncodingSectionHasDetailContent() {
        app.launchArguments += ["--ui-settings-section", "encoding"]
        launchApp()
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].waitForExistence(timeout: 10))
        XCTAssertGreaterThan(app.staticTexts.count, 0)
    }

    func testTranslationSectionHasDetailContent() {
        app.launchArguments += ["--ui-settings-section", "translation"]
        launchApp()
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].waitForExistence(timeout: 10))
        XCTAssertGreaterThan(app.staticTexts.count, 0)
    }

    func testClipboardSectionHasDetailContent() {
        app.launchArguments += ["--ui-settings-section", "clipboard"]
        launchApp()
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].waitForExistence(timeout: 10))
        XCTAssertGreaterThan(app.staticTexts.count, 0)
    }

    // MARK: - Keyboard Navigation

    func testKeyboardTabInTypingSettings() {
        app.launchArguments += ["--ui-settings-section", "typing"]
        launchApp()
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].waitForExistence(timeout: 10))
        app.typeKey(.tab, modifierFlags: [])
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].exists)
    }

    func testKeyboardTabInEncodingSettings() {
        app.launchArguments += ["--ui-settings-section", "encoding"]
        launchApp()
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].waitForExistence(timeout: 10))
        app.typeKey(.tab, modifierFlags: [])
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].exists)
    }

    func testKeyboardTabInMacroSettings() {
        app.launchArguments += ["--ui-settings-section", "macros"]
        launchApp()
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].waitForExistence(timeout: 10))
        app.typeKey(.tab, modifierFlags: [])
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].exists)
    }

    // MARK: - Language

    func testVietnameseLocalizationHeader() {
        app.launchArguments += ["--ui-language", "vi", "--ui-settings-section", "system"]
        launchApp()
        XCTAssertTrue(app.descendants(matching: .any)["InterfaceLanguagePicker"].waitForExistence(timeout: 10))
    }
}
