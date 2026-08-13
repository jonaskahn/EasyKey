import Foundation

/// Bundled sample macro packs users can add from the Macros settings screen.
/// Each pack maps a curated set of triggers to their canonical expansion.
public enum MacroSamplePack: String, CaseIterable, Sendable {
    case english
    case vietnamese
    case nineX
    case genZ

    public var category: MacroCategory {
        switch self {
        case .english: .english
        case .vietnamese: .vietnamese
        case .nineX: .nineX
        case .genZ: .genZ
        }
    }

    /// Fresh `Macro` instances (new IDs) for the pack, ready for insertion.
    public var macros: [Macro] {
        entries.map { Macro(trigger: $0.trigger, expansion: $0.expansion, category: category) }
    }

    private var entries: [SampleEntry] {
        switch self {
        case .english: Self.englishEntries
        case .vietnamese: Self.vietnameseEntries
        case .nineX: Self.nineXEntries
        case .genZ: Self.genZEntries
        }
    }

    private struct SampleEntry: Sendable {
        let trigger: String
        let expansion: String
    }
}

extension MacroSamplePack {
    private static let englishEntries: [SampleEntry] = [
        SampleEntry(trigger: "btw", expansion: "by the way"),
        SampleEntry(trigger: "asap", expansion: "as soon as possible"),
        SampleEntry(trigger: "tbh", expansion: "to be honest"),
        SampleEntry(trigger: "imo", expansion: "in my opinion"),
        SampleEntry(trigger: "idk", expansion: "I don't know"),
        SampleEntry(trigger: "fyi", expansion: "for your information"),
        SampleEntry(trigger: "omw", expansion: "on my way"),
        SampleEntry(trigger: "lmk", expansion: "let me know"),
        SampleEntry(trigger: "np", expansion: "no problem"),
        SampleEntry(trigger: "thx", expansion: "thanks"),
        SampleEntry(trigger: "brb", expansion: "be right back"),
        SampleEntry(trigger: "ttyl", expansion: "talk to you later"),
        SampleEntry(trigger: "aka", expansion: "also known as"),
        SampleEntry(trigger: "omg", expansion: "oh my god"),
        SampleEntry(trigger: "fomo", expansion: "fear of missing out"),
    ]

    private static let vietnameseEntries: [SampleEntry] = [
        SampleEntry(trigger: "dc", expansion: "được"),
        SampleEntry(trigger: "ko", expansion: "không"),
        SampleEntry(trigger: "j", expansion: "gì"),
        SampleEntry(trigger: "ntn", expansion: "như thế nào"),
        SampleEntry(trigger: "vs", expansion: "với"),
        SampleEntry(trigger: "mn", expansion: "mọi người"),
        SampleEntry(trigger: "ns", expansion: "nói"),
        SampleEntry(trigger: "nt", expansion: "nhắn tin"),
        SampleEntry(trigger: "cmt", expansion: "bình luận"),
        SampleEntry(trigger: "cty", expansion: "công ty"),
        SampleEntry(trigger: "dt", expansion: "điện thoại"),
        SampleEntry(trigger: "gd", expansion: "gia đình"),
        SampleEntry(trigger: "tks", expansion: "cảm ơn"),
        SampleEntry(trigger: "bt", expansion: "bình thường"),
        SampleEntry(trigger: "nx", expansion: "nhận xét"),
        SampleEntry(trigger: "sv", expansion: "sinh viên"),
    ]

    private static let nineXEntries: [SampleEntry] = [
        SampleEntry(trigger: "coa", expansion: "có"),
        SampleEntry(trigger: "hem", expansion: "không"),
        SampleEntry(trigger: "hok", expansion: "không"),
        SampleEntry(trigger: "wa", expansion: "quá"),
        SampleEntry(trigger: "zay", expansion: "vậy"),
        SampleEntry(trigger: "mun", expansion: "muốn"),
        SampleEntry(trigger: "bit", expansion: "biết"),
        SampleEntry(trigger: "j", expansion: "gì"),
        SampleEntry(trigger: "k", expansion: "không"),
        SampleEntry(trigger: "ck", expansion: "chồng"),
        SampleEntry(trigger: "vk", expansion: "vợ"),
        SampleEntry(trigger: "ny", expansion: "người yêu"),
        SampleEntry(trigger: "g9", expansion: "ngủ ngon"),
        SampleEntry(trigger: "s2", expansion: "trái tim"),
        SampleEntry(trigger: "nk", expansion: "biệt danh"),
        SampleEntry(trigger: "acc", expansion: "tài khoản"),
        SampleEntry(trigger: "2k", expansion: "sinh năm 2000"),
        SampleEntry(trigger: "sn", expansion: "sinh nhật"),
        SampleEntry(trigger: "stt", expansion: "dòng trạng thái"),
        SampleEntry(trigger: "avt", expansion: "ảnh đại diện"),
        SampleEntry(trigger: "uk", expansion: "ừ"),
        SampleEntry(trigger: "ak", expansion: "ạ"),
    ]

    private static let genZEntries: [SampleEntry] = [
        SampleEntry(trigger: "fr", expansion: "for real"),
        SampleEntry(trigger: "ngl", expansion: "not gonna lie"),
        SampleEntry(trigger: "ong", expansion: "on God"),
        SampleEntry(trigger: "iykyk", expansion: "if you know, you know"),
        SampleEntry(trigger: "no cap", expansion: "no lie; I'm serious"),
        SampleEntry(trigger: "cap", expansion: "a lie; nonsense"),
        SampleEntry(trigger: "bet", expansion: "okay; I agree"),
        SampleEntry(trigger: "sus", expansion: "suspicious"),
        SampleEntry(trigger: "goat", expansion: "greatest of all time"),
        SampleEntry(trigger: "slay", expansion: "to do something exceptionally well"),
        SampleEntry(trigger: "rizz", expansion: "charisma; charm"),
        SampleEntry(trigger: "mid", expansion: "average; mediocre"),
        SampleEntry(trigger: "bussin", expansion: "delicious; really good"),
        SampleEntry(trigger: "salty", expansion: "upset; bitter"),
        SampleEntry(trigger: "drip", expansion: "stylish outfit; fashion"),
        SampleEntry(trigger: "tea", expansion: "gossip"),
    ]
}
