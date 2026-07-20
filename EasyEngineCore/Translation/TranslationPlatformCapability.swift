import Foundation

/// Injectable description of what the running OS supports, so resolution
/// logic never queries `ProcessInfo` or `#available` itself. The app layer
/// constructs this once from the real OS version and passes it in.
public struct TranslationPlatformCapability: Equatable, Sendable {
    public var supportsAppleTranslation: Bool

    public init(supportsAppleTranslation: Bool) {
        self.supportsAppleTranslation = supportsAppleTranslation
    }
}
