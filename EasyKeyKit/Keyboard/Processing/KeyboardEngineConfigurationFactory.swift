import EasyEngineCore
import Foundation

/// Applies the active app's compatibility rule on top of the core
/// settings→configuration mapping.
enum KeyboardEngineConfigurationFactory {
    static func make(
        for settings: EasyKeySettings,
        rule: AppCompatibilityRule?
    ) -> EngineConfiguration {
        var configuration = EngineConfiguration(settings: settings)
        if rule?.workarounds.contains(.unicodeCombiningOutput) == true {
            configuration.outputEncoding = .unicodeCombining
        }
        return configuration
    }
}
