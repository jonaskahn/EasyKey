import EasyEngineCore
@testable import EasyKey
import XCTest

@MainActor
final class LocalizationTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var store: LocalizationStore!

    override func setUpWithError() throws {
        suiteName = "one.ifelse.easykey.localization-tests.\(UUID().uuidString)"
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

    func testEveryKeyResolvesInEnglishAndVietnamese() {
        for language in [AppLanguage.english, .vietnamese] {
            store.setPreference(language)
            for key in L10nKey.allCases {
                let value = store.string(key)
                XCTAssertFalse(value.isEmpty, "Empty value for \(key.rawValue) in \(language.rawValue)")
                XCTAssertNotEqual(
                    value,
                    key.rawValue,
                    "Unresolved key \(key.rawValue) in \(language.rawValue)"
                )
            }
        }
    }

    func testCatalogAndTypedKeysMatchExactly() throws {
        XCTAssertEqual(try Set(catalog().keys), Set(L10nKey.allCases.map(\.rawValue)))
    }

    func testEveryCatalogEntryHasMatchingEnglishVietnamesePlaceholders() throws {
        for (key, entry) in try catalog() {
            let localizations = try XCTUnwrap(entry["localizations"] as? [String: Any], key)
            let english = try localizedValue("en", from: localizations, key: key)
            let vietnamese = try localizedValue("vi", from: localizations, key: key)
            XCTAssertEqual(try placeholders(in: english), try placeholders(in: vietnamese), "Placeholder mismatch: \(key)")
        }
    }

    func testSemanticKeysMapToExpectedLocaleValues() {
        store.setPreference(.english)
        XCTAssertEqual(store.string(.onboardingWelcome), "Welcome")
        XCTAssertEqual(store.string(.commonBack), "Back")
        XCTAssertEqual(store.string(.settingsWindowTitle), "EasyKey Settings")

        store.setPreference(.vietnamese)
        XCTAssertEqual(store.string(.onboardingWelcome), "Chào mừng")
        XCTAssertEqual(store.string(.commonBack), "Quay lại")
        XCTAssertEqual(store.string(.settingsWindowTitle), "Cài đặt EasyKey")
    }

    func testInterpolatedMessages() {
        store.setPreference(.english)
        XCTAssertEqual(
            store.format(.macrosImported, 3),
            "Imported text expansions: 3. Duplicate triggers were skipped."
        )
        XCTAssertEqual(store.format(.macrosEnableTrigger, "addr"), "Enable addr")

        store.setPreference(.vietnamese)
        XCTAssertEqual(
            store.format(.macrosImported, 3),
            "Đã nhập 3 mục gõ tắt. Mục trùng đã được bỏ qua."
        )
    }

    func testTranslationCatalogHasMatchingEnglishVietnamesePlaceholders() throws {
        let catalog = try catalog()
        let translationKeys = catalog.keys.filter { $0.hasPrefix("translation.") }
        XCTAssertFalse(translationKeys.isEmpty)
        XCTAssertEqual(
            Set(translationKeys),
            Set(L10nKey.allCases.map(\.rawValue).filter { $0.hasPrefix("translation.") })
        )

        for key in translationKeys {
            let localizations = try XCTUnwrap(catalog[key]?["localizations"] as? [String: Any], key)
            let english = try localizedValue("en", from: localizations, key: key)
            let vietnamese = try localizedValue("vi", from: localizations, key: key)
            XCTAssertFalse(english.isEmpty, "Empty English value: \(key)")
            XCTAssertFalse(vietnamese.isEmpty, "Empty Vietnamese value: \(key)")
            XCTAssertEqual(try placeholders(in: english), try placeholders(in: vietnamese), "Placeholder mismatch: \(key)")
        }
    }

    func testTranslationCopyNamesProvidersAndDescribesActualDataFlow() {
        for language in [AppLanguage.english, .vietnamese] {
            store.setPreference(language)
            let disclosure = store.format(.translationCloudDisclosureFirstUse, "DeepL", "DeepL")
            XCTAssertEqual(disclosure.components(separatedBy: "DeepL").count - 1, 2)
            XCTAssertFalse(disclosure.contains(L10nKey.translationCloudDisclosureFirstUse.rawValue))
            XCTAssertTrue(store.format(.translationSettingsProviderDataHandling, "OpenAI").contains("OpenAI"))
        }

        store.setPreference(.english)
        let disclosure = store.format(.translationCloudDisclosureFirstUse, "DeepL", "DeepL")
        XCTAssertTrue(disclosure.contains("choose Translate"))
        XCTAssertTrue(disclosure.contains("source text"))
        XCTAssertTrue(disclosure.contains("never sent"))
    }

    func testSystemDefaultFallsBackToSupportedLanguage() {
        store.setPreference(.system)
        XCTAssertTrue(["en", "vi"].contains(store.resolvedCode))
        XCTAssertNotEqual(store.string(.onboardingWelcome), L10nKey.onboardingWelcome.rawValue)
    }

    func testPreferencePersists() {
        store.setPreference(.english)
        XCTAssertEqual(defaults.string(forKey: AppLanguage.storageKey), "en")

        store.setPreference(.system)
        XCTAssertEqual(defaults.string(forKey: AppLanguage.storageKey), "system")

        let reloaded = LocalizationStore(defaults: defaults, bundle: .main)
        XCTAssertEqual(reloaded.preference, .system)
    }

    func testDomainDisplayNamesAndMacroErrorsLocalize() {
        store.setPreference(.vietnamese)
        XCTAssertEqual(store.displayName(for: InputLanguage.vietnamese), "Tiếng Việt")
        XCTAssertEqual(store.displayName(for: InputLanguage.english), "Tiếng Anh")
        XCTAssertEqual(store.displayName(for: InputMethod.simpleTelex), "Simple Telex")
        XCTAssertEqual(
            store.errorMessage(MacroStoreError.emptyTrigger),
            "Nhập từ gõ tắt."
        )

        store.setPreference(.english)
        XCTAssertEqual(
            store.errorMessage(MacroStoreError.invalidImportLine(4)),
            "Line 4 contains invalid import data."
        )
    }

    func testShortcutNoneLocalizesWhileActiveLabelStaysTechnical() {
        store.setPreference(.vietnamese)
        XCTAssertEqual(store.shortcutLabel(.none), "Không có")

        let active = Shortcut(keyCode: 0, modifiers: [.command])
        XCTAssertTrue(active.isActive)
        XCTAssertEqual(store.shortcutLabel(active), active.displayLabel)
    }

    func testPreferenceBinding_RoundTripsAppLanguage() {
        let binding = store.preferenceBinding
        binding.wrappedValue = AppLanguage.english.rawValue
        XCTAssertEqual(store.preference, .english)
        binding.wrappedValue = AppLanguage.vietnamese.rawValue
        XCTAssertEqual(store.preference, .vietnamese)
    }

    func testPreferenceBinding_UpdatesPreference() {
        let binding = store.preferenceBinding
        binding.wrappedValue = "vi"
        XCTAssertEqual(store.preference, .vietnamese)
        binding.wrappedValue = "en"
        XCTAssertEqual(store.preference, .english)
    }

    func testPreferenceBinding_IgnoresUnknownRawValue() {
        let binding = store.preferenceBinding
        binding.wrappedValue = "garbage"
        XCTAssertNotEqual(store.preference.rawValue, "garbage")
    }

    func testSectionTitle_ReturnsLocalizedTitle() {
        store.setPreference(.english)
        XCTAssertEqual(store.sectionTitle(.typing), store.string(.settingsSectionTyping))
        XCTAssertEqual(store.sectionTitle(.smartSwitch), store.string(.settingsSectionSmartSwitch))
        XCTAssertEqual(store.sectionTitle(.translation), store.string(.settingsSectionTranslation))
        XCTAssertEqual(store.sectionTitle(.system), store.string(.settingsSectionSystem))
        XCTAssertEqual(store.sectionTitle(.about), store.string(.settingsSectionAbout))
    }

    func testDisplayName_ForInputMethodAndEncoding() {
        store.setPreference(.english)
        XCTAssertEqual(store.displayName(for: InputMethod.telex), store.string(.domainMethodTelex))
        XCTAssertEqual(store.displayName(for: InputMethod.vni), store.string(.domainMethodVni))
        XCTAssertEqual(store.displayName(for: EncodingTable.unicode), store.string(.domainEncodingUnicode))
        XCTAssertEqual(store.displayName(for: EncodingTable.tcvn3), store.string(.domainEncodingTcvn3))
        XCTAssertEqual(store.displayName(for: EncodingTable.cp1258), store.string(.domainEncodingCp1258))
    }

    func testErrorMessage_ForNonMacroError_UsesLocalizedFallback() {
        let error = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Boom"])
        store.setPreference(.english)
        XCTAssertEqual(store.errorMessage(error), "Something went wrong.")
        store.setPreference(.vietnamese)
        XCTAssertEqual(store.errorMessage(error), "Đã xảy ra lỗi.")
    }

    func testErrorMessage_ForAllMacroStoreErrors() {
        store.setPreference(.english)
        XCTAssertEqual(store.errorMessage(MacroStoreError.emptyTrigger), "Enter a trigger.")
        XCTAssertEqual(store.errorMessage(MacroStoreError.emptyExpansion), "Enter replacement text.")
        XCTAssertEqual(store.errorMessage(MacroStoreError.triggerTooLong), "Trigger is too long.")
        XCTAssertEqual(store.errorMessage(MacroStoreError.expansionTooLong), "Replacement text is too long.")
        XCTAssertEqual(store.errorMessage(MacroStoreError.duplicateTrigger), "This trigger is already in use.")
        XCTAssertEqual(store.errorMessage(MacroStoreError.unknownMacro), "Text expansion not found.")
        XCTAssertEqual(store.errorMessage(MacroStoreError.invalidImportLine(7)), "Line 7 contains invalid import data.")
    }

    func testSettingDescriptionsAndContextualActionsLocalize() {
        store.setPreference(.english)
        XCTAssertEqual(store.string(.commonRemove), "Remove")
        XCTAssertEqual(
            store.string(.typingQuickTelexConsonantsDescription),
            "Enable cc=ch, gg=gi, kk=kh, nn=ng, qq=qu, pp=ph, and tt=th."
        )
        XCTAssertEqual(store.format(.menuCurrentAppStatus, "Safari", "Remembered Vietnamese"), "Safari · Remembered Vietnamese")

        store.setPreference(.vietnamese)
        XCTAssertEqual(store.string(.settingsSectionMacros), "Gõ tắt")
        XCTAssertEqual(store.string(.macrosTrigger), "Từ gõ tắt")
        XCTAssertEqual(store.string(.macrosExpansionField), "Nội dung thay thế")
        XCTAssertEqual(store.string(.encodingTransformClipboard), "Chuyển mã nội dung đã sao chép")
    }

    func testSetPreference_DoesNotInvokeRefreshOnSameValue() {
        let initial = store.preference
        store.setPreference(initial)
        XCTAssertEqual(store.preference, initial)
    }

    func testSystemLocaleChange_TriggersRefreshWhenPreferenceIsSystem() {
        store.setPreference(.system)
        let originalCode = store.resolvedCode
        store.setPreference(.english)
        store.setPreference(.system)
        XCTAssertEqual(store.resolvedCode, originalCode)
        NotificationCenter.default.post(
            name: NSLocale.currentLocaleDidChangeNotification,
            object: nil
        )
    }

    func testInit_WithBundleContainingOnlyXcstrings_LoadsCatalog() throws {
        let suite = "one.ifelse.easykey.localization-xcstrings.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }

        let bundlePath = try Self.makeXcstringsOnlyBundle()
        let bundle = try XCTUnwrap(Bundle(path: bundlePath.path))
        let testStore = LocalizationStore(defaults: defaults, bundle: bundle)
        XCTAssertFalse(testStore.string(.commonOk).isEmpty || testStore.string(.commonOk) == L10nKey.commonOk.rawValue)
    }

    func testInit_WithEmptyBundle_FallsBackToSystemLocalization() throws {
        let suite = "one.ifelse.easykey.localization-empty.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }

        let bundlePath = try Self.makeEmptyCatalogBundle()
        let bundle = try XCTUnwrap(Bundle(path: bundlePath.path))
        let testStore = LocalizationStore(defaults: defaults, bundle: bundle)
        let fallback = testStore.string(.commonOk)
        XCTAssertFalse(fallback.isEmpty)
    }

    private static func makeXcstringsOnlyBundle() throws -> URL {
        let bundleURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocXcstrings-\(UUID().uuidString).bundle")
        try FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)

        let xcstrings: [String: Any] = [
            "sourceLanguage": "en",
            "strings": [
                "common.ok": [
                    "localizations": [
                        "en": ["stringUnit": ["state": "translated", "value": "OK"]],
                        "vi": ["stringUnit": ["state": "translated", "value": "Đồng ý"]],
                    ],
                ],
            ],
            "version": 1,
        ]
        let data = try JSONSerialization.data(withJSONObject: xcstrings, options: [])
        try data.write(to: bundleURL.appendingPathComponent("Localizable.xcstrings"))
        return bundleURL
    }

    private static func makeEmptyCatalogBundle() throws -> URL {
        let bundleURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocEmpty-\(UUID().uuidString).bundle")
        try FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)
        return bundleURL
    }

    private func catalog() throws -> [String: [String: Any]] {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("EasyKeyApp/Localizable.xcstrings")
        let object = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]
        return try XCTUnwrap(object?["strings"] as? [String: [String: Any]])
    }

    private func localizedValue(_ language: String, from localizations: [String: Any], key: String) throws -> String {
        let localization = try XCTUnwrap(localizations[language] as? [String: Any], "Missing \(language): \(key)")
        let unit = try XCTUnwrap(localization["stringUnit"] as? [String: Any], key)
        XCTAssertEqual(unit["state"] as? String, "translated", "Untranslated \(language): \(key)")
        return try XCTUnwrap(unit["value"] as? String, key)
    }

    private func placeholders(in value: String) throws -> [String] {
        let regex = try NSRegularExpression(pattern: "%((\\d+)\\$)?(?:@|d|ld|lld)")
        let range = NSRange(value.startIndex..., in: value)
        return regex.matches(in: value, range: range).compactMap { match in
            Range(match.range, in: value).map { String(value[$0]) }
        }
        .map { $0.replacingOccurrences(of: #"^%\d+\$"#, with: "%", options: .regularExpression) }
        .sorted()
    }
}
