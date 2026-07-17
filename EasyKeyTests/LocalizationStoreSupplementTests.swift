import EasyEngineCore
@testable import EasyKey
import SwiftUI
import XCTest

@MainActor
final class LocalizationStoreSupplementTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var store: LocalizationStore!

    override func setUpWithError() throws {
        suiteName = "one.ifelse.easykey.localization-supplement.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        store = LocalizationStore(defaults: defaults, bundle: .main)
    }

    override func tearDownWithError() throws {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        store = nil
        suiteName = nil
    }

    func testDisplayNameForEveryEncoding() {
        for encoding in EncodingTable.allCases {
            XCTAssertFalse(store.displayName(for: encoding).isEmpty)
        }
    }

    func testDisplayNameForEveryInputMethod() {
        for method in InputMethod.allCases {
            XCTAssertFalse(store.displayName(for: method).isEmpty)
        }
    }

    func testDisplayNameForEveryLanguage() {
        for language in InputLanguage.allCases {
            XCTAssertFalse(store.displayName(for: language).isEmpty)
        }
    }

    func testSectionTitleForEverySection() {
        for section in SettingsSection.allCases {
            XCTAssertFalse(store.sectionTitle(section).isEmpty)
        }
    }

    func testMacroErrorMessagesForEveryCase() {
        let errors: [MacroStoreError] = [
            .emptyTrigger,
            .emptyExpansion,
            .triggerTooLong,
            .expansionTooLong,
            .duplicateTrigger,
            .unknownMacro,
            .invalidImportLine(2),
        ]
        for error in errors {
            XCTAssertFalse(store.errorMessage(error).isEmpty)
        }
    }

    func testErrorMessage_NonMacroError_FallsBackToLocalizedDescription() {
        struct SampleError: Error, LocalizedError {
            var errorDescription: String? {
                "sample failure"
            }
        }
        XCTAssertEqual(store.errorMessage(SampleError()), "sample failure")
    }

    func testPreferenceBinding_GetAndSet() {
        let binding = store.preferenceBinding
        binding.wrappedValue = AppLanguage.english.rawValue
        XCTAssertEqual(store.preference, .english)
        XCTAssertEqual(binding.wrappedValue, AppLanguage.english.rawValue)
    }

    func testPreferenceBinding_InvalidRawValue_DoesNotChangePreference() {
        store.setPreference(.english)
        let binding = store.preferenceBinding
        binding.wrappedValue = "not-a-real-language"
        XCTAssertEqual(store.preference, .english)
    }

    func testLocalizedModifier_AppliesWithoutCrashing() {
        struct Probe: View {
            var body: some View {
                Text("hello").localized()
            }
        }
        let host = NSHostingController(rootView: Probe())
        XCTAssertNotNil(host.view)
    }
}
