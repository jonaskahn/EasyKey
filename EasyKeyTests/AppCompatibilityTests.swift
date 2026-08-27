import EasyEngineCore
import EasyKeyKit
import XCTest

final class AppCompatibilityTests: XCTestCase {
    func testRule_Chromium_HasExpectedWorkarounds() {
        let rule = AppCompatibility.rule(for: "com.google.Chrome")
        XCTAssertEqual(rule?.workarounds, [.unicodeCombiningOutput, .emptyCharacterInsertion, .chromium])
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
            XCTAssertEqual(rule?.workarounds, [.unicodeCombiningOutput, .emptyCharacterInsertion, .chromium], bundleIdentifier)
        }
    }

    func testRule_Safari_UsesUnicodeCombiningOutput() {
        let rule = AppCompatibility.rule(for: "com.apple.Safari")
        XCTAssertEqual(rule?.workarounds, [.unicodeCombiningOutput])
    }

    func testRule_CustomChromiumBrowserUsesConfiguredWorkarounds() {
        let rule = AppCompatibility.rule(
            for: "dev.example.CustomBrowser",
            compatibilityModeApplicationBundleIdentifiers: ["dev.example.CustomBrowser"]
        )
        XCTAssertEqual(rule?.workarounds, [.unicodeCombiningOutput, .emptyCharacterInsertion, .chromium])
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
        // the Chromium rule must count replacements in code units so combining
        // output ("ề" = 3 code units) is fully deleted before re-insertion.
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
        // Safari, Spotlight, and VSCode are native fields: one backspace
        // deletes one grapheme cluster, so they keep grapheme counting even
        // though Chromium switched to code-point counting.
        XCTAssertEqual(AppCompatibility.rule(for: "com.apple.Safari")?.backspaceUnit, .grapheme)
        XCTAssertEqual(AppCompatibility.rule(for: "com.apple.Spotlight")?.backspaceUnit, .grapheme)
        XCTAssertEqual(AppCompatibility.rule(for: "com.microsoft.VSCode")?.backspaceUnit, .grapheme)
    }
}
