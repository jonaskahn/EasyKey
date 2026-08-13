import Foundation

public enum ConverterTransform: String, Codable, CaseIterable, Hashable, Sendable {
    case allCaps
    case lowercase
    case capitalizeSentences
    case capitalizeWords
    case removeMarks
}

public struct ConverterConfiguration: Codable, Equatable, Sendable {
    public var sourceEncoding: EncodingTable
    public var destinationEncoding: EncodingTable
    public var transforms: Set<ConverterTransform>

    public init(
        sourceEncoding: EncodingTable = .unicode,
        destinationEncoding: EncodingTable = .unicode,
        transforms: Set<ConverterTransform> = []
    ) {
        self.sourceEncoding = sourceEncoding
        self.destinationEncoding = destinationEncoding
        self.transforms = transforms
    }
}

public enum Converter {
    /// Converts text without accessing platform clipboard services.
    public static func preview(input: String, configuration: ConverterConfiguration) -> String {
        let unicode = EncodingCodec.decode(input, from: configuration.sourceEncoding)
        let transformed = apply(configuration.transforms, to: unicode)
        return EncodingCodec.encode(transformed, as: configuration.destinationEncoding)
    }

    private static func apply(_ transforms: Set<ConverterTransform>, to text: String) -> String {
        var output = text
        if transforms.contains(.removeMarks) {
            output = EncodingCodec.removeVietnameseMarks(from: output)
        }
        if transforms.contains(.allCaps) {
            output = output.uppercased()
        }
        if transforms.contains(.lowercase) {
            output = output.lowercased()
        }
        if transforms.contains(.capitalizeWords) {
            output = capitalizeWords(in: output)
        }
        if transforms.contains(.capitalizeSentences) {
            output = capitalizeSentences(in: output)
        }
        return output
    }

    private static func capitalizeWords(in text: String) -> String {
        var nextIsFirst = true
        var output = ""
        for character in text {
            if character.isLetter {
                output += nextIsFirst ? String(character).uppercased() : String(character)
                nextIsFirst = false
            } else {
                output.append(character)
                nextIsFirst = true
            }
        }
        return output
    }

    private static func capitalizeSentences(in text: String) -> String {
        var shouldCapitalize = true
        var output = ""
        for character in text {
            if character.isLetter, shouldCapitalize {
                output += String(character).uppercased()
                shouldCapitalize = false
            } else {
                output.append(character)
            }
            if ".!?".contains(character) {
                shouldCapitalize = true
            }
        }
        return output
    }
}
