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
            let message = "Decode failed; current settings preserved: \(error.localizedDescription)"
            diagnostic.entries.append(.init(severity: .warning, message: message))
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
            spellCheck: settings.typing.spellCheck,
            autoRestoreKeys: settings.typing.restoreInvalidWord,
            toneStyle: settings.typing.toneStyle,
            quickTelexConsonants: settings.typing.quickTelexConsonants,
            standaloneWShortcut: settings.typing.standaloneWShortcut,
            bracketShortcuts: settings.typing.bracketShortcuts,
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
        do {
            try encoded.write(to: url, options: .atomic)
        } catch {
            AppLog.error(.settings, "Failed to write settings: \(error.localizedDescription)")
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
    public var spellCheck: Bool
    public var autoRestoreKeys: Bool
    public var toneStyle: ToneStyle
    public var quickTelexConsonants: Bool
    public var standaloneWShortcut: Bool
    public var bracketShortcuts: Bool
    public var uppercaseFirstCharacter: Bool

    public init(
        inputMethod: InputMethod = .telex,
        outputEncoding: EncodingTable = .unicode,
        spellCheck: Bool = true,
        autoRestoreKeys: Bool = true,
        toneStyle: ToneStyle = .old,
        quickTelexConsonants: Bool = false,
        standaloneWShortcut: Bool = true,
        bracketShortcuts: Bool = true,
        uppercaseFirstCharacter: Bool = false
    ) {
        self.inputMethod = inputMethod
        self.outputEncoding = outputEncoding
        self.spellCheck = spellCheck
        self.autoRestoreKeys = autoRestoreKeys
        self.toneStyle = toneStyle
        self.quickTelexConsonants = quickTelexConsonants
        self.standaloneWShortcut = standaloneWShortcut
        self.bracketShortcuts = bracketShortcuts
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
