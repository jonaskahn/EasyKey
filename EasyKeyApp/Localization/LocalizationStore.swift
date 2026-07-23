import Combine
import EasyEngineCore
import Foundation
import SwiftUI

/// Single observable resolver: semantic key → locale value for SwiftUI and AppKit.
/// Injects `UserDefaults` (`.standard` by default) so extensions and isolated test suites can provide custom defaults.
@MainActor
final class LocalizationStore: ObservableObject {
    static let shared = LocalizationStore()

    @Published private(set) var preference: AppLanguage {
        didSet {
            guard oldValue != preference else { return }
            preference.save(to: defaults)
            refreshLocaleCaches()
        }
    }

    /// Concrete `en` / `vi` code currently in effect.
    @Published private(set) var resolvedCode: String

    /// Locale injected into SwiftUI via `.environment(\.locale, ...)`.
    @Published private(set) var locale: Locale

    /// Catalog loaded from `Localizable.xcstrings`: key → language code → value.
    private let catalog: [String: [String: String]]
    private let defaults: UserDefaults
    private var defaultsObserver: AnyCancellable?

    init(defaults: UserDefaults = .standard, bundle: Bundle = .main) {
        self.defaults = defaults
        catalog = Self.loadCatalog(from: bundle)
        let preference = AppLanguage.load(from: defaults)
        self.preference = preference
        let code = preference.resolvedCode
        resolvedCode = code
        locale = Locale(identifier: code)
        observeSystemLanguageChanges()
    }

    func setPreference(_ preference: AppLanguage) {
        self.preference = preference
    }

    /// Binding for pickers that store `AppLanguage.rawValue`.
    var preferenceBinding: Binding<String> {
        Binding(
            get: { self.preference.rawValue },
            set: { raw in
                if let language = AppLanguage(rawValue: raw) {
                    self.setPreference(language)
                }
            }
        )
    }

    func string(_ key: L10nKey) -> String {
        if let value = catalog[key.rawValue]?[resolvedCode] {
            return value
        }
        if let value = catalog[key.rawValue]?["en"] {
            return value
        }
        if let path = Bundle.main.path(forResource: resolvedCode, ofType: "lproj"),
           let languageBundle = Bundle(path: path) {
            let value = languageBundle.localizedString(forKey: key.rawValue, value: nil, table: nil)
            if value != key.rawValue {
                return value
            }
        }
        return String(localized: String.LocalizationValue(key.rawValue), locale: locale)
    }

    func format(_ key: L10nKey, _ arguments: CVarArg...) -> String {
        String(format: string(key), locale: locale, arguments: arguments)
    }

    func errorMessage(_ error: Error) -> String {
        if let macroError = error as? MacroStoreError {
            return macroErrorMessage(macroError)
        }
        return error.localizedDescription
    }

    func displayName(for language: InputLanguage) -> String {
        switch language {
        case .vietnamese: string(.domainLanguageVietnamese)
        case .english: string(.domainLanguageEnglish)
        }
    }

    func displayName(for method: InputMethod) -> String {
        switch method {
        case .telex: string(.domainMethodTelex)
        case .vni: string(.domainMethodVni)
        case .simpleTelex: string(.domainMethodSimpleTelex)
        }
    }

    func displayName(for toneStyle: ToneStyle) -> String {
        switch toneStyle {
        case .old: string(.typingToneStyleOld)
        case .new: string(.typingToneStyleNew)
        }
    }

    func displayName(for encoding: EncodingTable) -> String {
        switch encoding {
        case .unicode: string(.domainEncodingUnicode)
        case .unicodeCombining: string(.domainEncodingUnicodeCombining)
        case .tcvn3: string(.domainEncodingTcvn3)
        case .vniWindows: string(.domainEncodingVniWindows)
        case .cp1258: string(.domainEncodingCp1258)
        }
    }

    func sectionTitle(_ section: SettingsSection) -> String {
        switch section {
        case .typing: string(.settingsSectionTyping)
        case .encoding: string(.settingsSectionEncoding)
        case .translation: string(.settingsSectionTranslation)
        case .clipboard: string(.settingsSectionClipboard)
        case .macros: string(.settingsSectionMacros)
        case .smartSwitch: string(.settingsSectionSmartSwitch)
        case .behavior: string(.settingsSectionBehavior)
        case .system: string(.settingsSectionSystem)
        case .about: string(.settingsSectionAbout)
        }
    }

    func shortcutLabel(_ shortcut: Shortcut) -> String {
        guard shortcut.isActive else { return string(.commonNone) }
        return shortcut.displayLabel
    }

    private func macroErrorMessage(_ error: MacroStoreError) -> String {
        switch error {
        case .emptyTrigger: string(.macrosErrorEmptyTrigger)
        case .emptyExpansion: string(.macrosErrorEmptyExpansion)
        case .triggerTooLong: string(.macrosErrorTriggerTooLong)
        case .expansionTooLong: string(.macrosErrorExpansionTooLong)
        case .duplicateTrigger: string(.macrosErrorDuplicateTrigger)
        case .unknownMacro: string(.macrosErrorUnknownMacro)
        case let .invalidImportLine(line): format(.macrosErrorInvalidImportLine, line)
        }
    }

    private func refreshLocaleCaches() {
        let code = preference.resolvedCode
        resolvedCode = code
        locale = Locale(identifier: code)
    }

    private func observeSystemLanguageChanges() {
        defaultsObserver = NotificationCenter.default.publisher(for: NSLocale.currentLocaleDidChangeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self, preference == .system else { return }
                refreshLocaleCaches()
            }
    }

    private static func loadCatalog(from bundle: Bundle) -> [String: [String: String]] {
        var catalog = loadCompiledStrings(from: bundle)
        if !catalog.isEmpty {
            return catalog
        }

        guard let url = bundle.url(forResource: "Localizable", withExtension: "xcstrings"),
              let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let strings = root["strings"] as? [String: Any]
        else {
            return [:]
        }

        for (key, rawEntry) in strings {
            guard let entry = rawEntry as? [String: Any],
                  let localizations = entry["localizations"] as? [String: Any]
            else { continue }

            var values: [String: String] = [:]
            for (language, rawLocalization) in localizations {
                guard let localization = rawLocalization as? [String: Any],
                      let unit = localization["stringUnit"] as? [String: Any],
                      let value = unit["value"] as? String
                else { continue }
                values[language] = value
            }
            if !values.isEmpty {
                catalog[key] = values
            }
        }
        return catalog
    }

    private static func loadCompiledStrings(from bundle: Bundle) -> [String: [String: String]] {
        var catalog: [String: [String: String]] = [:]
        for language in AppLanguage.supportedCodes {
            guard let path = bundle.path(forResource: language, ofType: "lproj"),
                  let languageBundle = Bundle(path: path),
                  let stringsPath = languageBundle.path(forResource: "Localizable", ofType: "strings"),
                  let dictionary = NSDictionary(contentsOfFile: stringsPath) as? [String: String]
            else { continue }

            for (key, value) in dictionary {
                catalog[key, default: [:]][language] = value
            }
        }
        return catalog
    }
}

extension View {
    /// Applies the active interface locale and observes localization changes.
    func localized() -> some View {
        modifier(LocalizedEnvironmentModifier())
    }
}

private struct LocalizedEnvironmentModifier: ViewModifier {
    @ObservedObject private var localization = LocalizationStore.shared

    func body(content: Content) -> some View {
        content
            .environment(\.locale, localization.locale)
            .environmentObject(localization)
    }
}
