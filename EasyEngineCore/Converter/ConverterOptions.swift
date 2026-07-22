import Foundation

public struct ConverterOptions: Codable, Equatable, Sendable {
    public var sourceEncoding: EncodingTable
    public var destinationEncoding: EncodingTable

    public init(
        sourceEncoding: EncodingTable = .unicode,
        destinationEncoding: EncodingTable = .unicode
    ) {
        self.sourceEncoding = sourceEncoding
        self.destinationEncoding = destinationEncoding
    }
}
