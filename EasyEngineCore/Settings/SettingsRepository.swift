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
    private let saveDebounceNanos: UInt64 = 300_000_000

    public init(fileURL: URL? = nil) {
        let resolvedURL = fileURL ?? SettingsRepository.defaultFileURL
        self.fileURL = resolvedURL
        if let data = try? Data(contentsOf: resolvedURL),
           let decoded = try? JSONDecoder().decode(EasyKeySettings.self, from: data) {
            settings = SettingsRepository.migrate(decoded)
            AppLog.info(.settings, "Loaded settings from \(resolvedURL.lastPathComponent)")
        } else {
            settings = .defaults
            AppLog.info(.settings, "Using default settings (no valid file at \(resolvedURL.lastPathComponent))")
        }
    }

    public static var defaultFileURL: URL {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let preferredParent = appSupport
            ?? fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        if appSupport == nil {
            AppLog.error(.settings, "Application Support unavailable; falling back to \(preferredParent.path)")
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
            let message = "Decode failed, using defaults: \(error.localizedDescription)"
            diagnostic.entries.append(.init(severity: .warning, message: message))
            settings = .defaults
            scheduleSave()
            AppLog.error(.settings, message)
            return diagnostic
        }
        settings = SettingsRepository.migrate(decoded)
        diagnostic.entries.append(.init(severity: .info, message: "Settings imported successfully"))
        scheduleSave()
        AppLog.info(.settings, "Imported settings from \(url.lastPathComponent)")
        return diagnostic
    }

    public func load() {
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode(EasyKeySettings.self, from: data) {
            settings = SettingsRepository.migrate(decoded)
        } else {
            settings = .defaults
            AppLog.notice(.settings, "Reload fell back to defaults")
        }
    }

    public func saveNow() async {
        saveTask?.cancel()
        await Self.performAtomicWrite(data: settings, to: fileURL)
    }

    public var configurationSnapshot: EngineConfiguration {
        EngineConfiguration(
            inputMethod: settings.input.inputMethod,
            outputEncoding: settings.input.encoding,
            autoRestoreKeys: settings.typing.restoreInvalidWord,
            modernStyle: settings.typing.spellingModernization,
            quickTelex: settings.typing.quickTelex,
            uppercaseFirstCharacter: settings.typing.uppercaseFirstCharacter
        )
    }

    private func scheduleSave() {
        saveTask?.cancel()
        let current = settings
        let url = fileURL
        saveTask = Task {
            try? await Task.sleep(nanoseconds: saveDebounceNanos)
            guard !Task.isCancelled else { return }
            await Self.performAtomicWrite(data: current, to: url)
        }
    }

    private static func performAtomicWrite(data: EasyKeySettings, to url: URL) async {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let encoded = try? encoder.encode(data) else {
            AppLog.error(.settings, "Failed to encode settings for write")
            return
        }
        let parent = url.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        } catch {
            AppLog.error(.settings, "Failed to create settings parent directory: \(error.localizedDescription)")
            return
        }
        let tempURL = url.appendingPathExtension("tmp")
        do {
            try encoded.write(to: tempURL, options: .atomic)
            _ = try? FileManager.default.removeItem(at: url)
            try FileManager.default.moveItem(at: tempURL, to: url)
        } catch {
            AppLog.error(.settings, "Failed to write settings: \(error.localizedDescription)")
            try? FileManager.default.removeItem(at: tempURL)
        }
    }

    private static func migrate(_ settings: EasyKeySettings) -> EasyKeySettings {
        var migrated = settings
        if migrated.schemaVersion < EasyKeySettings.currentSchemaVersion {
            migrated.schemaVersion = EasyKeySettings.currentSchemaVersion
        }
        return migrated
    }
}

public enum SettingsRepositoryError: Error, Equatable, Sendable {
    case importFileTooLarge
}

public struct EngineConfiguration: Equatable, Sendable {
    public var inputMethod: InputMethod
    public var outputEncoding: EncodingTable
    public var autoRestoreKeys: Bool
    public var modernStyle: Bool
    public var quickTelex: Bool
    public var uppercaseFirstCharacter: Bool

    public init(
        inputMethod: InputMethod = .telex,
        outputEncoding: EncodingTable = .unicode,
        autoRestoreKeys: Bool = true,
        modernStyle: Bool = false,
        quickTelex: Bool = false,
        uppercaseFirstCharacter: Bool = false
    ) {
        self.inputMethod = inputMethod
        self.outputEncoding = outputEncoding
        self.autoRestoreKeys = autoRestoreKeys
        self.modernStyle = modernStyle
        self.quickTelex = quickTelex
        self.uppercaseFirstCharacter = uppercaseFirstCharacter
    }
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
