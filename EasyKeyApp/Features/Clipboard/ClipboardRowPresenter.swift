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

    static func primaryText(for entry: ClipboardEntry, imageDescription: ((String) -> String)? = nil) -> String {
        guard let item = entry.items.first else { return "" }
        switch item.kind {
        case .text:
            return normalizedTextPreview(item.preview.primaryText)
        case .image:
            let type = item.preview.typeLabel ?? item.preview.primaryText
            return imageDescription?(type) ?? "\(type) image"
        default:
            if entry.items.count > 1 {
                return "\(item.preview.primaryText) +\(entry.items.count - 1)"
            }
            return item.preview.primaryText
        }
    }

    static func metadata(for entry: ClipboardEntry, now: Date, locale: Locale = .current) -> String {
        var parts: [String] = []
        if let item = entry.items.first {
            if let typeLabel = item.preview.typeLabel {
                parts.append(typeLabel)
            }
            if let bytes = item.preview.byteCount {
                parts.append(formattedBytes(bytes, locale: locale))
            }
            if let width = item.preview.pixelWidth, let height = item.preview.pixelHeight {
                parts.append("\(width)×\(height)")
            }
        }
        if let name = entry.source?.applicationName {
            parts.append(name)
        }
        parts.append(relativeTime(from: entry.capturedAt, to: now, locale: locale))
        return parts.joined(separator: " · ")
    }

    static func formattedBytes(_ count: Int, locale: Locale = .current) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var value = Double(count)
        var index = 0
        while value >= 1000, index < units.indices.last! {
            value /= 1000
            index += 1
        }
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.maximumFractionDigits = index == 0 ? 0 : 1
        formatter.minimumFractionDigits = 0
        let number = formatter.string(from: NSNumber(value: value)) ?? String(value)
        return "\(number) \(units[index])"
    }

    static func relativeTime(from date: Date, to now: Date, locale: Locale = .current) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = locale
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
