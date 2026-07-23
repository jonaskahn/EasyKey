import Foundation

public struct ApplicationIdentity: Codable, Equatable, Sendable {
    public var bundleIdentifier: String?
    public var path: String?
    public var name: String?

    public init(bundleIdentifier: String? = nil, path: String? = nil, name: String? = nil) {
        self.bundleIdentifier = bundleIdentifier
        self.path = path
        self.name = name
    }

    public var stableKey: String? {
        if let bundleIdentifier, !bundleIdentifier.isEmpty {
            return "bundle:\(bundleIdentifier)"
        }
        if let path, !path.isEmpty {
            return "path:\(path)"
        }
        if let name, !name.isEmpty {
            return "name:\(name)"
        }
        return nil
    }
}

public struct SmartSwitchChoice: Codable, Equatable, Sendable {
    public var language: InputLanguage
    public var encoding: EncodingTable?

    public init(language: InputLanguage, encoding: EncodingTable? = nil) {
        self.language = language
        self.encoding = encoding
    }
}

public struct SmartSwitchPreference: Codable, Equatable, Sendable, Identifiable {
    public var key: String
    public var displayName: String
    public var choice: SmartSwitchChoice
    public var lastUsedAt: Date

    public var id: String {
        key
    }

    public init(key: String, displayName: String, choice: SmartSwitchChoice, lastUsedAt: Date) {
        self.key = key
        self.displayName = displayName
        self.choice = choice
        self.lastUsedAt = lastUsedAt
    }
}

public enum SmartSwitchFocusResult: Equatable, Sendable {
    case applied(SmartSwitchChoice)
    case recorded(SmartSwitchChoice)
    case ignored
}

public enum SmartSwitchStoreError: Error, Equatable, Sendable {
    case missingApplicationIdentity
    case unknownPreference
}

private struct SmartSwitchDocument: Codable, Sendable {
    static let currentSchemaVersion = 1

    var schemaVersion: Int
    var preferences: [SmartSwitchPreference]
}

public final class SmartSwitchStore {
    private let fileURL: URL?
    private var preferencesByKey: [String: SmartSwitchPreference]

    public init(fileURL: URL? = nil) {
        self.fileURL = fileURL
        preferencesByKey = Self.load(from: fileURL)
    }

    public var preferences: [SmartSwitchPreference] {
        preferencesByKey.values.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }

    public func search(_ query: String) -> [SmartSwitchPreference] {
        guard !query.isEmpty else { return preferences }
        return preferences.filter {
            $0.displayName.localizedCaseInsensitiveContains(query) || $0.key.localizedCaseInsensitiveContains(query)
        }
    }

    public func choice(for application: ApplicationIdentity) -> SmartSwitchChoice? {
        guard let key = application.stableKey else { return nil }
        return preferencesByKey[key]?.choice
    }

    @discardableResult
    public func handleAppFocus(
        _ application: ApplicationIdentity,
        currentChoice: SmartSwitchChoice,
        now: Date = Date()
    ) throws -> SmartSwitchFocusResult {
        guard let key = application.stableKey else { throw SmartSwitchStoreError.missingApplicationIdentity }
        if var preference = preferencesByKey[key] {
            preference.lastUsedAt = now
            var candidate = preferencesByKey
            candidate[key] = preference
            try save(candidate)
            preferencesByKey = candidate
            return .applied(preference.choice)
        }
        let preference = SmartSwitchPreference(
            key: key,
            displayName: application.name ?? application.path ?? application.bundleIdentifier ?? key,
            choice: currentChoice,
            lastUsedAt: now
        )
        var candidate = preferencesByKey
        candidate[key] = preference
        try save(candidate)
        preferencesByKey = candidate
        return .recorded(currentChoice)
    }

    public func edit(key: String, choice: SmartSwitchChoice, now: Date = Date()) throws {
        guard var preference = preferencesByKey[key] else { throw SmartSwitchStoreError.unknownPreference }
        preference.choice = choice
        preference.lastUsedAt = now
        var candidate = preferencesByKey
        candidate[key] = preference
        try save(candidate)
        preferencesByKey = candidate
    }

    /// Updates the saved choice for an app when the user changes language/encoding
    /// while that app is active. No-ops if the app has no preference yet.
    @discardableResult
    public func updateChoice(
        for application: ApplicationIdentity,
        choice: SmartSwitchChoice,
        now: Date = Date()
    ) throws -> Bool {
        guard let key = application.stableKey else { throw SmartSwitchStoreError.missingApplicationIdentity }
        guard var preference = preferencesByKey[key] else { return false }
        guard preference.choice != choice else { return false }
        preference.choice = choice
        preference.lastUsedAt = now
        var candidate = preferencesByKey
        candidate[key] = preference
        try save(candidate)
        preferencesByKey = candidate
        return true
    }

    public func reset(key: String) throws {
        var candidate = preferencesByKey
        guard candidate.removeValue(forKey: key) != nil else { throw SmartSwitchStoreError.unknownPreference }
        try save(candidate)
        preferencesByKey = candidate
    }

    public func clearAll() throws {
        let candidate: [String: SmartSwitchPreference] = [:]
        try save(candidate)
        preferencesByKey = candidate
    }

    private var pendingSaveTask: Task<Void, Never>?

    public func flush() {
        pendingSaveTask?.cancel()
        pendingSaveTask = nil
        try? saveSync(preferencesByKey)
    }

    private func save(_ preferencesByKey: [String: SmartSwitchPreference]) throws {
        guard let fileURL else { return }
        pendingSaveTask?.cancel()
        let prefs = preferencesByKey
        pendingSaveTask = Task.detached(priority: .utility) { [weak self] in
            try? await Task.sleep(nanoseconds: 100_000_000)
            guard !Task.isCancelled, let self else { return }
            try? self.saveSync(prefs)
        }
    }

    private func saveSync(_ preferencesByKey: [String: SmartSwitchPreference]) throws {
        guard let fileURL else { return }
        let parent = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        let document = SmartSwitchDocument(
            schemaVersion: SmartSwitchDocument.currentSchemaVersion,
            preferences: preferencesByKey.values.sorted {
                $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
            }
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(document).write(to: fileURL, options: .atomic)
    }

    private static func load(from fileURL: URL?) -> [String: SmartSwitchPreference] {
        guard let fileURL, let data = try? Data(contentsOf: fileURL),
              let document = try? JSONDecoder().decode(SmartSwitchDocument.self, from: data),
              document.schemaVersion == SmartSwitchDocument.currentSchemaVersion
        else {
            return [:]
        }
        return Dictionary(document.preferences.map { ($0.key, $0) }, uniquingKeysWith: { _, latest in latest })
    }
}
