import Foundation

public struct MacroOptions: Codable, Equatable, Sendable {
    public var enabled: Bool
    public var enabledInEnglish: Bool
    public var autoCapitalize: Bool

    public init(
        enabled: Bool = false,
        enabledInEnglish: Bool = false,
        autoCapitalize: Bool = false
    ) {
        self.enabled = enabled
        self.enabledInEnglish = enabledInEnglish
        self.autoCapitalize = autoCapitalize
    }
}
