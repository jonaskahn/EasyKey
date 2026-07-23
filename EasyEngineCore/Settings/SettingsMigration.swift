import Foundation

public enum SettingsMigration {
    public static func migrate(_ data: Data) -> Data {
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
        // Reserved for future per-version field migrations
        return dict
    }
}
