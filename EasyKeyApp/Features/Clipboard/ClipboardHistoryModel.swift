import Combine
import EasyEngineCore
import Foundation

/// Non-content notice surfaced when a fixed safety limit blocks an operation.
enum ClipboardLimitNotice: Equatable {
    case pinnedLimitReached
    case payloadLimitReached
}

/// Observable app-layer coordinator over Core history, the session payload store,
/// and optional encrypted persistence. Owns staged capture transactions,
/// debounced saves, and the serialized secure-clear command. Knows nothing about
/// panel geometry or view text.
@MainActor
final class ClipboardHistoryModel: ObservableObject {
    @Published private(set) var history: ClipboardHistory
    @Published private(set) var persistenceError: ClipboardPersistenceError?
    @Published private(set) var limitNotice: ClipboardLimitNotice?

    let payloadStore: ClipboardPayloadStore
    private let persistence: ClipboardPersistence?
    private let now: () -> Date
    private let saveDebounce: Duration

    private var options: ClipboardOptions
    private var generation = 0
    private var saveTask: Task<Void, Never>?
    private var persistenceTransitionTask: Task<Void, Never>?

    /// Invoked with references whose payloads left the store, so decoded-thumbnail
    /// caches can invalidate alongside the source payload lifecycle.
    var onPayloadsRemoved: ((Set<String>) -> Void)?

    init(
        options: ClipboardOptions,
        payloadStore: ClipboardPayloadStore? = nil,
        persistence: ClipboardPersistence? = nil,
        now: @escaping () -> Date = { Date() },
        saveDebounce: Duration = .milliseconds(400)
    ) {
        self.options = options
        self.payloadStore = payloadStore ?? ClipboardPayloadStore()
        self.persistence = persistence
        self.now = now
        self.saveDebounce = saveDebounce
        history = ClipboardHistory()
    }

    var entryCount: Int {
        history.entries.count
    }

    var retainedByteCount: Int {
        payloadStore.totalByteCount
    }

    var currentSelectionAction: ClipboardSelectionAction {
        options.selectionAction
    }

    func payloadData(for reference: String) -> Data? {
        try? payloadStore.data(for: reference)
    }

    /// Stages one capture as a single transaction: prune, compute payload
    /// eviction, and commit history and payloads together. Any limit breach that
    /// pinned content cannot make room for rejects the candidate untouched.
    func capture(_ classified: ClassifiedClipboard) {
        var candidate = history
        candidate.insert(classified.entry, options: options, now: now())

        let referencedAfter = referencedPayloads(in: candidate)
        let orphans = payloadStore.references.subtracting(referencedAfter)
        let newReferences = Set(classified.payloads.keys).intersection(referencedAfter)
        let unstoredReferences = newReferences.subtracting(payloadStore.references)
        let newBytes = unstoredReferences.reduce(0) { $0 + (classified.payloads[$1]?.count ?? 0) }
        let projectedTotal = payloadStore.totalByteCount - payloadStore.byteCount(of: orphans) + newBytes

        guard projectedTotal <= ClipboardLimits.maximumRetainedBytes else {
            limitNotice = .payloadLimitReached
            return
        }

        payloadStore.remove(references: orphans)
        guard payloadStore.insert(classified.payloads.filter { newReferences.contains($0.key) }) else {
            limitNotice = .payloadLimitReached
            return
        }
        notifyRemoved(orphans)
        history = candidate
        scheduleSave()
    }

    func setPinned(_ pinned: Bool, entryID: UUID) {
        var candidate = history
        let result = candidate.setPinned(pinned, entryID: entryID, now: now())
        guard result == .updated else {
            if result == .pinnedLimitReached {
                limitNotice = .pinnedLimitReached
            }
            return
        }
        history = candidate
        scheduleSave()
    }

    func remove(entryID: UUID) {
        var candidate = history
        candidate.remove(entryID: entryID)
        commit(candidate)
    }

    func clearUnpinned() {
        var candidate = history
        candidate.clearUnpinned()
        commit(candidate)
    }

    func apply(_ options: ClipboardOptions) {
        let wasPersisting = self.options.persistsHistory
        if wasPersisting != options.persistsHistory {
            generation &+= 1
        }
        persistenceTransitionTask?.cancel()
        persistenceTransitionTask = nil
        self.options = options
        var candidate = history
        candidate.prune(options: options, now: now())
        commit(candidate)
        if wasPersisting, !options.persistsHistory {
            let capturedGeneration = generation
            persistenceTransitionTask = Task { [weak self] in
                await self?.disablePersistence(generation: capturedGeneration)
            }
        }
    }

    /// Serialized secure clear: stop saves, advance generation so no queued save
    /// can commit, clear memory and payloads, then delete disk state and key.
    func clearAll() async {
        saveTask?.cancel()
        saveTask = nil
        persistenceTransitionTask?.cancel()
        persistenceTransitionTask = nil
        generation &+= 1
        let removed = payloadStore.references
        history.clear()
        payloadStore.clear()
        notifyRemoved(removed)
        do {
            try await persistence?.deleteAll()
            persistenceError = nil
        } catch {
            persistenceError = error as? ClipboardPersistenceError ?? .malformedDocument
        }
    }

    func loadPersistedHistory() async {
        guard options.persistsHistory, let persistence else { return }
        do {
            let state = try await persistence.load()
            var loadedHistory = ClipboardHistory(entries: state.entries)
            loadedHistory.prune(options: options, now: now())
            loadedHistory = historyCappingPinnedEntries(loadedHistory)
            let retainedReferences = referencedPayloads(in: loadedHistory)
            let retainedPayloads = state.payloads.filter { retainedReferences.contains($0.key) }
            let removed = payloadStore.references.subtracting(retainedReferences)
            payloadStore.clear()
            guard payloadStore.insert(retainedPayloads) else {
                limitNotice = .payloadLimitReached
                return
            }
            notifyRemoved(removed)
            history = loadedHistory
            persistenceError = nil
            scheduleSave()
        } catch {
            persistenceError = error as? ClipboardPersistenceError ?? .malformedDocument
        }
    }

    private func disablePersistence(generation capturedGeneration: Int) async {
        guard capturedGeneration == generation, !options.persistsHistory, !Task.isCancelled else { return }
        saveTask?.cancel()
        saveTask = nil
        do {
            try await persistence?.deleteAll()
            if capturedGeneration == generation, !options.persistsHistory {
                persistenceError = nil
            }
        } catch is CancellationError {
            return
        } catch {
            if capturedGeneration == generation, !options.persistsHistory {
                persistenceError = error as? ClipboardPersistenceError ?? .malformedDocument
            }
        }
    }

    private func commit(_ candidate: ClipboardHistory) {
        let referencedAfter = referencedPayloads(in: candidate)
        let orphans = payloadStore.references.subtracting(referencedAfter)
        payloadStore.remove(references: orphans)
        notifyRemoved(orphans)
        history = candidate
        scheduleSave()
    }

    private func notifyRemoved(_ references: Set<String>) {
        guard !references.isEmpty else { return }
        onPayloadsRemoved?(references)
    }

    private func scheduleSave() {
        guard options.persistsHistory, let persistence else { return }
        saveTask?.cancel()
        let entries = history.entries
        let payloads = collectPayloads(for: entries)
        let capturedGeneration = generation
        let debounce = saveDebounce
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: debounce)
            guard !Task.isCancelled else { return }
            await self?.performSave(
                persistence: persistence,
                entries: entries,
                payloads: payloads,
                generation: capturedGeneration
            )
        }
    }

    /// Flushes any pending save immediately, e.g. on termination.
    func flushPendingSave() async {
        guard options.persistsHistory, let persistence else { return }
        saveTask?.cancel()
        let entries = history.entries
        let payloads = collectPayloads(for: entries)
        await performSave(persistence: persistence, entries: entries, payloads: payloads, generation: generation)
    }

    private func performSave(
        persistence: ClipboardPersistence,
        entries: [ClipboardEntry],
        payloads: [String: Data],
        generation capturedGeneration: Int
    ) async {
        guard capturedGeneration == generation else { return }
        do {
            try await persistence.save(entries: entries, payloads: payloads)
            if capturedGeneration == generation {
                persistenceError = nil
            }
        } catch {
            persistenceError = error as? ClipboardPersistenceError ?? .malformedDocument
        }
    }

    private func collectPayloads(for entries: [ClipboardEntry]) -> [String: Data] {
        var payloads: [String: Data] = [:]
        for reference in referencedPayloads(in: ClipboardHistory(entries: entries)) {
            if let data = try? payloadStore.data(for: reference) {
                payloads[reference] = data
            }
        }
        return payloads
    }

    private func referencedPayloads(in history: ClipboardHistory) -> Set<String> {
        var references: Set<String> = []
        for entry in history.entries {
            for item in entry.items {
                for representation in item.representations {
                    if case let .data(_, payloadReference) = representation {
                        references.insert(payloadReference)
                    }
                }
            }
        }
        return references
    }

    private func historyCappingPinnedEntries(_ history: ClipboardHistory) -> ClipboardHistory {
        var pinnedCount = 0
        let entries = history.entries.filter { entry in
            guard entry.isPinned else { return true }
            pinnedCount += 1
            return pinnedCount <= ClipboardLimits.maximumPinnedEntries
        }
        return ClipboardHistory(entries: entries)
    }
}
