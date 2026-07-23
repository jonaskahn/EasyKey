import AppKit
import EasyEngineCore
import Foundation
import OSLog

/// Exports recent OSLog entries for the EasyKey subsystem and reveals them in Finder.
///
/// Log entries are filtered to safe categories (`.app`, `.keyboard`, `.settings`) by default.
/// Any sensitive credential strings matching common API key formats are automatically redacted,
/// and output files are created with restricted file permissions (`0600`).
enum LogExporter {
    private static let lookbackInterval: TimeInterval = 60 * 60
    private static let maxEntries = 2000

    /// Safe log categories allowed in standard exports.
    static let allowedCategories: Set<String> = [
        AppLog.Category.app.rawValue,
        AppLog.Category.keyboard.rawValue,
        AppLog.Category.settings.rawValue,
    ]

    /// Redacts sensitive credential patterns from log messages.
    static func redact(_ text: String) -> String {
        var redacted = text
        let patterns = [
            #"sk-[A-Za-z0-9_\-]{20,}"#,
            #"AIzaSy[A-Za-z0-9_\-]{20,}"#,
            #"x-api-key:\s*[A-Za-z0-9_\-]{10,}"#,
        ]
        for pattern in patterns {
            redacted = redacted.replacingOccurrences(of: pattern, with: "[REDACTED]", options: [.regularExpression])
        }
        return redacted
    }

    @MainActor
    static func exportAndReveal(reveal: @escaping (URL) -> Void = { NSWorkspace.shared.activateFileViewerSelecting([$0]) }) {
        let now = Date()
        Task.detached(priority: .userInitiated) {
            do {
                let url = try writeExport(now: now)
                await MainActor.run {
                    AppLog.info(.app, "Exported logs to \(url.lastPathComponent)")
                    reveal(url)
                }
            } catch {
                await MainActor.run {
                    AppLog.error(.app, "Log export failed: \(error.localizedDescription)")
                    presentExportFailure(message: error.localizedDescription)
                }
            }
        }
    }

    @MainActor
    static func presentExportFailure(message: String) {
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }
        let alert = NSAlert()
        alert.messageText = LocalizationStore.shared.string(.menuShowLogs)
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }

    static func writeExport(
        store: OSLogStore? = nil,
        fileManager: FileManager = .default,
        now: Date = Date(),
        allowedCategories: Set<String> = allowedCategories
    ) throws -> URL {
        let logStore = try store ?? OSLogStore(scope: .currentProcessIdentifier)
        let startDate = now.addingTimeInterval(-lookbackInterval)
        let position = logStore.position(date: startDate)
        let predicate = NSPredicate(format: "subsystem == %@", AppLog.subsystem)
        let entries = try logStore.getEntries(at: position, matching: predicate)

        var lines: [String] = [
            "EasyKey log export",
            "subsystem=\(AppLog.subsystem)",
            "exportedAt=\(ISO8601DateFormatter().string(from: now))",
            "lookbackSeconds=\(Int(lookbackInterval))",
            "---",
        ]
        var count = 0
        for entry in entries {
            guard let logEntry = entry as? OSLogEntryLog else { continue }
            guard logEntry.subsystem == AppLog.subsystem else { continue }
            guard allowedCategories.contains(logEntry.category) else { continue }

            let timestamp = ISO8601DateFormatter().string(from: logEntry.date)
            let sanitizedMessage = redact(logEntry.composedMessage)
            lines.append("[\(timestamp)] [\(logEntry.category)] \(sanitizedMessage)")
            count += 1
            if count >= maxEntries {
                break
            }
        }
        if count == 0 {
            lines.append("(no log entries in lookback window)")
        }

        let directory = fileManager.temporaryDirectory.appendingPathComponent("EasyKeyLogs", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let fileURL = directory.appendingPathComponent("easykey-\(formatter.string(from: now)).log")
        let payload = lines.joined(separator: "\n") + "\n"
        try payload.write(to: fileURL, atomically: true, encoding: .utf8)
        try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
        return fileURL
    }
}
