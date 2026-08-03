---
id: "data_handling"
title: "Data Handling"
docforge_provenance:
  schema: "2.0"
  doc_id: "data_handling"
  path: "docs/security/data-handling.md"
  generated_at: "2026-08-03T08:45:41Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "deep-dive"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "keystroke-input-transient"
      sources:
        - path: "EasyKeyKit/Keyboard/KeyboardEventTap.swift"
          git_blob: "2df63cc191f2509471b02cfad60b8a3113be0933"
          role: "code"
        - path: "EasyKeyKit/Keyboard/KeyboardInputPipeline.swift"
          git_blob: "e18b247e57d0c2fe0d761cdff8230d5f4d4e7a2c"
          role: "code"
        - path: "EasyKeyKit/KeyboardService.swift"
          git_blob: "3d2db069ec81fb639d6eb9a6fc69121580854d31"
          role: "code"
      unresolved: []
    - id: "clipboard-history-and-payloads-confidential"
      sources:
        - path: "EasyEngineCore/Clipboard/ClipboardOptions.swift"
          git_blob: "f1409bbfebea82ad1d8e76ec6d75612f0b1b7a93"
          role: "code"
        - path: "EasyKeyApp/Features/Clipboard/ClipboardMonitor.swift"
          git_blob: "b554c2a511999b5eab5b545232bd3fc2c8cedf76"
          role: "code"
        - path: "EasyKeyApp/Features/Clipboard/PasteboardSnapshot.swift"
          git_blob: "cf479dc1990e259036d4ce3784f8539195e38f41"
          role: "code"
        - path: "EasyKeyApp/Features/Clipboard/ClipboardHistoryModel.swift"
          git_blob: "6fe0b0f894f3d17c9546f48eb32f497701ac0ede"
          role: "code"
        - path: "EasyKeyApp/Features/Clipboard/ClipboardPersistence.swift"
          git_blob: "2f2f6e1c7c03071c95010c565309b55a06b15c34"
          role: "code"
      unresolved: []
    - id: "translation-source-text-and-results-confidential-transient"
      sources:
        - path: "EasyKeyApp/Features/Translation/AppTranslationRuntime.swift"
          git_blob: "c4df84fdde3f664cd167d91ce3a64b387e6ef30e"
          role: "code"
        - path: "EasyKeyApp/Features/Translation/TranslationProviding.swift"
          git_blob: "5c70817f7b83a111395b771d818f235db64e39c1"
          role: "code"
        - path: "EasyKeyApp/Features/Translation/GoogleTranslationProvider.swift"
          git_blob: "a58ea2ffd3149408365009e036353d1c130b3056"
          role: "code"
        - path: "EasyEngineCore/Translation/TranslationOptions.swift"
          git_blob: "1c0c39a3d9bc405c47c447ac21c90b0d9545d89f"
          role: "code"
        - path: "EasyKeyApp/Features/Translation/TranslationModel.swift"
          git_blob: "dbeb3c07bd87de658d4a81c926b44de2dd18b405"
          role: "code"
        - path: "docs/_archive/PRIVACY.md"
          git_blob: "4fab52de09cef3d41e3f25c500a4ab0df475a2b1"
          role: "doc"
      unresolved: []
    - id: "cloud-translation-credentials-secret"
      sources:
        - path: "EasyKeyApp/Features/Translation/TranslationCredentialStore.swift"
          git_blob: "768aab956a8d02978101105e7a896b6d55c75376"
          role: "code"
        - path: "EasyEngineCore/Settings/SettingsRepository.swift"
          git_blob: "f718fcf9ea3a84f0aa770650c15c8c059e450a19"
          role: "code"
      unresolved: []
    - id: "clipboard-persistence-key-secret"
      sources:
        - path: "EasyKeyApp/Features/Clipboard/ClipboardKeyStore.swift"
          git_blob: "8308409cb0bb907254e169b15dd74b9304399ed3"
          role: "code"
        - path: "EasyKeyApp/Features/Clipboard/ClipboardPersistence.swift"
          git_blob: "2f2f6e1c7c03071c95010c565309b55a06b15c34"
          role: "code"
      unresolved: []
    - id: "settings-macros-and-preferences-internal"
      sources:
        - path: "EasyEngineCore/Settings/SettingsRepository.swift"
          git_blob: "f718fcf9ea3a84f0aa770650c15c8c059e450a19"
          role: "code"
      unresolved: []
    - id: "diagnostic-logs-and-exports-internal"
      sources:
        - path: "EasyEngineCore/Diagnostics/AppLog.swift"
          git_blob: "5fc4b67c2fd3e17d5ba285cabad24e5e112951fa"
          role: "code"
        - path: "EasyKeyApp/Coordination/LogExporter.swift"
          git_blob: "3d1a645db3bcb360f93a997575bcae4bb88071c9"
          role: "code"
      unresolved: []
    - id: "compliance-evidence"
      sources:
        - path: "README.md"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
          role: "doc"
        - path: "docs/_archive/PRIVACY.md"
          git_blob: "4fab52de09cef3d41e3f25c500a4ab0df475a2b1"
          role: "doc"
      unresolved: []
---
# Data handling

_Last reviewed: 2026-08-03_

This document classifies the data classes the repository actually distinguishes
and states, per class, the lifecycle the code implements. Retention authority
and deletion execution are cited per row; where a duration or processor is not
evidenced, it is stated as a limit rather than claimed. Threat responses are
owned by [threat-model.md](threat-model.md); permissions by
[permissions.md](permissions.md).

## Keystroke input (transient)

| Stage | Behavior |
|---|---|
| Collected | Session-level CGEvent tap (`CGEvent.tapCreate`, `.cgSessionEventTap`) observing key down/up, flags, and mouse events, installed only after `AXIsProcessTrusted()`; the tap is present regardless of the frontmost application, so all keystrokes pass through it |
| Used | Vietnamese engine transforms, macro expansion, and shortcut handling in `KeyboardInputPipeline`; composed text is passed to the frontmost application; no keystroke content is stored or logged (diagnostics record latency and disposition only) |
| Retained | Not retained; composition state lives in the engine session and is reset on application switch, reset commands, or `resetSession()` |
| Deleted | `resetSession()` / `resetComposition()` clear engine state, encoded units, and macro trigger buffers; process exit clears all memory |

**Access:** the EasyKey process only, via the system event tap; any other
Accessibility-trusted process has the same OS-level visibility.

## Clipboard history and payloads (confidential)

| Stage | Behavior |
|---|---|
| Collected | `NSPasteboard` polling every 0.3 s while capture is enabled; capture defaults to off (`ClipboardOptions.isCaptureEnabled = false`); events carrying Concealed/Transient/AutoGenerated or password-manager markers are rejected before any payload read; per-event cap 10 MiB, retained cap 100 MiB |
| Used | Search, pin, copy, and paste through the clipboard panel; payloads are referenced by opaque keys; in-memory history is the single live store (`ClipboardHistoryModel`) |
| Retained | Memory-only by default (`persistsHistory = false`); when persistence is enabled, the manifest and payloads are sealed with AES-GCM under a Keychain-held key in `Application Support/EasyKey`; retention defaults to 100 entries and 7 days with pinned entries (max 25) exempt from pruning |
| Deleted | `clearAll()` calls `deleteAll()`, which removes the persistence directory and deletes the Keychain key; disabling persistence triggers the same deletion; per-entry remove, unpinned clear, age/count pruning, and orphan-payload removal all delete immediately |

**Access:** the app process in memory; on disk, ciphertext is readable by local
users but not decryptable without the device-only, non-synchronizing Keychain
key.

## Translation source text and results (confidential, transient)

| Stage | Behavior |
|---|---|
| Collected | Only from EasyKey translation surfaces (translation editor, menu popover, Option+A panel) as `request.sourceText`; general keyboard input is never submitted; first use of each cloud provider requires a disclosure prompt |
| Used | Submitted directly to the selected provider over the validated HTTPS endpoint; results rendered in the translation panel; no intermediate service |
| Retained | Not persisted to disk; an in-memory session (source text, result) survives panel close under the default `sessionPersistence = .keepUntilRestart` and is held until the app restarts |
| Deleted | Nothing stored on disk to delete; the in-memory session is dropped on panel close only when `sessionPersistence = .clearOnClose` — the default `.keepUntilRestart` clears it at app restart (`AppTranslationRuntime.handleSurfaceClosed` → `TranslationModel.clearSession`) |

**Access:** the selected provider, per its terms (retention on the provider
side is not evidenced here and is out of repository scope); the app keeps no
persisted copy.

## Cloud translation credentials (secret)

| Stage | Behavior |
|---|---|
| Collected | User-entered API key per provider in Translation settings; validated against fixed provider endpoints (validation does not submit source text) |
| Used | Request authentication headers (`x-api-key`, `Authorization`, `x-goog-api-key`) built by the provider adapters |
| Retained | Keychain items, one account per provider under service `one.ifelse.easykey.translation`, `WhenUnlockedThisDeviceOnly`, `kSecAttrSynchronizable = false`; never written to settings JSON, logs, or exports |
| Deleted | `deleteCredential(for:)` deletes the Keychain item; the settings UI exposes per-provider deletion |

**Access:** the app process via `SecItem`; the items are excluded from
synchronization and bound to this device.

## Clipboard persistence key (secret)

| Stage | Behavior |
|---|---|
| Collected | Generated on first persisted save as a 256-bit `SymmetricKey` and stored via `SecItemAdd` |
| Used | AES-GCM seal and open of the history manifest and payload files |
| Retained | Keychain item `one.ifelse.easykey.clipboard`/`history-key`, `WhenUnlockedThisDeviceOnly`, non-synchronizing, for as long as persistence is enabled |
| Deleted | `deleteAll()` deletes the key; disabling persistence deletes it as part of the same transition |

**Access:** the app process only; the key never leaves the device.

## Settings, macros, and preferences (internal)

| Stage | Behavior |
|---|---|
| Collected | User choices written as JSON (`settings.json`, `macros.json`, `smart-switch.json`) under `Application Support/EasyKey`; settings support file import/export with a 1 MiB import cap |
| Used | Runtime configuration of the engine, clipboard options, translation, launch-at-login, and compatibility lists |
| Retained | Until changed, reset, or replaced by import; no explicit retention policy beyond the app's own writes |
| Deleted | `reset()` restores defaults; users may delete the files; import replaces the current settings document |

**Access:** plain JSON readable by the local user and their processes; contains
no credentials (API keys and keys are Keychain-only) and no clipboard content.

## Diagnostic logs and exports (internal)

| Stage | Behavior |
|---|---|
| Collected | OSLog entries under subsystem `one.ifelse.easykey` across nine categories; debug/info/notice messages are marked `privacy: .private`; no clipboard content is ever logged |
| Used | Debugging; the menu-bar "Show Logs" action exports a one-hour, 2000-entry window restricted to app/keyboard/settings categories with credential-like patterns redacted |
| Retained | System-managed unified logging; the app holds no own log store |
| Deleted | System truncation governs; export files are written to the temporary directory with 0600 permissions |

**Access:** unified logging is readable by local users on macOS; exports are
permission-restricted and exclude translation, engine, and update categories.

## Compliance evidence

The repository evidences the following, and nothing beyond it:

- No analytics or telemetry collection ([product overview](../product/overview.md) Private by
  Design, [Privacy](data-handling.md)).
- Device-only, non-synchronizing Keychain items for credentials and keys.
- AES-GCM authenticated encryption with key deletion on clear and on
  persistence disable.
- Opt-in capture with memory-only default and sensitive-marker rejection.
- Log export redaction and permission restriction.
- No compliance posture (GDPR, HIPAA, SOC 2, or similar) is claimed or
  evidenced anywhere in the repository.

Limits: provider-side handling and retention of submitted translation text are
governed by provider terms (links in `docs/PRIVACY.md`); nothing in this
repository controls or evidences them.
