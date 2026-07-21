import Foundation

/// Tone-placement style. Divergence is limited to open `oa`/`oe`/`uy`
/// clusters: old (aesthetic) places the mark on the first vowel
/// (hòa, thủy, khỏe), new (phonetic) on the main vowel (hoà, thuý, khoẻ).
public enum ToneStyle: String, Codable, CaseIterable, Sendable {
    case old
    case new
}
