import Foundation

/// The curated set of languages EasyKey offers in source and target
/// language pickers, independent of which providers are configured.
public enum SupportedLanguages {
    public static let all: [TranslationLanguage] = [
        .english,
        .vietnamese,
        TranslationLanguage(bcp47: "fr"),
        TranslationLanguage(bcp47: "de"),
        TranslationLanguage(bcp47: "es"),
        TranslationLanguage(bcp47: "it"),
        TranslationLanguage(bcp47: "pt"),
        TranslationLanguage(bcp47: "ja"),
        TranslationLanguage(bcp47: "ko"),
        TranslationLanguage(bcp47: "zh-Hans"),
        TranslationLanguage(bcp47: "zh-Hant"),
        TranslationLanguage(bcp47: "ru"),
        TranslationLanguage(bcp47: "th"),
        TranslationLanguage(bcp47: "id"),
        TranslationLanguage(bcp47: "ar"),
        TranslationLanguage(bcp47: "hi"),
        TranslationLanguage(bcp47: "nl"),
        TranslationLanguage(bcp47: "pl"),
        TranslationLanguage(bcp47: "tr"),
        TranslationLanguage(bcp47: "sv"),
    ].compactMap { $0 }

    public static func contains(_ language: TranslationLanguage) -> Bool {
        all.contains(language)
    }
}
