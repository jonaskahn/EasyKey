import Foundation

/// Outcome of a pin request. Pinning is refused past the hard limit so no pinned
/// entry is ever silently evicted.
public enum ClipboardPinResult: Equatable, Sendable {
    case updated
    case pinnedLimitReached
    case notFound
}

/// Deterministic in-memory clipboard history. Core owns ordering, deduplication,
/// pinning, retention, and search because those are product rules. Time-sensitive
/// commands take an injected `now` so tests own the clock.
public struct ClipboardHistory: Equatable, Sendable {
    /// Hard cap on pinned entries. Pinned entries bypass age/count pruning but
    /// never exceed this count.
    public static let maximumPinnedEntries = 25

    public private(set) var entries: [ClipboardEntry]

    public init(entries: [ClipboardEntry] = []) {
        self.entries = entries
        sort()
    }

    public var pinnedCount: Int {
        entries.reduce(0) { $0 + ($1.isPinned ? 1 : 0) }
    }

    /// Inserts a freshly captured event at the top. A same-fingerprint duplicate is
    /// replaced in place; if that duplicate was pinned, the new event inherits its
    /// pin state and original `pinnedAt`, preserving pin order.
    public mutating func insert(_ entry: ClipboardEntry, options: ClipboardOptions, now: Date) {
        var incoming = entry
        incoming.capturedAt = now
        if let existing = entries.first(where: { $0.fingerprint == entry.fingerprint }) {
            if existing.isPinned {
                incoming.isPinned = true
                incoming.pinnedAt = existing.pinnedAt
            }
            entries.removeAll { $0.fingerprint == entry.fingerprint }
        }
        entries.append(incoming)
        sort()
        prune(options: options, now: now)
    }

    @discardableResult
    public mutating func setPinned(_ pinned: Bool, entryID: UUID, now: Date) -> ClipboardPinResult {
        guard let index = entries.firstIndex(where: { $0.id == entryID }) else {
            return .notFound
        }
        if pinned {
            if entries[index].isPinned {
                return .updated
            }
            guard pinnedCount < Self.maximumPinnedEntries else {
                return .pinnedLimitReached
            }
            entries[index].isPinned = true
            entries[index].pinnedAt = now
        } else {
            entries[index].isPinned = false
            entries[index].pinnedAt = nil
        }
        sort()
        return .updated
    }

    public mutating func remove(entryID: UUID) {
        entries.removeAll { $0.id == entryID }
    }

    public mutating func clearUnpinned() {
        entries.removeAll { !$0.isPinned }
    }

    public mutating func clear() {
        entries.removeAll()
    }

    /// Removes expired then surplus unpinned entries. Pinned entries are preserved.
    public mutating func prune(options: ClipboardOptions, now: Date) {
        if options.retentionDays > 0 {
            let cutoff = now.addingTimeInterval(-Double(options.retentionDays) * 86400)
            entries.removeAll { !$0.isPinned && $0.capturedAt < cutoff }
        }
        let limit = max(0, options.maximumEntryCount)
        var keptUnpinned = 0
        entries = entries.filter { entry in
            if entry.isPinned {
                return true
            }
            keptUnpinned += 1
            return keptUnpinned <= limit
        }
    }

    /// Filtered view for a search query. An empty/whitespace query returns all
    /// entries in canonical order. Matching is localized and case-insensitive.
    public func entries(matching query: String) -> [ClipboardEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return entries }
        return entries.filter { $0.searchableText.localizedCaseInsensitiveContains(trimmed) }
    }

    private mutating func sort() {
        entries.sort { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned
            }
            if lhs.isPinned {
                return (lhs.pinnedAt ?? .distantPast) > (rhs.pinnedAt ?? .distantPast)
            }
            return lhs.capturedAt > rhs.capturedAt
        }
    }
}
