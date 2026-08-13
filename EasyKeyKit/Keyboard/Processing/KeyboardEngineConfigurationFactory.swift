import EasyEngineCore
import Foundation

/// Builds engine configuration from user settings plus the active app's
/// compatibility rule.
enum KeyboardEngineConfigurationFactory {
    static func make(
        for settings: EasyKeySettings,
        rule: AppCompatibilityRule?
    ) -> EngineConfiguration {
        var configuration = EngineConfiguration(
            inputMethod: settings.input.inputMethod,
            outputEncoding: settings.input.encoding,
            spellCheck: settings.typing.spellCheck,
            autoRestoreKeys: settings.typing.restoreInvalidWord,
            toneStyle: settings.typing.toneStyle,
            quickTelexConsonants: settings.typing.quickTelexConsonants,
            standaloneWShortcut: settings.typing.standaloneWShortcut,
            bracketShortcuts: settings.typing.bracketShortcuts,
            uppercaseFirstCharacter: settings.typing.uppercaseFirstCharacter,
            liveConfidenceScoring: settings.typing.liveConfidenceScoring,
            liveConfidenceLowThreshold: settings.typing.liveConfidenceLowThreshold,
            liveConfidenceHighThreshold: settings.typing.liveConfidenceHighThreshold,
            iosUniKeyLikeMode: settings.typing.iosUniKeyLikeMode,
            literalTechnicalTokens: settings.typing.literalTechnicalTokens
        )
        if rule?.workarounds.contains(.unicodeCombiningOutput) == true {
            configuration.outputEncoding = .unicodeCombining
        }
        return configuration
    }
}
