---
id: "data_handling"
title: "Data Handling"
description: "Data classes, lifecycle, access, retention, deletion"
docforge_provenance:
  schema: "2.0"
  doc_id: "data_handling"
  path: "docs/security/data-handling.md"
  generated_at: "2026-08-13T11:23:00Z"
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
          git_blob: "afd7e07bf098c7400aaccab85a72e77fac8a936d"
          git_blob_normalized: "afd7e07bf098c7400aaccab85a72e77fac8a936d"
          role: "code"
        - path: "EasyKeyKit/Keyboard/KeyboardInputPipeline.swift"
          git_blob: "81a9d66e22797ea2b1b0632ecddfcaf73fd06757"
          git_blob_normalized: "81a9d66e22797ea2b1b0632ecddfcaf73fd06757"
          role: "code"
        - path: "EasyKeyKit/Keyboard/KeyboardService.swift"
          git_blob: "3246c7e678b841077f3006877c3b2ead836e912b"
          git_blob_normalized: "3246c7e678b841077f3006877c3b2ead836e912b"
          role: "code"
      unresolved: []
    - id: "clipboard-history-and-payloads-confidential"
      sources:
        - path: "EasyEngineCore/Clipboard/ClipboardOptions.swift"
          git_blob: "f1409bbfebea82ad1d8e76ec6d75612f0b1b7a93"
          git_blob_normalized: "f1409bbfebea82ad1d8e76ec6d75612f0b1b7a93"
          role: "code"
        - path: "EasyKeyApp/Features/Clipboard/ClipboardMonitor.swift"
          git_blob: "b554c2a511999b5eab5b545232bd3fc2c8cedf76"
          git_blob_normalized: "b554c2a511999b5eab5b545232bd3fc2c8cedf76"
          role: "code"
        - path: "EasyKeyApp/Features/Clipboard/PasteboardSnapshot.swift"
          git_blob: "cf479dc1990e259036d4ce3784f8539195e38f41"
          git_blob_normalized: "cf479dc1990e259036d4ce3784f8539195e38f41"
          role: "code"
        - path: "EasyKeyApp/Features/Clipboard/ClipboardHistoryModel.swift"
          git_blob: "6fe0b0f894f3d17c9546f48eb32f497701ac0ede"
          git_blob_normalized: "6fe0b0f894f3d17c9546f48eb32f497701ac0ede"
          role: "code"
        - path: "EasyKeyApp/Features/Clipboard/ClipboardPersistence.swift"
          git_blob: "2f2f6e1c7c03071c95010c565309b55a06b15c34"
          git_blob_normalized: "2f2f6e1c7c03071c95010c565309b55a06b15c34"
          role: "code"
      unresolved: []
    - id: "translation-source-text-and-results-confidential-transient"
      sources:
        - path: "EasyKeyApp/Features/Translation/AppTranslationRuntime.swift"
          git_blob: "4f6f75d8aa093c688ec77d6722ba0cc62769b87d"
          git_blob_normalized: "4f6f75d8aa093c688ec77d6722ba0cc62769b87d"
          role: "code"
        - path: "EasyKeyApp/Features/Translation/TranslationProviding.swift"
          git_blob: "6f084a52ef962023ebf19cd19dc37d378c2b83b9"
          git_blob_normalized: "6f084a52ef962023ebf19cd19dc37d378c2b83b9"
          role: "code"
        - path: "EasyKeyApp/Features/Translation/GoogleTranslationProvider.swift"
          git_blob: "a58ea2ffd3149408365009e036353d1c130b3056"
          git_blob_normalized: "a58ea2ffd3149408365009e036353d1c130b3056"
          role: "code"
        - path: "EasyEngineCore/Translation/TranslationOptions.swift"
          git_blob: "ac20f144cfffb6a896dfc2fe27c2b6651e48456c"
          git_blob_normalized: "ac20f144cfffb6a896dfc2fe27c2b6651e48456c"
          role: "code"
        - path: "EasyKeyApp/Features/Translation/TranslationModel.swift"
          git_blob: "cbff7d5a4ea3f0690ff7b7962acafec1e9c88a0c"
          git_blob_normalized: "cbff7d5a4ea3f0690ff7b7962acafec1e9c88a0c"
          role: "code"
        - path: "EasyKeyApp/Features/Translation/TranslationDisclosureController.swift"
          git_blob: "9795c7fc78539e5b7758259157d1f3ae63dff87a"
          git_blob_normalized: "9795c7fc78539e5b7758259157d1f3ae63dff87a"
          role: "code"
      unresolved: []
    - id: "cloud-translation-credentials-secret"
      sources:
        - path: "EasyKeyApp/Features/Translation/TranslationCredentialStore.swift"
          git_blob: "768aab956a8d02978101105e7a896b6d55c75376"
          git_blob_normalized: "768aab956a8d02978101105e7a896b6d55c75376"
          role: "code"
        - path: "EasyEngineCore/Settings/SettingsRepository.swift"
          git_blob: "8dbf2339135a67a57533869cca68d46cc6e8c991"
          git_blob_normalized: "8dbf2339135a67a57533869cca68d46cc6e8c991"
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
          git_blob: "8dbf2339135a67a57533869cca68d46cc6e8c991"
          git_blob_normalized: "8dbf2339135a67a57533869cca68d46cc6e8c991"
          role: "code"
      unresolved: []
    - id: "diagnostic-logs-and-exports-internal"
      sources:
        - path: "EasyEngineCore/Diagnostics/AppLog.swift"
          git_blob: "827ef0baa84980d0df634f19d06d944c856a4293"
          git_blob_normalized: "827ef0baa84980d0df634f19d06d944c856a4293"
          role: "code"
        - path: "EasyKeyApp/Coordination/LogExporter.swift"
          git_blob: "d4cb310fd2cb020302eb4ecac9ccb154505493d7"
          git_blob_normalized: "d4cb310fd2cb020302eb4ecac9ccb154505493d7"
          role: "code"
      unresolved: []
    - id: "compliance-evidence"
      sources:
        - path: "README.md"
          git_blob: "0de1699403dbb6d0d24b58a2963cde1ac952a70e"
          git_blob_normalized: "0de1699403dbb6d0d24b58a2963cde1ac952a70e"
          role: "doc"
        - path: "docs/product/overview.md"
          git_blob: "f71493c7ff2b280378f4ce271a3a4104cb576aa1"
          git_blob_normalized: "f71493c7ff2b280378f4ce271a3a4104cb576aa1"
          role: "doc"
        - path: "EasyKeyApp/Features/Clipboard/ClipboardKeyStore.swift"
          git_blob: "8308409cb0bb907254e169b15dd74b9304399ed3"
          git_blob_normalized: "8308409cb0bb907254e169b15dd74b9304399ed3"
          role: "code"
        - path: "EasyKeyApp/Features/Clipboard/ClipboardPersistence.swift"
          git_blob: "2f2f6e1c7c03071c95010c565309b55a06b15c34"
          git_blob_normalized: "2f2f6e1c7c03071c95010c565309b55a06b15c34"
          role: "code"
        - path: "EasyKeyApp/Features/Clipboard/ClipboardMonitor.swift"
          git_blob: "b554c2a511999b5eab5b545232bd3fc2c8cedf76"
          git_blob_normalized: "b554c2a511999b5eab5b545232bd3fc2c8cedf76"
          role: "code"
        - path: "EasyKeyApp/Coordination/LogExporter.swift"
          git_blob: "d4cb310fd2cb020302eb4ecac9ccb154505493d7"
          git_blob_normalized: "d4cb310fd2cb020302eb4ecac9ccb154505493d7"
          role: "code"
      unresolved: []
---
# Data handling

_Last reviewed: 2026-08-13_

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
| Retained | Memory-only by default (`persistsHistory = false`); when persistence is enabled, the manifest and payloads are sealed with AES-GCM under a Keychain-held key in `Application Support/EasyKey/Clipboard`; retention defaults to 100 entries and 7 days with pinned entries (max 25) exempt from pruning |
| Deleted | `clearAll()` calls `deleteAll()`, which removes the persistence directory and deletes the Keychain key; disabling persistence triggers the same deletion; per-entry remove, unpinned clear, age/count pruning, and orphan-payload removal all delete immediately |

**Access:** the app process in memory; on disk, ciphertext is readable by local
users but not decryptable without the device-only, non-synchronizing Keychain
key.

## Translation source text and results (confidential, transient)

| Stage | Behavior |
|---|---|
| Collected | Only from EasyKey translation surfaces (translation editor, menu popover, Option+C panel) as `request.sourceText`; general keyboard input is never submitted; first use of each cloud provider requires a disclosure prompt |
| Used | Submitted directly to the selected provider over the validated HTTPS endpoint; results rendered in the translation panel; no intermediate service |
| Retained | Not persisted to disk; an in-memory session (source text, result) survives panel close under the default `sessionPersistence = .keepUntilRestart` and is held until the app restarts |
| Deleted | Nothing stored on disk to delete; the in-memory session is dropped on panel close only when `sessionPersistence = .clearOnClose` — the default `.keepUntilRestart` clears it at app restart (`AppTranslationRuntime.handleSurfaceClosed` → `TranslationModel.clearSession`) |

**Access:** the selected provider, per its terms (retention on the provider
side is not evidenced here and is out of repository scope); the app keeps no
persisted copy.

### Provider data handling and retention links

Provider-side handling and retention of submitted source text depend on each
provider's terms, account tier, and account controls; nothing in this
repository controls or evidences them. First use of each cloud provider shows
a disclosure naming the provider and explaining that source text is
transferred to it before the request proceeds; declining cancels the request,
and consent can be reset in Translation settings. Requests go directly to the
selected provider — they never pass through an EasyKey server. Provider names
and links identify interoperability and provider-controlled data handling
only; they do not imply sponsorship, affiliation, or endorsement. Links
reviewed on July 19, 2026:

- [DeepL Privacy Policy](https://www.deepl.com/privacy)
- [Google Cloud Translation data usage](https://cloud.google.com/translate/data-usage)
- [OpenAI API data controls](https://platform.openai.com/docs/guides/your-data)
- [Anthropic Privacy Center](https://privacy.anthropic.com/)
- [Gemini API Additional Terms](https://ai.google.dev/gemini-api/terms)
- [OpenRouter Privacy Policy](https://openrouter.ai/privacy)
- [Groq Privacy Policy](https://groq.com/privacy-policy/)
- A user-configured OpenAI-compatible or Anthropic-compatible endpoint is
  governed by that endpoint's published terms.

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

- No analytics or telemetry collection ([README](../README.md) Private by Design,
  [product overview](../product/overview.md)).
- Device-only, non-synchronizing Keychain items for credentials and keys.
- AES-GCM authenticated encryption with key deletion on clear and on
  persistence disable.
- Opt-in capture with memory-only default and sensitive-marker rejection.
- Log export redaction and permission restriction.
- No compliance posture (GDPR, HIPAA, SOC 2, or similar) is claimed or
  evidenced anywhere in the repository.

Limits: provider-side handling and retention of submitted translation text are
governed by provider terms (links in [Provider data handling and
retention links](#provider-data-handling-and-retention-links)); nothing in
this repository controls or evidences them.
