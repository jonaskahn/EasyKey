import Foundation

public struct InputSettings: Codable, Equatable, Sendable {
    public var language: InputLanguage
    public var inputMethod: InputMethod
    public var encoding: EncodingTable
    public var switchShortcut: Shortcut

    public init(
        language: InputLanguage = .vietnamese,
        inputMethod: InputMethod = .simpleTelex,
        encoding: EncodingTable = .unicode,
        switchShortcut: Shortcut = Shortcut(keyCode: 6, modifiers: [.option])
    ) {
        self.language = language
        self.inputMethod = inputMethod
        self.encoding = encoding
        self.switchShortcut = switchShortcut
    }
}
