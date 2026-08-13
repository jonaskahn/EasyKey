import Foundation

public struct EasyKeySettings: Codable, Equatable, Sendable {
    public static let currentSchemaVersion: Int = 10

    public var schemaVersion: Int
    public var input: InputSettings
    public var typing: TypingOptions
    public var macro: MacroOptions
    public var compatibility: CompatibilityOptions
    public var smartSwitch: SmartSwitchOptions
    public var system: SystemOptions
    public var converter: ConverterOptions
    public var clipboard: ClipboardOptions
    public var translation: TranslationOptions

    public init(
        schemaVersion: Int = currentSchemaVersion,
        input: InputSettings = InputSettings(),
        typing: TypingOptions = TypingOptions(),
        macro: MacroOptions = MacroOptions(),
        compatibility: CompatibilityOptions = CompatibilityOptions(),
        smartSwitch: SmartSwitchOptions = SmartSwitchOptions(),
        system: SystemOptions = SystemOptions(),
        converter: ConverterOptions = ConverterOptions(),
        clipboard: ClipboardOptions = ClipboardOptions(),
        translation: TranslationOptions = TranslationOptions()
    ) {
        self.schemaVersion = schemaVersion
        self.input = input
        self.typing = typing
        self.macro = macro
        self.compatibility = compatibility
        self.smartSwitch = smartSwitch
        self.system = system
        self.converter = converter
        self.clipboard = clipboard
        self.translation = translation
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case input
        case typing
        case macro
        case compatibility
        case smartSwitch
        case system
        case converter
        case clipboard
        case translation
    }

    /// Decodes every root field with `decodeIfPresent` and its current default so a
    /// settings document written by an older release — which lacks newer keys such
    /// as `clipboard` — migrates without resetting unrelated preferences.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? Self.currentSchemaVersion
        input = try container.decodeIfPresent(InputSettings.self, forKey: .input) ?? InputSettings()
        typing = try container.decodeIfPresent(TypingOptions.self, forKey: .typing) ?? TypingOptions()
        macro = try container.decodeIfPresent(MacroOptions.self, forKey: .macro) ?? MacroOptions()
        compatibility = try container.decodeIfPresent(CompatibilityOptions.self, forKey: .compatibility) ?? CompatibilityOptions()
        smartSwitch = try container.decodeIfPresent(SmartSwitchOptions.self, forKey: .smartSwitch) ?? SmartSwitchOptions()
        system = try container.decodeIfPresent(SystemOptions.self, forKey: .system) ?? SystemOptions()
        converter = try container.decodeIfPresent(ConverterOptions.self, forKey: .converter) ?? ConverterOptions()
        clipboard = try container.decodeIfPresent(ClipboardOptions.self, forKey: .clipboard) ?? ClipboardOptions()
        translation = try container.decodeIfPresent(TranslationOptions.self, forKey: .translation) ?? TranslationOptions()
    }

    public static var defaults: EasyKeySettings {
        EasyKeySettings()
    }
}

public struct SettingsDelta: Equatable, Sendable {
    public var schemaVersionChanged: Bool
    public var inputChanged: Bool
    public var typingChanged: Bool
    public var macroChanged: Bool
    public var compatibilityChanged: Bool
    public var smartSwitchChanged: Bool
    public var systemChanged: Bool
    public var converterChanged: Bool
    public var clipboardChanged: Bool
    public var translationChanged: Bool

    public var hasAnyChange: Bool {
        schemaVersionChanged || inputChanged || typingChanged || macroChanged ||
            compatibilityChanged || smartSwitchChanged || systemChanged ||
            converterChanged || clipboardChanged || translationChanged
    }

    public static func delta(from old: EasyKeySettings, to new: EasyKeySettings) -> SettingsDelta {
        SettingsDelta(
            schemaVersionChanged: old.schemaVersion != new.schemaVersion,
            inputChanged: old.input != new.input,
            typingChanged: old.typing != new.typing,
            macroChanged: old.macro != new.macro,
            compatibilityChanged: old.compatibility != new.compatibility,
            smartSwitchChanged: old.smartSwitch != new.smartSwitch,
            systemChanged: old.system != new.system,
            converterChanged: old.converter != new.converter,
            clipboardChanged: old.clipboard != new.clipboard,
            translationChanged: old.translation != new.translation
        )
    }
}
