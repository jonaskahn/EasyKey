# Migrating from settings schema 3–7 to schema 11

_Last reviewed: 2026-08-13_

This guide covers the settings-storage migration path in `EasyEngineCore/Settings`: any `settings.json` document written by a release before schema 8 loads into the current repository as a schema-11 document. The earliest shipped documents (0.0.1, commit `8e480af`) already carried `"schemaVersion": 3` — `EasyKeySettings.currentSchemaVersion == 3` at that commit, written by synthesized Codable; no release ever shipped a document without the marker. A document missing the key is tolerated by the current decoder (it defaults to the current schema), but that is decoder tolerance, not a state any release produced. Target: `EasyKeySettings.currentSchemaVersion == 11` on current HEAD. The migration is additive and automatic on load; the breaking changes below are the behaviors a reader must know when handling settings files or imports.

## Breaking changes, in order

Apply these in the order listed — versioning first, because every later behavior depends on the schema marker.

### Schema versioning of settings.json

**Before** (0.0.1, commit `8e480af`): the settings file at `~/Library/Application Support/EasyKey/settings.json` already carried the integer marker `"schemaVersion": 3` — `EasyKeySettings.currentSchemaVersion == 3` at that commit, written by the synthesized Codable encoder — and load attempted a strict decode of the known keys.

```swift
if let data = try? Data(contentsOf: resolvedURL),
   let decoded = try? JSONDecoder().decode(EasyKeySettings.self, from: data) {
    settings = decoded
} else {
    settings = .defaults
}
```

**After** (0.0.2+): every document carries an integer `schemaVersion`; the repository steps the document forward one version at a time until it reaches the current schema before decoding.

```swift
while schemaVersion < EasyKeySettings.currentSchemaVersion {
    currentDict = migrateStep(currentDict, from: schemaVersion, to: schemaVersion + 1)
    schemaVersion += 1
    currentDict["schemaVersion"] = schemaVersion
}
```

Schema history: 3 (0.0.1, commit `8e480af`) → 4 (0.0.2, clipboard added, commit `b6ab8c5`) → 5 (translation, commit `e0feaf6`) → 7 (provider expansion, commit `8e22c85`) → 8 (engine reimplementation, commit `3c88ddd`) → 9 (live confidence scoring, commit `f59172b`) → 10 (iOS-UniKey-like mode, commit `e9c8582`) → 11 (literal technical-token skipping, commit `d78e896`). `migrateStep` is currently a reserved no-op returning the document unchanged — every completed step so far was **field addition**, which the tolerant decoder below handles; the loop exists so a future real transformation has an ordered place to run. On write, the document is re-encoded pretty-printed with sorted keys.

### Missing root fields decode with defaults

**Before** (pre-0.0.2, strict): a document written by an older release failed to decode when a newer root key (for example `clipboard`) was absent, because `Codable` synthesis required every non-optional property.

**After** (all root fields optional on read): every root group decodes with `decodeIfPresent` and falls back to its current default, so an old document gains new groups instead of failing.

```swift
schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? Self.currentSchemaVersion
clipboard = try container.decodeIfPresent(ClipboardOptions.self, forKey: .clipboard) ?? ClipboardOptions()
```

Net effect: upgrading an app version never resets unrelated preferences, and no data-migration step is required for existing users.

### Import rejections

Settings **import** is stricter than load. A file is rejected outright when it exceeds 1 MiB (`SettingsRepository.maxImportFileBytes`), when JSON decoding fails, or when its declared schema is newer than the app supports:

```swift
guard decoded.schemaVersion <= EasyKeySettings.currentSchemaVersion else {
    throw SettingsRepositoryError.unsupportedSchemaVersion(decoded.schemaVersion)
}
```

**Before** (0.0.1, commit `8e480af`): a malformed document failed the decode and the repository **reset the current settings to defaults** — the catch branch ran `settings = .defaults; scheduleSave()` (logged "Decode failed, using defaults"). **Commit `11504af`** ("fix(settings): preserve state on bad import", 2026-07-18) is the fix that introduced preservation: the decode-failure branch stopped touching `settings`, so the current settings were kept. **After** (current): the repository throws a typed error (`importFileTooLarge`, `malformedDocument`, `unsupportedSchemaVersion`) before `settings` is touched, so the current settings are preserved either way; the Settings UI surfaces the error.

### Atomic debounced writes

**Before**: writes were issued immediately on each settings change. **After**: every mutation schedules a detached 300 ms-debounced save that serializes on a dedicated queue and writes atomically (`options: .atomic`) into `Application Support/EasyKey/settings.json`, creating the directory if needed — so rapid changes coalesce and a crash mid-write never leaves a torn file.

### SettingsDelta gating

**Before** (commit `d2b1469`, 2026-07-23, `EasyKeySettingsDeltaTests`): any settings change notified keyboard services. **After**: `SettingsDelta` compares each group between old and new settings and gates keyboard-service updates to the groups that actually changed (`schemaVersionChanged`, `inputChanged`, `typingChanged`, …), so unrelated writes no longer rebuild the keyboard pipeline.

## Verify

```bash
make test
```

Coverage you can target directly:

- `EasyKeyTests/SettingsRepositoryMigrationTests.swift` — `testSettingsMigration_BumpsSchemaVersion` feeds a `schemaVersion: 1` document into `SettingsMigration.migrate` and asserts the result carries `currentSchemaVersion`.
- `EasyKeyTests/SettingsRepositoryEdgeCaseTests.swift` — covers `testImport_FileTooLarge_Throws`, `testImportRejectsFutureSchemaAndPreservesCurrentSettings` (`unsupportedSchemaVersion(999)`), `testLoadWithInvalidJSON`, and `testSaveToReadOnlyDirectory_DoesNotCrash`.

Manual check: export settings, rewrite the exported file's `schemaVersion` to an old value (or delete the key), import it, and confirm the file on disk is rewritten with `"schemaVersion": 11` and that unrelated groups were preserved.

## Rollback

**Not supported.** There is no downgrade path: migration is forward-only and nothing writes a copy of the pre-migration file. Installing an older release over a schema-11 document does **not** fail at decode — older releases decode with synthesized `Codable`, which ignores keys it does not know, and every older decoder's known-key set is a subset of a schema-11 document, so the document decodes successfully. The actual downgrade hazard is on the next write: the older release re-encodes only the groups it knows and silently rewrites the file without newer groups (for example `clipboard` or `translation`), destroying them. The forward path is non-destructive (old groups are preserved, missing ones defaulted), but a settings document is written in place once the current release touches it.

Full version matrix: see [compatibility.md](../../reference/compatibility.md).
