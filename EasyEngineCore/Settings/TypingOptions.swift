import Foundation

public struct TypingOptions: Codable, Equatable, Sendable {
    public var spellingModernization: Bool
    public var freeToneMarking: Bool
    public var quickTelex: Bool
    public var restoreInvalidWord: Bool
    public var allowZFWJ: Bool
    public var quickStartEndConsonant: Bool
    public var temporarySpellToggle: Shortcut
    public var temporaryEngineToggle: Shortcut
    public var uppercaseFirstCharacter: Bool

    public init(
        spellingModernization: Bool = true,
        freeToneMarking: Bool = false,
        quickTelex: Bool = false,
        restoreInvalidWord: Bool = true,
        allowZFWJ: Bool = false,
        quickStartEndConsonant: Bool = false,
        temporarySpellToggle: Shortcut = .none,
        temporaryEngineToggle: Shortcut = .none,
        uppercaseFirstCharacter: Bool = false
    ) {
        self.spellingModernization = spellingModernization
        self.freeToneMarking = freeToneMarking
        self.quickTelex = quickTelex
        self.restoreInvalidWord = restoreInvalidWord
        self.allowZFWJ = allowZFWJ
        self.quickStartEndConsonant = quickStartEndConsonant
        self.temporarySpellToggle = temporarySpellToggle
        self.temporaryEngineToggle = temporaryEngineToggle
        self.uppercaseFirstCharacter = uppercaseFirstCharacter
    }
}
