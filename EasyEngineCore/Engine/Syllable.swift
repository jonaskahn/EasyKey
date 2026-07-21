import Foundation

/// Orthographic syllable components used by tone placement and validation.
/// `qu` and `gi` onsets absorb their glide vowel (the `u`/`i` is not part of
/// the nucleus). Standalone "gì" keeps `i` as its nucleus.
struct Syllable: Equatable, Sendable {
    var onset: String
    var nucleus: String
    var final: String

    var isOpen: Bool {
        final.isEmpty
    }

    /// Parses a word of plain base letters (lowercased, marks stripped).
    /// Returns nil when no vowel nucleus exists.
    static func parse(_ text: String) -> Syllable? {
        let letters = text.map { Character(String($0).lowercased()) }
        guard !letters.isEmpty else { return nil }

        var index = 0
        var onset = ""

        if !VietnameseCharacters.isVowel(letters[0]) {
            for candidate in VietnameseOrthography.onsetsByLength
                where letters.count >= candidate.count {
                if String(letters.prefix(candidate.count)) == candidate {
                    if candidate == "gi" || candidate == "qu" {
                        guard letters.count > candidate.count,
                              VietnameseCharacters.isVowel(letters[candidate.count])
                        else {
                            continue
                        }
                    }
                    onset = candidate
                    index = candidate.count
                    break
                }
            }
            if onset.isEmpty {
                onset = String(letters[0])
                index = 1
            }
        }

        guard letters.count > index, VietnameseCharacters.isVowel(letters[index]) else {
            return nil
        }

        let tail = letters[index...]
        var finalLength = 0
        if tail.count > 1 {
            for length in stride(from: min(3, tail.count - 1), through: 1, by: -1) {
                let candidate = String(tail.suffix(length))
                if VietnameseOrthography.finals.contains(candidate) {
                    finalLength = length
                    break
                }
            }
        }

        let nucleusLetters = tail.prefix(tail.count - finalLength)
        guard !nucleusLetters.isEmpty, nucleusLetters.allSatisfy(VietnameseCharacters.isVowel) else {
            return nil
        }

        return Syllable(
            onset: onset,
            nucleus: String(nucleusLetters),
            final: String(tail.suffix(finalLength))
        )
    }
}
