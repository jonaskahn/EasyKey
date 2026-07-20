import EasyEngineCore
import Foundation

enum ClipboardActionError: Equatable {
    case unavailable
    case targetTerminated
    case accessibilityDenied
}

/// Orchestrates a selection action: write the entry through the shared writer,
/// close the panel, reactivate the previously focused app, then synthesize paste
/// only when appropriate. Command-C style copy never synthesizes paste. All
/// AppKit effects are injected so ordering and fallbacks are testable.
@MainActor
final class ClipboardActionCoordinator {
    private let writeEntry: (ClipboardEntry) throws -> Void
    private let closePanel: () -> Void
    private let reactivatePrevious: () -> Bool
    private let synthesizePaste: () -> Bool

    private(set) var lastError: ClipboardActionError?

    init(
        writeEntry: @escaping (ClipboardEntry) throws -> Void,
        closePanel: @escaping () -> Void,
        reactivatePrevious: @escaping () -> Bool,
        synthesizePaste: @escaping () -> Bool
    ) {
        self.writeEntry = writeEntry
        self.closePanel = closePanel
        self.reactivatePrevious = reactivatePrevious
        self.synthesizePaste = synthesizePaste
    }

    func perform(_ entry: ClipboardEntry, action: ClipboardSelectionAction) {
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

    private func pasteImmediately(_ entry: ClipboardEntry) {
        guard write(entry) else { return }
        closePanel()
        guard reactivatePrevious() else {
            lastError = .targetTerminated
            return
        }
        if !synthesizePaste() {
            lastError = .accessibilityDenied
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
}
