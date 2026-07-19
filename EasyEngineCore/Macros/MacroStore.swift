import Foundation

public struct Macro: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var trigger: String
    public var expansion: String
    public var isEnabled: Bool
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        trigger: String,
        expansion: String,
        isEnabled: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.trigger = trigger
        self.expansion = expansion
        self.isEnabled = isEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public enum MacroStoreError: Error, Equatable, Sendable {
    case emptyTrigger
    case emptyExpansion
    case triggerTooLong
    case expansionTooLong
    case duplicateTrigger
    case unknownMacro
    case invalidImportLine(Int)
}

public enum MacroImportResolution: Codable, Equatable, Sendable {
    case replace
    case skip
    case rename
}

public struct MacroImportConflict: Codable, Equatable, Sendable {
    public let imported: Macro
    public let existing: Macro
}

public struct MacroImportPreview: Codable, Equatable, Sendable {
    public let additions: [Macro]
    public let conflicts: [MacroImportConflict]
    public let unparseableRecords: [String]
}

public final class MacroStore {
    public static let maximumTriggerLength = 128
    public static let maximumExpansionLength = 16384

    private let fileURL: URL?
    private var macrosByID: [UUID: Macro]
    private var encodedExpansions: [UUID: String] = [:]
    public private(set) var activeEncoding: EncodingTable

    public init(fileURL: URL? = nil, activeEncoding: EncodingTable = .unicode) {
        self.fileURL = fileURL
        self.activeEncoding = activeEncoding
        macrosByID = Self.load(from: fileURL)
        refreshEncodedExpansions()
    }

    public var macros: [Macro] {
        macrosByID.values.sorted { lhs, rhs in
            lhs.trigger.localizedCaseInsensitiveCompare(rhs.trigger) == .orderedAscending
        }
    }

    public func search(_ query: String) -> [Macro] {
        guard !query.isEmpty else { return macros }
        return macros.filter {
            $0.trigger.localizedCaseInsensitiveContains(query) ||
                $0.expansion.localizedCaseInsensitiveContains(query)
        }
    }

    @discardableResult
    public func add(trigger: String, expansion: String, isEnabled: Bool = true, now: Date = Date()) throws -> Macro {
        let macro = Macro(trigger: trigger, expansion: expansion, isEnabled: isEnabled, createdAt: now, updatedAt: now)
        try validate(macro)
        var candidate = macrosByID
        candidate[macro.id] = macro
        try save(candidate)
        macrosByID = candidate
        refreshEncodedExpansions()
        return macro
    }

    @discardableResult
    public func edit(
        id: UUID,
        trigger: String,
        expansion: String,
        isEnabled: Bool,
        now: Date = Date()
    ) throws -> Macro {
        guard var macro = macrosByID[id] else { throw MacroStoreError.unknownMacro }
        macro.trigger = trigger
        macro.expansion = expansion
        macro.isEnabled = isEnabled
        macro.updatedAt = now
        try validate(macro, excluding: id)
        var candidate = macrosByID
        candidate[id] = macro
        try save(candidate)
        macrosByID = candidate
        refreshEncodedExpansions()
        return macro
    }

    public func delete(id: UUID) throws {
        var candidate = macrosByID
        guard candidate.removeValue(forKey: id) != nil else { throw MacroStoreError.unknownMacro }
        try save(candidate)
        macrosByID = candidate
        refreshEncodedExpansions()
    }

    public func replaceAll(_ replacements: [Macro]) throws {
        var candidate: [UUID: Macro] = [:]
        for macro in replacements {
            try validate(macro, among: candidate.values)
            candidate[macro.id] = macro
        }
        try save(candidate)
        macrosByID = candidate
        refreshEncodedExpansions()
    }

    public func changeActiveEncoding(to encoding: EncodingTable) {
        activeEncoding = encoding
        refreshEncodedExpansions()
    }

    public func encodedExpansion(for id: UUID) -> String? {
        encodedExpansions[id]
    }

    public func expansion(for typedTrigger: String, autoCapitalize: Bool) -> String? {
        guard let macro = macros.first(where: {
            $0.isEnabled && $0.trigger.compare(typedTrigger, options: .caseInsensitive) == .orderedSame
        })
        else {
            return nil
        }
        return autoCapitalize ? Self.matchCapitalization(of: typedTrigger, in: macro.expansion) : macro.expansion
    }

    public func exportTSV() -> String {
        (["trigger\texpansion\tenabled"] + macros.map {
            "\($0.trigger)\t\($0.expansion)\t\($0.isEnabled ? "1" : "0")"
        }).joined(separator: "\n") + "\n"
    }

    public func export(to url: URL) throws {
        guard let data = exportTSV().data(using: .utf8) else { throw CocoaError(.fileWriteInapplicableStringEncoding) }
        try data.write(to: url, options: .atomic)
    }

    public func previewImport(from url: URL) throws -> MacroImportPreview {
        let data = try Data(contentsOf: url)
        guard let text = String(data: data, encoding: .utf8) else { throw CocoaError(.fileReadInapplicableStringEncoding) }
        return try previewImport(text)
    }

    public func previewImport(_ text: String) throws -> MacroImportPreview {
        var additions: [Macro] = []
        var conflicts: [MacroImportConflict] = []
        var unparseableRecords: [String] = []
        var seenTriggers: Set<String> = []
        for (offset, line) in text.split(whereSeparator: \.isNewline).enumerated() {
            if offset == 0, line == "trigger\texpansion\tenabled" {
                continue
            }
            let fields = line.split(separator: "\t", omittingEmptySubsequences: false)
            guard fields.count == 3, let isEnabled = Self.bool(from: String(fields[2])) else {
                unparseableRecords.append(String(line))
                continue
            }
            let macro = Macro(trigger: String(fields[0]), expansion: String(fields[1]), isEnabled: isEnabled)
            do {
                try validateFields(macro)
            } catch {
                unparseableRecords.append(String(line))
                continue
            }
            let normalizedTrigger = macro.trigger.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            guard seenTriggers.insert(normalizedTrigger).inserted else {
                unparseableRecords.append(String(line))
                continue
            }
            if let existing = macros.first(where: { $0.trigger.caseInsensitiveCompare(macro.trigger) == .orderedSame }) {
                conflicts.append(MacroImportConflict(imported: macro, existing: existing))
            } else {
                additions.append(macro)
            }
        }
        return MacroImportPreview(additions: additions, conflicts: conflicts, unparseableRecords: unparseableRecords)
    }

    /// Parses simple legacy `trigger => expansion` records without discarding bad lines.
    public func previewLegacyImport(_ text: String) throws -> MacroImportPreview {
        let tabSeparated = text.split(whereSeparator: \.isNewline).map { line -> String in
            let fields = String(line).components(separatedBy: "=>")
            guard fields.count == 2 else { return String(line) }
            return "\(fields[0].trimmingCharacters(in: .whitespaces))\t\(fields[1].trimmingCharacters(in: .whitespaces))\t1"
        }.joined(separator: "\n")
        return try previewImport(tabSeparated)
    }

    public func apply(_ preview: MacroImportPreview, resolving conflicts: [UUID: MacroImportResolution]) throws {
        var updated = macrosByID
        for macro in preview.additions {
            updated[macro.id] = macro
        }
        for conflict in preview.conflicts {
            switch conflicts[conflict.imported.id] ?? .skip {
            case .replace:
                var replacement = conflict.imported
                replacement = Macro(
                    id: conflict.existing.id,
                    trigger: replacement.trigger,
                    expansion: replacement.expansion,
                    isEnabled: replacement.isEnabled,
                    createdAt: conflict.existing.createdAt,
                    updatedAt: Date()
                )
                updated[replacement.id] = replacement
            case .skip:
                break
            case .rename:
                var renamed = conflict.imported
                renamed.trigger = availableTrigger(for: renamed.trigger, among: updated.values)
                updated[renamed.id] = renamed
            }
        }
        try replaceAll(Array(updated.values))
    }

    public static func matchCapitalization(of trigger: String, in expansion: String) -> String {
        guard trigger.rangeOfCharacter(from: .letters) != nil else { return expansion }
        if trigger == trigger.uppercased(), trigger != trigger.lowercased() {
            return expansion.uppercased()
        }
        guard trigger.first?.isUppercase == true, let first = expansion.first else { return expansion }
        return String(first).uppercased() + expansion.dropFirst()
    }

    private func validate(_ macro: Macro, excluding id: UUID? = nil) throws {
        try validateFields(macro)
        try validate(macro, among: macrosByID.values.filter { $0.id != id })
    }

    private func validate(_ macro: Macro, among candidates: some Sequence<Macro>) throws {
        if candidates.contains(where: { $0.trigger.caseInsensitiveCompare(macro.trigger) == .orderedSame }) {
            throw MacroStoreError.duplicateTrigger
        }
    }

    private func validateFields(_ macro: Macro) throws {
        guard !macro.trigger.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw MacroStoreError.emptyTrigger }
        guard !macro.expansion.isEmpty else { throw MacroStoreError.emptyExpansion }
        guard macro.trigger.count <= Self.maximumTriggerLength else { throw MacroStoreError.triggerTooLong }
        guard macro.expansion.count <= Self.maximumExpansionLength else { throw MacroStoreError.expansionTooLong }
        guard !macro.trigger.contains("\t"), !macro.trigger.contains("\n"), !macro.expansion.contains("\t"),
              !macro.expansion.contains("\n")
        else {
            throw MacroStoreError.invalidImportLine(0)
        }
    }

    private func availableTrigger(for trigger: String, among candidates: some Sequence<Macro>) -> String {
        let existing = candidates.map(\.trigger)
        var number = 2
        var candidate = "\(trigger) \(number)"
        while existing.contains(where: { $0.caseInsensitiveCompare(candidate) == .orderedSame }) {
            number += 1
            candidate = "\(trigger) \(number)"
        }
        return candidate
    }

    private func refreshEncodedExpansions() {
        encodedExpansions = Dictionary(uniqueKeysWithValues: macrosByID.values.map {
            ($0.id, EncodingCodec.encode($0.expansion, as: activeEncoding))
        })
    }

    private func save(_ macrosByID: [UUID: Macro]) throws {
        guard let fileURL else { return }
        let parent = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let macros = macrosByID.values.sorted { lhs, rhs in
            lhs.trigger.localizedCaseInsensitiveCompare(rhs.trigger) == .orderedAscending
        }
        try encoder.encode(macros).write(to: fileURL, options: .atomic)
    }

    private static func load(from fileURL: URL?) -> [UUID: Macro] {
        guard let fileURL, let data = try? Data(contentsOf: fileURL),
              let stored = try? JSONDecoder().decode([Macro].self, from: data)
        else {
            return [:]
        }
        return Dictionary(uniqueKeysWithValues: stored.map { ($0.id, $0) })
    }

    private static func bool(from field: String) -> Bool? {
        switch field.lowercased() {
        case "1", "true": true
        case "0", "false": false
        default: nil
        }
    }
}
