import Foundation

/// Engine-facing configuration derived from user settings. Built once per
/// settings change by the platform layers and consumed by the engine types.
public struct EngineConfiguration: Equatable, Sendable {
    public var inputMethod: InputMethod
    public var outputEncoding: EncodingTable
    public var spellCheck: Bool
    public var autoRestoreKeys: Bool
    public var toneStyle: ToneStyle
    public var quickTelexConsonants: Bool
    public var standaloneWShortcut: Bool
    public var bracketShortcuts: Bool
    public var uppercaseFirstCharacter: Bool
    public var liveConfidenceScoring: Bool
    public var liveConfidenceLowThreshold: Double
    public var liveConfidenceHighThreshold: Double
    public var iosUniKeyLikeMode: Bool
    public var literalTechnicalTokens: Bool

    public init(
        inputMethod: InputMethod = .simpleTelex,
        outputEncoding: EncodingTable = .unicode,
        spellCheck: Bool = true,
        autoRestoreKeys: Bool = true,
        toneStyle: ToneStyle = .old,
        quickTelexConsonants: Bool = false,
        standaloneWShortcut: Bool = true,
        bracketShortcuts: Bool = true,
        uppercaseFirstCharacter: Bool = false,
        liveConfidenceScoring: Bool = false,
        liveConfidenceLowThreshold: Double = LiveConfidenceDefaults.lowThreshold,
        liveConfidenceHighThreshold: Double = LiveConfidenceDefaults.highThreshold,
        iosUniKeyLikeMode: Bool = true,
        literalTechnicalTokens: Bool = true
    ) {
        self.inputMethod = inputMethod
        self.outputEncoding = outputEncoding
        self.spellCheck = spellCheck
        self.autoRestoreKeys = autoRestoreKeys
        self.toneStyle = toneStyle
        self.quickTelexConsonants = quickTelexConsonants
        self.standaloneWShortcut = standaloneWShortcut
        self.bracketShortcuts = bracketShortcuts
        self.uppercaseFirstCharacter = uppercaseFirstCharacter
        self.liveConfidenceScoring = liveConfidenceScoring
        self.liveConfidenceLowThreshold = liveConfidenceLowThreshold
        self.liveConfidenceHighThreshold = liveConfidenceHighThreshold
        self.iosUniKeyLikeMode = iosUniKeyLikeMode
        self.literalTechnicalTokens = literalTechnicalTokens
    }
}
