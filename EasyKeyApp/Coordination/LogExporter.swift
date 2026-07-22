import AppKit
import EasyEngineCore
import Foundation
import OSLog

/// Exports recent OSLog entries for the EasyKey subsystem and reveals them in Finder.
enum LogExporter {
    private static let lookbackInterval: TimeInterval = 60 * 60
    private static let maxEntries = 2000

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
        now: Date = Date()
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
            let timestamp = ISO8601DateFormatter().string(from: logEntry.date)
            lines.append("[\(timestamp)] [\(logEntry.category)] \(logEntry.composedMessage)")
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
        return fileURL
    }
}
