import Foundation

public struct MacroOptions: Codable, Equatable, Sendable {
    public var enabled: Bool
    public var autoCapitalize: Bool

    public init(
        enabled: Bool = false,
        autoCapitalize: Bool = false
    ) {
        self.enabled = enabled
        self.autoCapitalize = autoCapitalize
    }
}
