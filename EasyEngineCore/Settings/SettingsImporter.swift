import Foundation

public struct SettingsImportResult: Sendable {
    public struct Entry: Sendable {
        public enum Kind: Sendable {
            case mapped(String)
            case defaulted(String)
            case skipped(String)
        }

        public let kind: Kind
        public let key: String
    }

    public private(set) var entries: [Entry] = []
    public var settings: EasyKeySettings

    public init(defaults: EasyKeySettings = .defaults) {
        settings = defaults
    }

    public mutating func addMapped(key: String, description: String) {
        entries.append(Entry(kind: .mapped(description), key: key))
    }

    public mutating func addDefaulted(key: String, description: String) {
        entries.append(Entry(kind: .defaulted(description), key: key))
    }

    public mutating func addSkipped(key: String, reason: String) {
        entries.append(Entry(kind: .skipped(reason), key: key))
    }
}

public enum SettingsImporter {
    public static let maxPlistFileBytes = 1_048_576

    public static func `import`(fromPlistAt url: URL) throws -> SettingsImportResult {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        if let size = attributes[.size] as? NSNumber, size.intValue > maxPlistFileBytes {
            AppLog.error(.settings, "Legacy plist import rejected: file exceeds \(maxPlistFileBytes) bytes")
            throw SettingsImporterError.fileTooLarge
        }
        let data = try Data(contentsOf: url)
        return try importFromPlistData(data)
    }

    public static func importFromPlistData(_ data: Data) throws -> SettingsImportResult {
        guard data.count <= maxPlistFileBytes else {
            AppLog.error(.settings, "Legacy plist import rejected: payload exceeds \(maxPlistFileBytes) bytes")
            throw SettingsImporterError.fileTooLarge
        }
        guard let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            AppLog.error(.settings, "Legacy plist import failed: root is not a dictionary")
            throw SettingsImporterError.notADictionary
        }
        let result = mapPlist(plist)
        AppLog.info(.settings, "Legacy plist import mapped \(result.entries.count) keys")
        return result
    }

    // MARK: - Mapping

    private static func mapPlist(_ plist: [String: Any]) -> SettingsImportResult {
        var result = SettingsImportResult()

        mapInputMethod(plist, into: &result)
        mapEncoding(plist, into: &result)
        mapBoolFlag(plist, key: "ModernOrthography", target: \.typing.spellingModernization, into: &result)
        mapBoolFlag(plist, key: "QuickTelex", target: \.typing.quickTelex, into: &result)
        mapBoolFlag(plist, key: "RestoreKeyIfInvalid", target: \.typing.restoreInvalidWord, into: &result)
        mapBoolFlag(plist, key: "AllowFZWJ", target: \.typing.allowZFWJ, into: &result)
        mapBoolFlag(plist, key: "UppercaseFirstChar", target: \.typing.uppercaseFirstCharacter, into: &result)
        mapBoolFlag(plist, key: "RunOnStartup", target: \.system.launchAtLogin, into: &result)
        mapBoolFlag(plist, key: "GrayIcon", target: \.system.grayMenuIcon, into: &result)
        mapBoolFlag(plist, key: "ShowDockIcon", target: \.system.showDockIcon, into: &result)
        mapBoolFlag(plist, key: "MacroEnabled", target: \.macro.enabled, into: &result)
        mapBoolFlag(plist, key: "SmartSwitchEnabled", target: \.smartSwitch.enabled, into: &result)
        mapBoolFlag(plist, key: "CheckForUpdates", target: \.system.checkForUpdates, into: &result)

        reportUnmappedKeys(plist, mapped: Set(result.entries.map(\.key)), into: &result)
        return result
    }

    private static func mapInputMethod(_ plist: [String: Any], into result: inout SettingsImportResult) {
        let key = "InputMethod"
        guard let raw = plist[key] as? Int else {
            result.addDefaulted(key: key, description: "Input method not found, using Telex")
            return
        }
        let method: InputMethod
        switch raw {
        case 0: method = .telex
        case 1: method = .vni
        case 2: method = .simpleTelex
        default:
            result.addDefaulted(key: key, description: "Unknown input method value \(raw), using Telex")
            return
        }
        result.settings.input.inputMethod = method
        result.addMapped(key: key, description: "Input method: \(method.rawValue)")
    }

    private static func mapEncoding(_ plist: [String: Any], into result: inout SettingsImportResult) {
        let key = "Encoding"
        guard let raw = plist[key] as? Int else {
            result.addDefaulted(key: key, description: "Encoding not found, using Unicode")
            return
        }
        let encoding: EncodingTable
        switch raw {
        case 0: encoding = .unicode
        case 1: encoding = .unicodeCombining
        case 2: encoding = .tcvn3
        case 3: encoding = .vniWindows
        case 4: encoding = .cp1258
        default:
            result.addDefaulted(key: key, description: "Unknown encoding value \(raw), using Unicode")
            return
        }
        result.settings.input.encoding = encoding
        result.addMapped(key: key, description: "Encoding: \(encoding.rawValue)")
    }

    private static func mapBoolFlag(
        _ plist: [String: Any],
        key: String,
        target: WritableKeyPath<EasyKeySettings, Bool>,
        into result: inout SettingsImportResult
    ) {
        guard let value = plist[key] as? Bool else {
            result.addDefaulted(key: key, description: "Flag not found, keeping default")
            return
        }
        result.settings[keyPath: target] = value
        result.addMapped(key: key, description: "\(key): \(value)")
    }

    private static func reportUnmappedKeys(
        _ plist: [String: Any],
        mapped: Set<String>,
        into result: inout SettingsImportResult
    ) {
        let knownNonSettingKeys: Set = [
            "SUEnableAutomaticChecks", "SUFeedURL", "SUPublicEDKey",
            "CFBundleVersion", "CFBundleShortVersionString",
        ]
        for key in plist.keys.sorted() where !mapped.contains(key) && !knownNonSettingKeys.contains(key) {
            result.addSkipped(key: key, reason: "Unrecognized key, ignored")
        }
    }
}

public enum SettingsImporterError: Error, Equatable, Sendable {
    case notADictionary
    case fileTooLarge
}
