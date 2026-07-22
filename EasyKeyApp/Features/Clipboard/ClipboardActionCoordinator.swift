import Combine
import EasyEngineCore
import Foundation

enum ClipboardActionError: Equatable {
    case unavailable
    case targetTerminated
    case accessibilityDenied
    case focusChanged
}

/// Orchestrates a selection action: write the entry through the shared writer,
/// close the panel, reactivate the previously focused app, then synthesize paste
/// only when appropriate. Command-C style copy never synthesizes paste. All
/// AppKit effects are injected so ordering and fallbacks are testable.
@MainActor
final class ClipboardActionCoordinator: ObservableObject {
    private let writeEntry: (ClipboardEntry) throws -> Void
    private let closePanel: () -> Void
    private let reactivatePrevious: () -> Bool
    private let synthesizePaste: () -> Bool
    private let isTargetFocused: () -> Bool
    private let pasteDelay: Duration

    @Published private(set) var lastError: ClipboardActionError?
    private var pasteTask: Task<Void, Never>?

    init(
        writeEntry: @escaping (ClipboardEntry) throws -> Void,
        closePanel: @escaping () -> Void,
        reactivatePrevious: @escaping () -> Bool,
        synthesizePaste: @escaping () -> Bool,
        isTargetFocused: @escaping () -> Bool = { true },
        pasteDelay: Duration = .zero
    ) {
        self.writeEntry = writeEntry
        self.closePanel = closePanel
        self.reactivatePrevious = reactivatePrevious
        self.synthesizePaste = synthesizePaste
        self.isTargetFocused = isTargetFocused
        self.pasteDelay = pasteDelay
    }

    func perform(_ entry: ClipboardEntry, action: ClipboardSelectionAction) {
        pasteTask?.cancel()
        pasteTask = nil
        switch action {
        case .copyOnly:
            copyOnly(entry)
        case .pasteImmediately:
            pasteImmediately(entry)
        }
    }

    func copyOnly(_ entry: ClipboardEntry) {
        guard write(entry) else { return }
        closePanel()
    }

    func cancelPendingPaste() {
        pasteTask?.cancel()
        pasteTask = nil
    }

    private func pasteImmediately(_ entry: ClipboardEntry) {
        guard write(entry) else { return }
        closePanel()
        guard reactivatePrevious() else {
            lastError = .targetTerminated
            return
        }
        if pasteDelay == .zero {
            pasteIfFocused()
            return
        }
        let pasteDelay = self.pasteDelay
        pasteTask = Task { [weak self] in
            do {
                try await Task.sleep(for: pasteDelay)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            self?.pasteIfFocused()
        }
    }

    @discardableResult
    private func write(_ entry: ClipboardEntry) -> Bool {
        do {
            try writeEntry(entry)
            lastError = nil
            return true
        } catch {
            lastError = .unavailable
            return false
        }
    }

    private func pasteIfFocused() {
        guard isTargetFocused() else {
            lastError = .focusChanged
            return
        }
        if !synthesizePaste() {
            lastError = .accessibilityDenied
        }
    }
}
