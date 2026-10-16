import EasyEngineCore
import Foundation

/// Builds the engine configuration from the core settings→configuration
/// mapping. Compatibility rules no longer rewrite the output encoding:
/// typed output is normalized to NFC at the synthesis boundary instead, so
/// the user's encoding setting is honored in every app.
enum KeyboardEngineConfigurationFactory {
    static func make(
        for settings: EasyKeySettings,
        rule _: AppCompatibilityRule?
    ) -> EngineConfiguration {
        EngineConfiguration(settings: settings)
    }
}
