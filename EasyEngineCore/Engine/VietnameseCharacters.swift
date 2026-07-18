import Foundation

public enum VietnameseCharacters {
    // MARK: - Vowel tables (base, mark, tone) -> Unicode scalar

    // Source: Unicode 15.0 Latin Extended Additional block (U+1E00-U+1EFF)
    // and Latin-1 Supplement (U+00C0-U+00FF)

    // Row order per base: none, acute, grave, hook, tilde, dotBelow
    // Column order per mark: none, circumflex, breve, horn

    private static let lowerVowels: [Character: [[Character]]] = [
        "a": [
            // [none, circumflex, breve, horn] for each tone
            ["a", "â", "ă", "a"], // none
            ["á", "ấ", "ắ", "á"], // acute
            ["à", "ầ", "ằ", "à"], // grave
            ["ả", "ẩ", "ẳ", "ả"], // hook
            ["ã", "ẫ", "ẵ", "ã"], // tilde
            ["ạ", "ậ", "ặ", "ạ"], // dotBelow
        ],
        "e": [
            ["e", "ê", "e", "e"],
            ["é", "ế", "é", "é"],
            ["è", "ề", "è", "è"],
            ["ẻ", "ể", "ẻ", "ẻ"],
            ["ẽ", "ễ", "ẽ", "ẽ"],
            ["ẹ", "ệ", "ẹ", "ẹ"],
        ],
        "i": [
            ["i", "i", "i", "i"],
            ["í", "í", "í", "í"],
            ["ì", "ì", "ì", "ì"],
            ["ỉ", "ỉ", "ỉ", "ỉ"],
            ["ĩ", "ĩ", "ĩ", "ĩ"],
            ["ị", "ị", "ị", "ị"],
        ],
        "o": [
            ["o", "ô", "o", "ơ"],
            ["ó", "ố", "ó", "ớ"],
            ["ò", "ồ", "ò", "ờ"],
            ["ỏ", "ổ", "ỏ", "ở"],
            ["õ", "ỗ", "õ", "ỡ"],
            ["ọ", "ộ", "ọ", "ợ"],
        ],
        "u": [
            ["u", "u", "u", "ư"],
            ["ú", "ú", "ú", "ứ"],
            ["ù", "ù", "ù", "ừ"],
            ["ủ", "ủ", "ủ", "ử"],
            ["ũ", "ũ", "ũ", "ữ"],
            ["ụ", "ụ", "ụ", "ự"],
        ],
        "y": [
            ["y", "y", "y", "y"],
            ["ý", "ý", "ý", "ý"],
            ["ỳ", "ỳ", "ỳ", "ỳ"],
            ["ỷ", "ỷ", "ỷ", "ỷ"],
            ["ỹ", "ỹ", "ỹ", "ỹ"],
            ["ỵ", "ỵ", "ỵ", "ỵ"],
        ],
    ]

    private static let upperVowels: [Character: [[Character]]] = [
        "a": [
            ["A", "Â", "Ă", "A"],
            ["Á", "Ấ", "Ắ", "Á"],
            ["À", "Ầ", "Ằ", "À"],
            ["Ả", "Ẩ", "Ẳ", "Ả"],
            ["Ã", "Ẽ", "Ẵ", "Ã"],
            ["Ạ", "Ậ", "Ặ", "Ạ"],
        ],
        "e": [
            ["E", "Ê", "E", "E"],
            ["É", "Ế", "É", "É"],
            ["È", "Ề", "È", "È"],
            ["Ẻ", "Ể", "Ẻ", "Ẻ"],
            ["Ẽ", "Ễ", "Ẽ", "Ẽ"],
            ["Ẹ", "Ệ", "Ẹ", "Ẹ"],
        ],
        "i": [
            ["I", "I", "I", "I"],
            ["Í", "Í", "Í", "Í"],
            ["Ì", "Ì", "Ì", "Ì"],
            ["Ỉ", "Ỉ", "Ỉ", "Ỉ"],
            ["Ĩ", "Ĩ", "Ĩ", "Ĩ"],
            ["Ị", "Ị", "Ị", "Ị"],
        ],
        "o": [
            ["O", "Ô", "O", "Ơ"],
            ["Ó", "Ố", "Ó", "Ớ"],
            ["Ò", "Ồ", "Ò", "Ờ"],
            ["Ỏ", "Ổ", "Ỏ", "Ở"],
            ["Õ", "Ỗ", "Õ", "Ỡ"],
            ["Ọ", "Ộ", "Ọ", "Ợ"],
        ],
        "u": [
            ["U", "U", "U", "Ư"],
            ["Ú", "Ú", "Ú", "Ứ"],
            ["Ù", "Ù", "Ù", "Ừ"],
            ["Ủ", "Ủ", "Ủ", "Ử"],
            ["Ũ", "Ũ", "Ũ", "Ữ"],
            ["Ụ", "Ụ", "Ụ", "Ự"],
        ],
        "y": [
            ["Y", "Y", "Y", "Y"],
            ["Ý", "Ý", "Ý", "Ý"],
            ["Ỳ", "Ỳ", "Ỳ", "Ỳ"],
            ["Ỷ", "Ỷ", "Ỷ", "Ỷ"],
            ["Ỹ", "Ỹ", "Ỹ", "Ỹ"],
            ["Ỵ", "Ỵ", "Ỵ", "Ỵ"],
        ],
    ]

    public static func vowel(
        base: Character,
        mark: DiacriticalMark,
        tone: Tone,
        uppercase: Bool
    ) -> Character? {
        let table = uppercase ? upperVowels : lowerVowels
        guard let baseTable = table[base] else { return nil }
        let toneIndex = tone.rawValue
        guard toneIndex < baseTable.count else { return nil }
        let toneRow = baseTable[toneIndex]
        let markIndex = mark.rawValue
        guard markIndex < toneRow.count else { return nil }
        return toneRow[markIndex]
    }

    public static let lowerD: Character = "d"
    public static let upperD: Character = "D"
    public static let lowerDStroke: Character = "đ"
    public static let upperDStroke: Character = "Đ"

    public static func d(withStroke: Bool, uppercase: Bool) -> Character {
        if withStroke {
            return uppercase ? upperDStroke : lowerDStroke
        }
        return uppercase ? upperD : lowerD
    }

    public static let vowels: Set<Character> = [
        "a",
        "e",
        "i",
        "o",
        "u",
        "y",
        "A",
        "E",
        "I",
        "O",
        "U",
        "Y",
    ]

    public static let toneMarkKeys: [Tone: Set<Character>] = [
        .acute: ["s", "S"],
        .grave: ["f", "F"],
        .hook: ["r", "R"],
        .tilde: ["x", "X"],
        .dotBelow: ["j", "J"],
    ]

    public static let toneNumberKeys: [Character: Tone] = [
        "1": .acute,
        "2": .grave,
        "3": .hook,
        "4": .tilde,
        "5": .dotBelow,
    ]

    public static let diacriticNumberKeys: [Character: DiacriticalMark] = [
        "6": .circumflex,
        "7": .horn,
        "8": .breve,
        "9": .stroke,
    ]

    public static let startConsonants: Set<String> = [
        "b", "c", "d", "đ", "g", "h", "k", "l", "m", "n", "p", "q", "r", "s", "t", "v", "x",
        "ch", "gh", "gi", "kh", "ng", "ngh", "nh", "ph", "th", "tr", "qu",
    ]

    public static let endConsonants: Set<String> = [
        "c", "ch", "m", "n", "ng", "nh", "p", "t",
    ]

    public static func isVowel(_ character: Character) -> Bool {
        let lower = Character(character.lowercased())
        return vowels.contains(lower)
    }

    public static func baseVowel(_ character: Character) -> Character? {
        let lower = Character(character.lowercased())
        switch lower {
        case "a", "â", "ă": return Character("a")
        case "e", "ê": return Character("e")
        case "i": return Character("i")
        case "o", "ô", "ơ": return Character("o")
        case "u", "ư": return Character("u")
        case "y": return Character("y")
        default: return nil
        }
    }

    public static func mark(forVowel character: Character) -> DiacriticalMark {
        let lower = Character(character.lowercased())
        switch lower {
        case "â": return .circumflex
        case "ă": return .breve
        case "ơ": return .horn
        case "ư": return .horn
        default: return .none
        }
    }
}
