import Foundation

/// Deterministic language-selection rules shared by every translation
/// surface, kept independent of UI state and provider behavior.
public enum TranslationLanguagePolicy {
    /// Swaps source and target languages. When the source is automatic
    /// detection (`nil`), swapping has no concrete language to promote into
    /// the target position, so the pair is returned unchanged.
    public static func swapped(
        source: TranslationLanguage?,
        target: TranslationLanguage
    ) -> (source: TranslationLanguage?, target: TranslationLanguage) {
        guard let source else { return (source, target) }
        return (target, source)
    }

    /// Maps a keyboard input language to its opposite-language translation
    /// target: Vietnamese input defaults to an English target, and English
    /// input defaults to a Vietnamese target.
    public static func defaultTarget(forInput inputLanguage: InputLanguage) -> TranslationLanguage {
        switch inputLanguage {
        case .vietnamese:
            return .english
        case .english:
            return .vietnamese
        }
    }
}
