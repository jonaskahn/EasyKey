import Foundation

/// Unicode Vietnamese letter tables. Rows follow tone order and columns follow
/// diacritic order defined by `Tone` and `DiacriticalMark` raw values.
public enum VietnameseCharacters {
    private static let lowerVowels: [Character: [[Character]]] = [
        "a": [
            ["a", "â", "ă", "a"],
            ["á", "ấ", "ắ", "á"],
            ["à", "ầ", "ằ", "à"],
            ["ả", "ẩ", "ẳ", "ả"],
            ["ã", "ẫ", "ẵ", "ã"],
            ["ạ", "ậ", "ặ", "ạ"],
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
            ["Ã", "Ẫ", "Ẵ", "Ã"],
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

    public static func d(withStroke: Bool, uppercase: Bool) -> Character {
        if withStroke {
            return uppercase ? "Đ" : "đ"
        }
        return uppercase ? "D" : "d"
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

    public static func isVowel(_ character: Character) -> Bool {
        let lower = Character(character.lowercased())
        return vowels.contains(lower)
    }

    public static func mark(forVowel character: Character) -> DiacriticalMark {
        let lower = Character(character.lowercased())
        switch lower {
        case "â", "ê", "ô": return .circumflex
        case "ă": return .breve
        case "ơ", "ư": return .horn
        default: return .none
        }
    }

    /// Plain-base letter with mark and tone stripped. Non-accented letters
    /// are returned unchanged.
    public static func baseLetter(_ character: Character) -> Character {
        accentedToBase[Character(character.lowercased())]
            .map { character.isUppercase ? Character(String($0).uppercased()) : $0 }
            ?? character
    }

    public static func tone(of character: Character) -> Tone {
        accentedToTone[Character(character.lowercased())] ?? .none
    }

    public static func removingTone(from character: Character) -> Character {
        let base = Character(String(baseLetter(character)).lowercased())
        guard isVowel(base) else { return character }
        return vowel(
            base: base,
            mark: mark(of: character),
            tone: .none,
            uppercase: character.isUppercase
        ) ?? character
    }

    private static let accentedToBase: [Character: Character] = buildBaseMap()
    private static let accentedToTone: [Character: Tone] = buildToneMap()
    private static let accentedToMark: [Character: DiacriticalMark] = buildMarkMap()

    static func mark(of character: Character) -> DiacriticalMark {
        accentedToMark[Character(character.lowercased())] ?? .none
    }

    private static func buildBaseMap() -> [Character: Character] {
        var map: [Character: Character] = [:]
        for (base, rows) in lowerVowels {
            for row in rows {
                for char in row where char != base {
                    map[char] = base
                }
            }
        }
        map["đ"] = "d"
        return map
    }

    private static func buildToneMap() -> [Character: Tone] {
        var map: [Character: Tone] = [:]
        for (_, rows) in lowerVowels {
            for (toneIndex, row) in rows.enumerated() where toneIndex > 0 {
                guard let tone = Tone(rawValue: toneIndex) else { continue }
                for char in row {
                    map[char] = tone
                }
            }
        }
        return map
    }

    private static func buildMarkMap() -> [Character: DiacriticalMark] {
        var map: [Character: DiacriticalMark] = [:]
        let validMarks: [Character: Set<DiacriticalMark>] = [
            "a": [.circumflex, .breve],
            "e": [.circumflex],
            "o": [.circumflex, .horn],
            "u": [.horn],
        ]
        for (base, rows) in lowerVowels {
            for row in rows {
                for (markIndex, char) in row.enumerated() where markIndex > 0 {
                    guard let mark = DiacriticalMark(rawValue: markIndex) else { continue }
                    guard validMarks[base]?.contains(mark) == true else { continue }
                    map[char] = mark
                }
            }
        }
        map["đ"] = .stroke
        return map
    }
}
