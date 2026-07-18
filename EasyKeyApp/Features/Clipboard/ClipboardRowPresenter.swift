import EasyEngineCore
import Foundation

/// Converts Core metadata into display strings without touching the restoration
/// payload. Normalization here is display-only.
enum ClipboardRowPresenter {
    static func symbolName(for kind: ClipboardContentKind) -> String {
        switch kind {
        case .text: "text.alignleft"
        case .url: "link"
        case .image: "photo"
        case .file: "doc"
        case .video: "film"
        case .mixed: "square.on.square"
        }
    }

    /// First two meaningful lines of text, whitespace collapsed for display only.
    static func normalizedTextPreview(_ text: String, maxLines: Int = 2) -> String {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return lines.prefix(maxLines).joined(separator: "\n")
    }

    static func primaryText(for entry: ClipboardEntry) -> String {
        guard let item = entry.items.first else { return "" }
        switch item.kind {
        case .text:
            return normalizedTextPreview(item.preview.primaryText)
        default:
            if entry.items.count > 1 {
                return "\(item.preview.primaryText) +\(entry.items.count - 1)"
            }
            return item.preview.primaryText
        }
    }

    static func metadata(for entry: ClipboardEntry, now: Date) -> String {
        var parts: [String] = []
        if let item = entry.items.first {
            if let typeLabel = item.preview.typeLabel {
                parts.append(typeLabel)
            }
            if let bytes = item.preview.byteCount {
                parts.append(formattedBytes(bytes))
            }
            if let width = item.preview.pixelWidth, let height = item.preview.pixelHeight {
                parts.append("\(width)×\(height)")
            }
        }
        if let name = entry.source?.applicationName {
            parts.append(name)
        }
        parts.append(relativeTime(from: entry.capturedAt, to: now))
        return parts.joined(separator: " · ")
    }

    static func formattedBytes(_ count: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(count))
    }

    static func relativeTime(from date: Date, to now: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: now)
    }

    static func isUnavailable(_ entry: ClipboardEntry) -> Bool {
        entry.items.contains { item in
            item.representations.contains { representation in
                if case let .fileURL(url) = representation {
                    return !FileManager.default.fileExists(atPath: url.path)
                }
                return false
            }
        }
    }
}
