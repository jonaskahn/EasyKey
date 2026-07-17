import Foundation

public struct EasyKeySettings: Codable, Equatable, Sendable {
    public static let currentSchemaVersion: Int = 3

    public var schemaVersion: Int
    public var input: InputSettings
    public var typing: TypingOptions
    public var macro: MacroOptions
    public var compatibility: CompatibilityOptions
    public var smartSwitch: SmartSwitchOptions
    public var system: SystemOptions
    public var converter: ConverterOptions

    public init(
        schemaVersion: Int = currentSchemaVersion,
        input: InputSettings = InputSettings(),
        typing: TypingOptions = TypingOptions(),
        macro: MacroOptions = MacroOptions(),
        compatibility: CompatibilityOptions = CompatibilityOptions(),
        smartSwitch: SmartSwitchOptions = SmartSwitchOptions(),
        system: SystemOptions = SystemOptions(),
        converter: ConverterOptions = ConverterOptions()
    ) {
        self.schemaVersion = schemaVersion
        self.input = input
        self.typing = typing
        self.macro = macro
        self.compatibility = compatibility
        self.smartSwitch = smartSwitch
        self.system = system
        self.converter = converter
    }

    public static var defaults: EasyKeySettings {
        EasyKeySettings()
    }
}
