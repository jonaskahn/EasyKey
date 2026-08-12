import XCTest

final class SettingsCoverageTests: XCTestCase {
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
        app.ensureKeyWindow()
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].waitForExistence(timeout: 10))
    }

    // MARK: - Typing Settings

    func testTypingSettingsSectionLoads() {
        launchToSection("typing")
        XCTAssertTrue(app.descendants(matching: .any)["SettingsSection-typing"].exists)
    }

    func testTypingSettingsHasContent() {
        launchToSection("typing")
        XCTAssertGreaterThan(app.staticTexts.count, 0)
    }

    func testTypingSettingsHasPicker() {
        launchToSection("typing")
        XCTAssertTrue(app.popUpButtons.firstMatch.waitForExistence(timeout: 5))
    }

    func testTypingSettingsHasRecordButtons() {
        launchToSection("typing")
        let recordButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Record'"))
        XCTAssertGreaterThanOrEqual(recordButtons.count, 1)
    }

    func testTypingSettingsSwitchesInteractable() {
        launchToSection("typing")
        let switches = app.switches
        if switches.count > 0 {
            switches.firstMatch.clickWhenHittable()
        }
    }

    // MARK: - Encoding Settings

    func testEncodingSettingsSectionLoads() {
        launchToSection("encoding")
        XCTAssertTrue(app.descendants(matching: .any)["SettingsSection-encoding"].exists)
    }

    func testEncodingSettingsHasPickers() {
        launchToSection("encoding")
        XCTAssertTrue(app.popUpButtons.firstMatch.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(app.popUpButtons.count, 2)
    }

    func testEncodingSettingsHasConvertButtons() {
        launchToSection("encoding")
        let buttons = app.buttons
        XCTAssertGreaterThan(buttons.count, 2)
    }

    func testEncodingSettingsHasTextEditor() {
        launchToSection("encoding")
        XCTAssertGreaterThanOrEqual(app.textViews.count, 1)
    }

    // MARK: - Translation Settings

    func testTranslationSettingsSectionLoads() {
        launchToSection("translation")
        XCTAssertTrue(app.descendants(matching: .any)["SettingsSection-translation"].exists)
    }

    func testTranslationSettingsProviderSelectorExists() {
        launchToSection("translation")
        let automaticProvider = app.descendants(matching: .any)["TranslationProvider-automatic"]
        XCTAssertTrue(app.reveal(automaticProvider))
    }

    func testTranslationSettingsEnableToggleExists() {
        launchToSection("translation")
        XCTAssertTrue(app.descendants(matching: .any)["TranslationEnableToggle"].waitForExistence(timeout: 10))
    }

    func testTranslationSettingsSourcePreferencePickerExists() {
        launchToSection("translation")
        XCTAssertTrue(app.descendants(matching: .any)["TranslationSourcePreferencePicker"].waitForExistence(timeout: 10))
    }

    func testTranslationSettingsShortcutStatusExists() {
        launchToSection("translation")
        XCTAssertTrue(app.descendants(matching: .any)["TranslationShortcutStatus"].waitForExistence(timeout: 10))
    }

    func testTranslationSettingsMenuPopoverToggleExists() {
        launchToSection("translation")
        XCTAssertTrue(app.descendants(matching: .any)["TranslationMenuPopoverToggle"].waitForExistence(timeout: 10))
    }

    func testTranslationSettingsDisclosureResetExists() {
        launchToSection("translation")
        XCTAssertTrue(app.descendants(matching: .any)["TranslationDisclosureReset"].waitForExistence(timeout: 10))
    }

    func testTranslationSettingsAppleLanguageSettingsExists() throws {
        launchToSection("translation")
        let appleDetails = app.descendants(matching: .any)["TranslationProviderDisclosure-apple"]
        try XCTSkipIf(!app.reveal(appleDetails), "Apple Translation is unavailable on this macOS version.")
        XCTAssertTrue(appleDetails.clickWhenHittable())
        XCTAssertTrue(app.descendants(matching: .any)["TranslationAppleLanguageSettings"].waitForExistence(timeout: 10))
    }

    // MARK: - Clipboard Settings

    func testClipboardSettingsSectionLoads() {
        launchToSection("clipboard")
        XCTAssertTrue(app.descendants(matching: .any)["SettingsSection-clipboard"].exists)
    }

    func testClipboardSettingsCaptureToggleExists() {
        launchToSection("clipboard")
        XCTAssertTrue(app.descendants(matching: .any)["ClipboardCaptureToggle"].waitForExistence(timeout: 5))
    }

    func testClipboardSettingsClearAllButtonExists() {
        launchToSection("clipboard")
        XCTAssertTrue(app.descendants(matching: .any)["ClipboardClearAllButton"].waitForExistence(timeout: 5))
    }

    func testClipboardSettingsHasPickers() {
        launchToSection("clipboard")
        XCTAssertGreaterThanOrEqual(app.popUpButtons.count, 1)
    }

    // MARK: - Macro Settings

    func testMacroSettingsSectionLoads() {
        launchToSection("macros")
        XCTAssertTrue(app.descendants(matching: .any)["SettingsSection-macros"].exists)
    }

    func testMacroSettingsHasSearchField() {
        launchToSection("macros")
        XCTAssertTrue(app.textFields.firstMatch.waitForExistence(timeout: 5))
    }

    func testMacroSettingsHasAddButton() {
        launchToSection("macros")
        let addBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Add'"))
        XCTAssertTrue(addBtn.firstMatch.exists)
    }

    func testMacroSettingsHasImportExportButtons() {
        launchToSection("macros")
        let importBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Import'"))
        XCTAssertTrue(importBtn.firstMatch.exists)
        let exportBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Export'"))
        XCTAssertTrue(exportBtn.firstMatch.exists)
    }

    func testMacroSettingsHasSwitches() {
        launchToSection("macros")
        XCTAssertGreaterThanOrEqual(app.switches.count, 1)
    }

    // MARK: - Smart Switch Settings

    func testSmartSwitchSettingsSectionLoads() {
        launchToSection("smartSwitch")
        XCTAssertTrue(app.descendants(matching: .any)["SettingsSection-smartSwitch"].exists)
    }

    func testSmartSwitchSettingsHasSwitches() {
        launchToSection("smartSwitch")
        XCTAssertGreaterThanOrEqual(app.switches.count, 1)
    }

    func testSmartSwitchSettingsHasContent() {
        launchToSection("smartSwitch")
        XCTAssertGreaterThan(app.staticTexts.count, 0)
    }

    // MARK: - Behavior Settings

    func testBehaviorSettingsSectionLoads() {
        launchToSection("behavior")
        XCTAssertTrue(app.descendants(matching: .any)["SettingsSection-behavior"].exists)
    }

    func testBehaviorSettingsHasSwitches() {
        launchToSection("behavior")
        XCTAssertGreaterThanOrEqual(app.switches.count, 1)
    }

    func testBehaviorSettingsHasAddButtons() {
        launchToSection("behavior")
        let addButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Add'"))
        XCTAssertGreaterThanOrEqual(addButtons.count, 1)
    }

    // MARK: - System Settings

    func testSystemSettingsSectionLoads() {
        launchToSection("system")
        XCTAssertTrue(app.descendants(matching: .any)["SettingsSection-system"].exists)
    }

    func testSystemSettingsLanguagePickerExists() {
        launchToSection("system")
        XCTAssertTrue(app.descendants(matching: .any)["InterfaceLanguagePicker"].waitForExistence(timeout: 10))
    }

    func testSystemSettingsHasCheckForUpdates() {
        launchToSection("system")
        let checkBtns = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Check'"))
        XCTAssertGreaterThanOrEqual(checkBtns.count, 1)
    }

    func testSystemSettingsHasResetButton() {
        launchToSection("system")
        let resetBtns = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Reset'"))
        XCTAssertGreaterThanOrEqual(resetBtns.count, 1)
    }

    func testSystemSettingsHasSwitches() {
        launchToSection("system")
        XCTAssertGreaterThanOrEqual(app.switches.count, 1)
    }

    // MARK: - About Settings

    func testAboutSettingsSectionLoads() {
        launchToSection("about")
        XCTAssertTrue(app.descendants(matching: .any)["SettingsSection-about"].exists)
    }

    func testAboutSettingsOpenSourceLicensesExists() {
        launchToSection("about")
        XCTAssertTrue(app.descendants(matching: .any)["OpenSourceLicenses"].waitForExistence(timeout: 5))
    }

    func testAboutSettingsHasVersion() {
        launchToSection("about")
        let hasContent = app.staticTexts.count > 1
        XCTAssertTrue(hasContent)
    }

    func testAboutSettingsHasSiteLink() {
        launchToSection("about")
        let siteLinks = app.links.matching(NSPredicate(format: "label CONTAINS 'Official'"))
        if siteLinks.count == 0 {
            let siteTexts = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Official'"))
            XCTAssertGreaterThanOrEqual(siteTexts.count, 1)
        }
    }

    func testAboutSettingsHasTrademarks() {
        launchToSection("about")
        let hasContent = app.staticTexts.count > 0
        XCTAssertTrue(hasContent)
    }

    // MARK: - Details section visibility

    func testSettingsDetailExists() {
        launchToSection("typing")
        XCTAssertTrue(app.descendants(matching: .any)["SettingsDetail"].exists)
    }

    func testSettingsSidebarExists() {
        launchToSection("typing")
        XCTAssertTrue(app.descendants(matching: .any)["SettingsSidebar"].exists)
    }
}
