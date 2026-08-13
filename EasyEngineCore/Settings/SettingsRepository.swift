import Foundation

@MainActor
public final class SettingsRepository {
    public static let maxImportFileBytes = 1_048_576

    public private(set) var settings: EasyKeySettings {
        didSet {
            onSettingsChange?(settings)
        }
    }

    public var onSettingsChange: ((EasyKeySettings) -> Void)?

    private let fileURL: URL
    private var saveTask: Task<Void, Never>?

    public init(fileURL: URL? = nil) {
        let resolvedURL = fileURL ?? SettingsRepository.defaultFileURL
        self.fileURL = resolvedURL
        if let data = try? Data(contentsOf: resolvedURL),
           let decoded = SettingsRepository.decodeSupportedSettings(from: data) {
            settings = decoded
            AppLog.info(.settings, "Loaded settings from \(resolvedURL.lastPathComponent)")
        } else {
            settings = .defaults
            AppLog.info(.settings, "Using default settings (no valid file at \(resolvedURL.lastPathComponent))")
        }
    }

    public static var defaultFileURL: URL {
        resolveDefaultFileURL(fileManager: .default)
    }

    /// Test seam: resolves the default settings file URL with an injected
    /// `FileManager` so the Application Support / Caches fallback chain is
    /// reachable from tests. Production callers use `defaultFileURL`.
    static func resolveDefaultFileURL(fileManager: FileManager) -> URL {
        let preferredParent: URL
        if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            preferredParent = appSupport
        } else if let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            AppLog.error(.settings, "Application Support unavailable; falling back to \(caches.path)")
            preferredParent = caches
        } else {
            let temp = fileManager.temporaryDirectory
            AppLog.error(.settings, "Application Support and Caches unavailable; falling back to \(temp.path)")
            preferredParent = temp
        }
        let dir = preferredParent.appendingPathComponent("EasyKey", isDirectory: true)
        do {
            try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        } catch {
            AppLog.error(.settings, "Failed to create settings directory: \(error.localizedDescription)")
        }
        return dir.appendingPathComponent("settings.json")
    }

    public func update(_ transform: (inout EasyKeySettings) -> Void) {
        var updated = settings
        transform(&updated)
        settings = updated
        scheduleSave()
    }

    public func reset() {
        settings = .defaults
        scheduleSave()
        AppLog.info(.settings, "Settings reset to defaults")
    }

    public func export(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(settings)
        try data.write(to: url, options: .atomic)
        AppLog.info(.settings, "Exported settings to \(url.lastPathComponent)")
    }

    public func `import`(from url: URL) throws -> ImportDiagnostics {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? NSNumber
        if let fileSize, fileSize.intValue > Self.maxImportFileBytes {
            AppLog.error(.settings, "Import rejected: file exceeds \(Self.maxImportFileBytes) bytes")
            throw SettingsRepositoryError.importFileTooLarge
        }

        let data = try Data(contentsOf: url)
        var diagnostic = ImportDiagnostics()
        let decoded: EasyKeySettings
        do {
            decoded = try JSONDecoder().decode(EasyKeySettings.self, from: data)
        } catch {
            let message = "Decode failed: \(error.localizedDescription)"
            AppLog.error(.settings, message)
            throw SettingsRepositoryError.malformedDocument(error.localizedDescription)
        }
        guard decoded.schemaVersion <= EasyKeySettings.currentSchemaVersion else {
            AppLog.error(.settings, "Import rejected: unsupported settings schema version \(decoded.schemaVersion)")
            throw SettingsRepositoryError.unsupportedSchemaVersion(decoded.schemaVersion)
        }
        settings = SettingsRepository.migrate(decoded)
        diagnostic.entries.append(.init(severity: .info, message: "Settings imported successfully"))
        scheduleSave()
        AppLog.info(.settings, "Imported settings from \(url.lastPathComponent)")
        return diagnostic
    }

    public func load() {
        if let data = try? Data(contentsOf: fileURL),
           let decoded = SettingsRepository.decodeSupportedSettings(from: data) {
            settings = decoded
        } else {
            settings = .defaults
            AppLog.notice(.settings, "Reload fell back to defaults")
        }
    }

    public func saveNow() async {
        saveTask?.cancel()
        saveTask = nil
        Self.performAtomicWrite(data: settings, to: fileURL)
    }

    private func scheduleSave() {
        saveTask?.cancel()
        let current = settings
        let url = fileURL
        saveTask = Task.detached(priority: .utility) {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            Self.performAtomicWrite(data: current, to: url)
        }
    }

    private nonisolated static let writeQueue = DispatchQueue(label: "one.ifelse.easykey.settings-write", qos: .utility)

    nonisolated static func performAtomicWrite(data: EasyKeySettings, to url: URL) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let encoded = try? encoder.encode(data) else {
            AppLog.error(.settings, "Failed to encode settings for write")
            return
        }
        writeQueue.sync {
            let parent = url.deletingLastPathComponent()
            do {
                try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
                try encoded.write(to: url, options: .atomic)
            } catch {
                AppLog.error(.settings, "Failed to write settings: \(error.localizedDescription)")
            }
        }
    }

    private static func migrate(_ settings: EasyKeySettings) -> EasyKeySettings {
        var migrated = settings
        if migrated.schemaVersion < EasyKeySettings.currentSchemaVersion {
            migrated.schemaVersion = EasyKeySettings.currentSchemaVersion
        }
        return migrated
    }

    private static func decodeSupportedSettings(from data: Data) -> EasyKeySettings? {
        let migratedData = SettingsMigration.migrate(data)
        guard let decoded = try? JSONDecoder().decode(EasyKeySettings.self, from: migratedData),
              decoded.schemaVersion <= EasyKeySettings.currentSchemaVersion
        else {
            return nil
        }
        return migrate(decoded)
    }
}

public enum SettingsRepositoryError: Error, Equatable, Sendable {
    case importFileTooLarge
    case unsupportedSchemaVersion(Int)
    case malformedDocument(String)
}

public struct ImportDiagnostics: Sendable {
    public struct Entry: Sendable {
        public enum Severity: Sendable {
            case info, warning, error
        }

        public let severity: Severity
        public let message: String
    }

    public var entries: [Entry] = []

    public init() {}
}
