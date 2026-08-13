import Foundation

public struct TypingOptions: Codable, Equatable, Sendable {
    public var spellCheck: Bool
    public var restoreInvalidWord: Bool
    public var toneStyle: ToneStyle
    public var quickTelexConsonants: Bool
    public var standaloneWShortcut: Bool
    public var bracketShortcuts: Bool
    public var restoreWordShortcut: Shortcut
    public var uppercaseFirstCharacter: Bool
    public var liveConfidenceScoring: Bool
    public var liveConfidenceLowThreshold: Double
    public var liveConfidenceHighThreshold: Double
    public var iosUniKeyLikeMode: Bool

    public init(
        spellCheck: Bool = true,
        restoreInvalidWord: Bool = true,
        toneStyle: ToneStyle = .old,
        quickTelexConsonants: Bool = false,
        standaloneWShortcut: Bool = true,
        bracketShortcuts: Bool = true,
        restoreWordShortcut: Shortcut = .none,
        uppercaseFirstCharacter: Bool = false,
        liveConfidenceScoring: Bool = false,
        liveConfidenceLowThreshold: Double = LiveConfidenceDefaults.lowThreshold,
        liveConfidenceHighThreshold: Double = LiveConfidenceDefaults.highThreshold,
        iosUniKeyLikeMode: Bool = true
    ) {
        self.spellCheck = spellCheck
        self.restoreInvalidWord = restoreInvalidWord
        self.toneStyle = toneStyle
        self.quickTelexConsonants = quickTelexConsonants
        self.standaloneWShortcut = standaloneWShortcut
        self.bracketShortcuts = bracketShortcuts
        self.restoreWordShortcut = restoreWordShortcut
        self.uppercaseFirstCharacter = uppercaseFirstCharacter
        self.liveConfidenceScoring = liveConfidenceScoring
        self.liveConfidenceLowThreshold = liveConfidenceLowThreshold
        self.liveConfidenceHighThreshold = liveConfidenceHighThreshold
        self.iosUniKeyLikeMode = iosUniKeyLikeMode
    }

    private enum CodingKeys: String, CodingKey {
        case spellCheck
        case restoreInvalidWord
        case toneStyle
        case quickTelexConsonants
        case standaloneWShortcut
        case bracketShortcuts
        case restoreWordShortcut
        case uppercaseFirstCharacter
        case liveConfidenceScoring
        case liveConfidenceLowThreshold
        case liveConfidenceHighThreshold
        case iosUniKeyLikeMode
    }

    private enum LegacyCodingKeys: String, CodingKey {
        case quickTelexConsonants = "quickStartEndConsonant"
    }

    /// Defaulting decode so settings written by older releases (which contain
    /// removed keys and lack these) migrate without resetting preferences.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let legacyContainer = try decoder.container(keyedBy: LegacyCodingKeys.self)
        let defaults = TypingOptions()
        spellCheck = try container.decodeIfPresent(Bool.self, forKey: .spellCheck) ?? defaults.spellCheck
        restoreInvalidWord = try container.decodeIfPresent(Bool.self, forKey: .restoreInvalidWord) ?? defaults.restoreInvalidWord
        toneStyle = try container.decodeIfPresent(ToneStyle.self, forKey: .toneStyle) ?? defaults.toneStyle
        quickTelexConsonants = try container.decodeIfPresent(Bool.self, forKey: .quickTelexConsonants)
            ?? legacyContainer.decodeIfPresent(Bool.self, forKey: .quickTelexConsonants)
            ?? defaults.quickTelexConsonants
        standaloneWShortcut = try container.decodeIfPresent(Bool.self, forKey: .standaloneWShortcut) ?? defaults.standaloneWShortcut
        bracketShortcuts = try container.decodeIfPresent(Bool.self, forKey: .bracketShortcuts) ?? defaults.bracketShortcuts
        restoreWordShortcut = try container.decodeIfPresent(Shortcut.self, forKey: .restoreWordShortcut) ?? defaults.restoreWordShortcut
        uppercaseFirstCharacter = try container.decodeIfPresent(Bool.self, forKey: .uppercaseFirstCharacter) ?? defaults
            .uppercaseFirstCharacter
        liveConfidenceScoring = try container.decodeIfPresent(Bool.self, forKey: .liveConfidenceScoring)
            ?? defaults.liveConfidenceScoring
        liveConfidenceLowThreshold = try container.decodeIfPresent(Double.self, forKey: .liveConfidenceLowThreshold)
            ?? defaults.liveConfidenceLowThreshold
        liveConfidenceHighThreshold = try container.decodeIfPresent(Double.self, forKey: .liveConfidenceHighThreshold)
            ?? defaults.liveConfidenceHighThreshold
        iosUniKeyLikeMode = try container.decodeIfPresent(Bool.self, forKey: .iosUniKeyLikeMode)
            ?? defaults.iosUniKeyLikeMode
    }
}
