import Foundation

public struct ConverterOptions: Codable, Equatable, Sendable {
    public var sourceEncoding: EncodingTable
    public var destinationEncoding: EncodingTable
    public var shortcut: Shortcut

    public init(
        sourceEncoding: EncodingTable = .unicode,
        destinationEncoding: EncodingTable = .unicode,
        shortcut: Shortcut = .none
    ) {
        self.sourceEncoding = sourceEncoding
        self.destinationEncoding = destinationEncoding
        self.shortcut = shortcut
    }
}
