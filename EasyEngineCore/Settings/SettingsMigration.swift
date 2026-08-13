import Foundation

/// Applies per-version schema migrations to persisted settings. The
/// per-version step is currently a passthrough reserved for future field
/// migrations; the version-bump loop itself is exercised by tests.
enum SettingsMigration {
    static func migrate(_ data: Data) -> Data {
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              var schemaVersion = json["schemaVersion"] as? Int
        else {
            return data
        }

        var currentDict = json
        while schemaVersion < EasyKeySettings.currentSchemaVersion {
            currentDict = migrateStep(currentDict, from: schemaVersion, to: schemaVersion + 1)
            schemaVersion += 1
            currentDict["schemaVersion"] = schemaVersion
        }

        return (try? JSONSerialization.data(withJSONObject: currentDict, options: [.prettyPrinted, .sortedKeys])) ?? data
    }

    private static func migrateStep(_ dict: [String: Any], from _: Int, to _: Int) -> [String: Any] {
        return dict
    }
}
