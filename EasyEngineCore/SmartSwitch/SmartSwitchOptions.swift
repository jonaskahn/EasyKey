import Foundation

public struct SmartSwitchOptions: Codable, Equatable, Sendable {
    public var enabled: Bool
    public var rememberEncoding: Bool
    public var perApplicationValues: [String: ApplicationOverride]

    public struct ApplicationOverride: Codable, Equatable, Sendable {
        public var inputLanguage: InputLanguage
        public var encoding: EncodingTable

        public init(inputLanguage: InputLanguage, encoding: EncodingTable) {
            self.inputLanguage = inputLanguage
            self.encoding = encoding
        }
    }

    public init(
        enabled: Bool = false,
        rememberEncoding: Bool = false,
        perApplicationValues: [String: ApplicationOverride] = [:]
    ) {
        self.enabled = enabled
        self.rememberEncoding = rememberEncoding
        self.perApplicationValues = perApplicationValues
    }
}
