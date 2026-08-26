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
}
