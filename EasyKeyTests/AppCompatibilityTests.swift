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

    func testRule_Safari_HasNoRule() {
        // Safari types precomposed NFC like every other app; the former
        // unicodeCombiningOutput workaround made its text unsearchable.
        XCTAssertNil(AppCompatibility.rule(for: "com.apple.Safari"))
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
        // Chromium uses code-point counting. Safari has no rule at all
        // (defaults to grapheme at the pipeline).
        XCTAssertEqual(AppCompatibility.rule(for: "com.apple.Safari"), nil)
        XCTAssertEqual(AppCompatibility.rule(for: "com.apple.Spotlight")?.backspaceUnit, .grapheme)
        XCTAssertEqual(AppCompatibility.rule(for: "com.microsoft.VSCode")?.backspaceUnit, .grapheme)
    }
}
