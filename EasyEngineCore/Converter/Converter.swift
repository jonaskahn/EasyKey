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

/// Shared codec used by output encoders and text conversion. Tables derive from
/// Unicode normalization and public TCVN3/VNI-Windows code charts.
public enum EncodingCodec {
    private static let unicodeCharacters = vietnameseCharacters()
    private static let tcvn3 = tcvn3Mappings()
    private static let tcvn3Inverse = Dictionary(tcvn3.map { ($1, $0) }, uniquingKeysWith: { first, _ in first })
    private static let vni = vniMappings()
    private static let vniInverse = Dictionary(vni.map { ($1, $0) }, uniquingKeysWith: { first, _ in first })
    private static let vniSingleCharacters: [Character: Character] = ["ñ": "đ", "Ñ": "Đ"]

    public static func encode(_ text: String, as encoding: EncodingTable) -> String {
        switch encoding {
        case .unicode:
            text
        case .unicodeCombining, .cp1258:
            text.map { character in
                unicodeCharacters.contains(character) ? String(character).decomposedStringWithCanonicalMapping : String(character)
            }.joined()
        case .tcvn3:
            text.map { tcvn3[$0].map(String.init) ?? String($0) }.joined()
        case .vniWindows:
            text.map { vni[$0] ?? String($0) }.joined()
        }
    }

    public static func decode(_ text: String, from encoding: EncodingTable) -> String {
        switch encoding {
        case .unicode:
            normalizeVietnameseCharacters(in: text)
        case .unicodeCombining, .cp1258:
            normalizeVietnameseCharacters(in: text)
        case .tcvn3:
            text.map { tcvn3Inverse[$0].map(String.init) ?? String($0) }.joined()
        case .vniWindows:
            decodeVNI(text)
        }
    }

    public static func removeVietnameseMarks(from text: String) -> String {
        text.map { character in
            guard unicodeCharacters.contains(character) else { return String(character) }
            switch character {
            case "đ": return "d"
            case "Đ": return "D"
            default:
                return String(character).decomposedStringWithCanonicalMapping.unicodeScalars
                    .filter { !CharacterSet.nonBaseCharacters.contains($0) }
                    .map(String.init)
                    .joined()
            }
        }.joined()
    }

    private static func normalizeVietnameseCharacters(in text: String) -> String {
        text.map { character in
            let normalized = String(character).precomposedStringWithCanonicalMapping
            guard normalized.count == 1, let normalizedCharacter = normalized.first,
                  unicodeCharacters.contains(normalizedCharacter)
            else {
                return String(character)
            }
            return normalized
        }.joined()
    }

    private static func decodeVNI(_ text: String) -> String {
        let characters = Array(text)
        var output = ""
        var index = 0
        while index < characters.count {
            if index + 2 < characters.count {
                let triplet = String(characters[index ... index + 2])
                if let decoded = vniInverse[triplet] {
                    output.append(decoded)
                    index += 3
                    continue
                }
            }
            if index + 1 < characters.count {
                let pair = String(characters[index ... index + 1])
                if let decoded = vniInverse[pair] {
                    output.append(decoded)
                    index += 2
                    continue
                }
            }
            if let decoded = vniSingleCharacters[characters[index]] {
                output.append(decoded)
                index += 1
                continue
            }
            output.append(characters[index])
            index += 1
        }
        return output
    }

    private static func vietnameseCharacters() -> Set<Character> {
        var result: Set<Character> = ["đ", "Đ"]
        for base in [Character("a"), "e", "i", "o", "u", "y"] {
            for mark in DiacriticalMark.allCases where mark != .stroke {
                for tone in Tone.allCases {
                    if let lower = VietnameseCharacters.vowel(base: base, mark: mark, tone: tone, uppercase: false) {
                        result.insert(lower)
                    }
                    if let upper = VietnameseCharacters.vowel(base: base, mark: mark, tone: tone, uppercase: true) {
                        result.insert(upper)
                    }
                }
            }
        }
        return result
    }

    private static func vniMappings() -> [Character: String] {
        var mappings: [Character: String] = ["đ": "ñ", "Đ": "Ñ"]
        let toneMarkers: [Character: Character] = ["\u{0301}": "ù", "\u{0300}": "ø", "\u{0309}": "û", "\u{0303}": "õ", "\u{0323}": "ï"]
        let markMarkers: [Character: Character] = ["\u{0302}": "â", "\u{0306}": "ê", "\u{031B}": "ô"]
        for character in unicodeCharacters where character != "đ" && character != "Đ" {
            let decomposition = String(character).decomposedStringWithCanonicalMapping
            let scalars = Array(decomposition.unicodeScalars)
            guard let base = scalars.first else { continue }
            var marks: [Character] = []
            for scalar in scalars.dropFirst() {
                let scalarCharacter = Character(String(scalar))
                if let mark = markMarkers[scalarCharacter] {
                    marks.append(mark)
                }
                if let tone = toneMarkers[scalarCharacter] {
                    marks.append(tone)
                }
            }
            if !marks.isEmpty {
                mappings[character] = "\(Character(String(base)))\(String(marks))"
            }
        }
        return mappings
    }

    private static func tcvn3Mappings() -> [Character: Character] {
        [
            "à": "µ", "á": "¸", "ả": "¶", "ã": "·", "ạ": "¹", "â": "©", "ấ": "Ê", "ầ": "Ç", "ẩ": "È", "ẫ": "É", "ậ": "Ë",
            "ă": "¨", "ắ": "¾", "ằ": "»", "ẳ": "¼", "ẵ": "½", "ặ": "Æ", "đ": "®",
            "è": "Ì", "é": "Ð", "ẻ": "Î", "ẽ": "Ï", "ẹ": "Ñ", "ê": "ª", "ế": "Õ", "ề": "Ò", "ể": "Ó", "ễ": "Ô", "ệ": "Ö",
            "ì": "×", "í": "Ý", "ỉ": "Ø", "ĩ": "Ü", "ị": "Þ",
            "ò": "ß", "ó": "ã", "ỏ": "á", "õ": "â", "ọ": "ä", "ô": "«", "ố": "è", "ồ": "å", "ổ": "æ", "ỗ": "ç", "ộ": "é",
            "ơ": "¬", "ớ": "í", "ờ": "ê", "ở": "ë", "ỡ": "ì", "ợ": "î",
            "ù": "ï", "ú": "ó", "ủ": "ñ", "ũ": "ò", "ụ": "ô", "ư": "­", "ứ": "ø", "ừ": "ö", "ử": "÷", "ữ": "ü", "ự": "þ",
            "ỳ": "ú", "ý": "ý", "ỷ": "û", "ỹ": "ÿ", "ỵ": "þ",
        ]
    }
}
