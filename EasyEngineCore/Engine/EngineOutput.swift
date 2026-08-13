import Foundation

public struct EngineOutput: Equatable, Sendable {
    public enum Disposition: Equatable, Sendable {
        case pass
        case suppress
    }

    public enum Edit: Equatable, Sendable {
        case deleteBackward(Int)
        case insert(String)
        case replaceBackward(deleteCount: Int, insert: String)
    }

    public enum SessionEffect: Equatable, Sendable {
        case continueSession
        case resetSession
    }

    public var disposition: Disposition
    public var edits: [Edit]
    public var sessionEffect: SessionEffect

    public init(
        disposition: Disposition,
        edits: [Edit] = [],
        sessionEffect: SessionEffect = .continueSession
    ) {
        self.disposition = disposition
        self.edits = edits
        self.sessionEffect = sessionEffect
    }

    static let passThrough = EngineOutput(disposition: .pass)

    static let suppress = EngineOutput(disposition: .suppress)
}
