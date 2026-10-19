import EasyEngineCore
import EasyKeyKit
import XCTest

final class AppCompatibilityTests: XCTestCase {
    func testRule_Chromium_HasExpectedWorkarounds() {
        let rule = AppCompatibility.rule(for: "com.google.Chrome")
        XCTAssertEqual(rule?.workarounds, [.emptyCharacterInsertion, .chromium])
    }

    func testRule_ConfiguredApplicationsHaveCompatibilityWorkarounds() {
        let bundleIdentifiers = [
            "com.microsoft.edgemac.Dev",
            "com.microsoft.edgemac.Beta",
            "com.microsoft.Edge.Dev",
            "com.microsoft.Edge",
        ]

        for bundleIdentifier in bundleIdentifiers {
            let rule = AppCompatibility.rule(
                for: bundleIdentifier,
                compatibilityModeApplicationBundleIdentifiers: bundleIdentifiers
            )
            XCTAssertEqual(rule?.workarounds, [.emptyCharacterInsertion, .chromium], bundleIdentifier)
        }
    }

    func testRule_Safari_UsesNativeRuleWithoutBlinkWorkarounds() {
        // Safari is a native text system: a fixed rule keeps it on grapheme
        // backspace counting and blocks Blink's workarounds even when Safari
        // is listed in compatibility mode (the former unicodeCombiningOutput
        // workaround made its text unsearchable).
        let rule = AppCompatibility.rule(for: "com.apple.Safari")
        XCTAssertEqual(rule?.workarounds, [])
        XCTAssertEqual(rule?.backspaceUnit, .grapheme)
    }

    func testRule_Terminal_UsesNativeRuleWithoutBlinkWorkarounds() {
        // Terminal edits text natively: grapheme backspace, no Blink
        // empty-character break in its shell input line.
        let rule = AppCompatibility.rule(for: "com.apple.Terminal")
        XCTAssertEqual(rule?.workarounds, [])
        XCTAssertEqual(rule?.backspaceUnit, .grapheme)
    }

    func testRule_SafariAndTerminalInConfiguredList_StayNative() {
        let configured = ["com.apple.Safari", "com.apple.Terminal", "com.google.Chrome"]
        for bundleIdentifier in ["com.apple.Safari", "com.apple.Terminal"] {
            let rule = AppCompatibility.rule(
                for: bundleIdentifier,
                compatibilityModeApplicationBundleIdentifiers: configured
            )
            XCTAssertEqual(rule?.workarounds, [], bundleIdentifier)
            XCTAssertEqual(rule?.backspaceUnit, .grapheme, bundleIdentifier)
        }
    }

    func testDefaultCompatibilityList_MakesSafariAndTerminalVisible() {
        let defaults = CompatibilityOptions.defaultCompatibilityModeApplicationBundleIdentifiers
        XCTAssertTrue(defaults.contains("com.apple.Safari"))
        XCTAssertTrue(defaults.contains("com.apple.Terminal"))
    }

    func testRule_CustomChromiumBrowserUsesConfiguredWorkarounds() {
        let rule = AppCompatibility.rule(
            for: "dev.example.CustomBrowser",
            compatibilityModeApplicationBundleIdentifiers: ["dev.example.CustomBrowser"]
        )
        XCTAssertEqual(rule?.workarounds, [.emptyCharacterInsertion, .chromium])
    }

    func testRule_RemovedDefaultBrowserHasNoChromiumWorkaround() {
        XCTAssertNil(AppCompatibility.rule(for: "com.google.Chrome", compatibilityModeApplicationBundleIdentifiers: []))
    }

    func testRule_FixedCompatibilityTakesPriorityOverConfiguredChromium() {
        let rule = AppCompatibility.rule(
            for: "com.apple.Spotlight",
            compatibilityModeApplicationBundleIdentifiers: ["com.apple.Spotlight"]
        )
        XCTAssertEqual(rule?.workarounds, [.spotlightSelection])
    }

    func testRule_Chromium_UsesCodePointBackspaceUnit() {
        // Blink web-page fields delete one UTF-16 code unit per backspace;
        // the Chromium rule must count replacements in code units so any
        // multi-unit text is fully deleted before re-insertion.
        let rule = AppCompatibility.rule(for: "com.google.Chrome")
        XCTAssertEqual(rule?.backspaceUnit, .codePoint)
    }

    func testRule_ConfiguredChromiumApps_UseCodePointBackspaceUnit() {
        let bundleIdentifiers = ["com.microsoft.edgemac.Dev", "dev.example.CustomBrowser"]
        for bundleIdentifier in bundleIdentifiers {
            let rule = AppCompatibility.rule(
                for: bundleIdentifier,
                compatibilityModeApplicationBundleIdentifiers: bundleIdentifiers
            )
            XCTAssertEqual(rule?.backspaceUnit, .codePoint, bundleIdentifier)
        }
    }

    func testRule_NativeFields_UseGraphemeBackspaceUnit() {
        // Spotlight and VSCode are native fields: one backspace deletes one
        // grapheme cluster, so they keep grapheme counting even though
        // Chromium uses code-point counting. Safari and Terminal have fixed
        // native rules that do the same.
        XCTAssertEqual(AppCompatibility.rule(for: "com.apple.Spotlight")?.backspaceUnit, .grapheme)
        XCTAssertEqual(AppCompatibility.rule(for: "com.microsoft.VSCode")?.backspaceUnit, .grapheme)
        XCTAssertEqual(AppCompatibility.rule(for: "com.apple.Safari")?.backspaceUnit, .grapheme)
        XCTAssertEqual(AppCompatibility.rule(for: "com.apple.Terminal")?.backspaceUnit, .grapheme)
    }
}
