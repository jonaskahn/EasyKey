import AppKit
import EasyEngineCore

/// Tracks the next `changeCount` produced by an EasyKey-authored pasteboard write
/// so the monitor can distinguish our own writes from external copies without
/// relying on timing.
@MainActor
final class ClipboardWriteSuppressor {
    private(set) var suppressedChangeCount: Int?

    func markWritten(changeCount: Int) {
        suppressedChangeCount = changeCount
    }

    func shouldSuppress(_ changeCount: Int) -> Bool {
        suppressedChangeCount == changeCount
    }
}

enum PasteboardWriteError: Error, Equatable {
    case unavailableRepresentation
    case writeFailed
}

/// The single boundary for every EasyKey-authored pasteboard write. Successful
/// writes update suppression state using resulting pasteboard change count.
@MainActor
final class PasteboardWriter {
    private let pasteboard: NSPasteboard
    private let suppressor: ClipboardWriteSuppressor
    private let payloadStore: ClipboardPayloadStore?

    init(
        pasteboard: NSPasteboard = .general,
        suppressor: ClipboardWriteSuppressor,
        payloadStore: ClipboardPayloadStore? = nil
    ) {
        self.pasteboard = pasteboard
        self.suppressor = suppressor
        self.payloadStore = payloadStore
    }

    /// Copies plain text, preserving the clearContents → setString → mark order
    /// so the clipboard monitor suppresses our own writes.
    @discardableResult
    func copyText(_ text: String) -> Bool {
        pasteboard.clearContents()
        guard pasteboard.setString(text, forType: .string) else { return false }
        suppressor.markWritten(changeCount: pasteboard.changeCount)
        return true
    }

    /// Writes the converter output, preserving an optional HTML representation.
    @discardableResult
    func copyConvertedText(_ text: String, preservingHTML html: Data?) -> Bool {
        pasteboard.clearContents()
        guard pasteboard.setString(text, forType: .string) else { return false }
        if let html, !pasteboard.setData(html, forType: .html) {
            return false
        }
        suppressor.markWritten(changeCount: pasteboard.changeCount)
        return true
    }

    /// Restores all representations of a history entry in original item order.
    /// Throws if a required binary payload or file reference is unavailable.
    func copy(_ entry: ClipboardEntry) throws {
        let items = try makeItems(for: entry)
        pasteboard.clearContents()
        guard pasteboard.writeObjects(items) else { throw PasteboardWriteError.writeFailed }
        suppressor.markWritten(changeCount: pasteboard.changeCount)
    }

    private func makeItems(for entry: ClipboardEntry) throws -> [NSPasteboardItem] {
        var pasteboardItems: [NSPasteboardItem] = []
        for item in entry.items {
            let pasteboardItem = NSPasteboardItem()
            for representation in item.representations {
                switch representation {
                case let .string(typeIdentifier, value):
                    guard pasteboardItem.setString(value, forType: NSPasteboard.PasteboardType(typeIdentifier)) else {
                        throw PasteboardWriteError.writeFailed
                    }
                case let .fileURL(url):
                    guard FileManager.default.fileExists(atPath: url.path) else {
                        throw PasteboardWriteError.unavailableRepresentation
                    }
                    guard pasteboardItem.setString(
                        url.absoluteString,
                        forType: NSPasteboard.PasteboardType(PasteboardClassifier.fileURL)
                    )
                    else {
                        throw PasteboardWriteError.writeFailed
                    }
                case let .data(typeIdentifier, payloadReference):
                    guard let data = try payloadStore?.data(for: payloadReference) else {
                        throw PasteboardWriteError.unavailableRepresentation
                    }
                    guard pasteboardItem.setData(data, forType: NSPasteboard.PasteboardType(typeIdentifier)) else {
                        throw PasteboardWriteError.writeFailed
                    }
                }
            }
            pasteboardItems.append(pasteboardItem)
        }
        return pasteboardItems
    }
}
