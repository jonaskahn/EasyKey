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
}

/// The single boundary for every EasyKey-authored pasteboard write. Updates
/// suppression state before touching `NSPasteboard` so capture cannot race.
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

    /// Writes the converter output, preserving an optional HTML representation.
    func copyConvertedText(_ text: String, preservingHTML html: Data?) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        if let html {
            pasteboard.setData(html, forType: .html)
        }
        suppressor.markWritten(changeCount: pasteboard.changeCount)
    }

    /// Restores all representations of a history entry in original item order.
    /// Throws if a required binary payload or file reference is unavailable.
    func copy(_ entry: ClipboardEntry) throws {
        let items = try makeItems(for: entry)
        pasteboard.clearContents()
        pasteboard.writeObjects(items)
        suppressor.markWritten(changeCount: pasteboard.changeCount)
    }

    private func makeItems(for entry: ClipboardEntry) throws -> [NSPasteboardItem] {
        var pasteboardItems: [NSPasteboardItem] = []
        for item in entry.items {
            let pasteboardItem = NSPasteboardItem()
            for representation in item.representations {
                switch representation {
                case let .string(typeIdentifier, value):
                    pasteboardItem.setString(value, forType: NSPasteboard.PasteboardType(typeIdentifier))
                case let .fileURL(url):
                    guard FileManager.default.fileExists(atPath: url.path) else {
                        throw PasteboardWriteError.unavailableRepresentation
                    }
                    pasteboardItem.setString(url.absoluteString, forType: NSPasteboard.PasteboardType(PasteboardClassifier.fileURL))
                case let .data(typeIdentifier, payloadReference):
                    guard let data = try payloadStore?.data(for: payloadReference) else {
                        throw PasteboardWriteError.unavailableRepresentation
                    }
                    pasteboardItem.setData(data, forType: NSPasteboard.PasteboardType(typeIdentifier))
                }
            }
            pasteboardItems.append(pasteboardItem)
        }
        return pasteboardItems
    }
}
