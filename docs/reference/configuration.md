---
id: "configuration"
title: "Configuration"
docforge_provenance:
  schema: "2.0"
  doc_id: "configuration"
  path: "docs/reference/configuration.md"
  generated_at: "2026-08-03T08:48:15Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "reference"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "configuration"
      sources:
        - path: "EasyEngineCore/Settings/EasyKeySettings.swift"
          role: "code"
          git_blob: "b42c58c6e3f1eba416bca3c809ba579441fe87cc"
        - path: "EasyEngineCore/Settings/SettingsRepository.swift"
          role: "code"
          git_blob: "f718fcf9ea3a84f0aa770650c15c8c059e450a19"
      unresolved: []
    - id: "input-and-typing"
      sources:
        - path: "EasyEngineCore/Settings/InputSettings.swift"
          role: "code"
          git_blob: "55a05f33b0b86e23f3fbce6c956f8a2c4921e6ab"
        - path: "EasyEngineCore/Settings/TypingOptions.swift"
          role: "code"
          git_blob: "301556d3f6530ff3b8613343a5b6c5e77ed152cf"
        - path: "EasyEngineCore/Settings/Shortcut.swift"
          role: "code"
          git_blob: "32d36fb49bcc848bb8817c1cffa2a00c3d7fb994"
      unresolved: []
    - id: "translation"
      sources:
        - path: "EasyEngineCore/Translation/TranslationOptions.swift"
          role: "code"
          git_blob: "1c0c39a3d9bc405c47c447ac21c90b0d9545d89f"
        - path: "EasyEngineCore/Translation/TranslationProviderResolver.swift"
          role: "code"
          git_blob: "9fe5786ed549713c4631839352100124f86cba13"
        - path: "EasyKeyApp/Features/Settings/Translation/TranslationSettingsModel.swift"
          role: "code"
          git_blob: "6380a5fed49e57b42d37bb611ddcb6d26661ee43"
      unresolved: []
    - id: "clipboard"
      sources:
        - path: "EasyEngineCore/Clipboard/ClipboardOptions.swift"
          role: "code"
          git_blob: "f1409bbfebea82ad1d8e76ec6d75612f0b1b7a93"
        - path: "EasyEngineCore/Clipboard/ClipboardEntry.swift"
          role: "code"
          git_blob: "2b6b2d0d1e12143a526f8aca275cee59a3a5b017"
      unresolved: []
    - id: "macros"
      sources:
        - path: "EasyEngineCore/Macros/MacroOptions.swift"
          role: "code"
          git_blob: "0163b8653a26c74939460a3a9fffae513cfc82ea"
        - path: "EasyEngineCore/Macros/MacroStore.swift"
          role: "code"
          git_blob: "b8a7256fcac4629b3824c752dd654f849170de08"
      unresolved: []
    - id: "smart-switch"
      sources:
        - path: "EasyEngineCore/SmartSwitch/SmartSwitchOptions.swift"
          role: "code"
          git_blob: "651f4dde5a9df0f03466c3185d904aa63c72f1af"
        - path: "EasyEngineCore/SmartSwitch/SmartSwitchStore.swift"
          role: "code"
          git_blob: "694b512e15a06e34e7df216ba74a4fc133e27f69"
      unresolved: []
    - id: "compatibility"
      sources:
        - path: "EasyEngineCore/Settings/CompatibilityOptions.swift"
          role: "code"
          git_blob: "51e22adaa9ea230bb9345d4b3f9f8eb099919f6e"
      unresolved: []
    - id: "system"
      sources:
        - path: "EasyEngineCore/Settings/SystemOptions.swift"
          role: "code"
          git_blob: "f8a09dbaa075211761f9ce69f1633cdb9077f82a"
        - path: "EasyKeyApp/Coordination/LoginItemController.swift"
          role: "code"
          git_blob: "7833a6d82792ded3986386ac26e40b686feab12d"
      unresolved: []
    - id: "converter"
      sources:
        - path: "EasyEngineCore/Converter/ConverterOptions.swift"
          role: "code"
          git_blob: "305ee275b13e3b9e3bef7fb31a1518a4dc8a4888"
      unresolved: []
    - id: "interface-language-and-onboarding"
      sources:
        - path: "EasyKeyApp/Localization/AppLanguage.swift"
          role: "code"
          git_blob: "1051771cdc25ef48d1f98e213e03a7f651f4196e"
        - path: "EasyKeyApp/AppDelegate.swift"
          role: "code"
          git_blob: "8ecc5922afe0e99166cbcf3425afd2514b887ae2"
      unresolved: []
    - id: "panel-display-preferences"
      sources:
        - path: "EasyKeyApp/Features/Clipboard/ClipboardPanelPresenter.swift"
          role: "code"
          git_blob: "ff8c6cb8cd91f1c22aa0970efd389359ee01cd83"
        - path: "EasyKeyApp/Features/Translation/TranslationPanelPresenter.swift"
          role: "code"
          git_blob: "c4db933b5e640c60680df6bc917baa1db669947e"
      unresolved: []
    - id: "settings-document"
      sources:
        - path: "EasyEngineCore/Settings/SettingsRepository.swift"
          role: "code"
          git_blob: "f718fcf9ea3a84f0aa770650c15c8c059e450a19"
        - path: "EasyEngineCore/Settings/SettingsMigration.swift"
          role: "code"
          git_blob: "faf8ce6b4248f9966298919b3e3b12fedef614d5"
        - path: "EasyKeyApp/Settings/ObservableSettingsStore.swift"
          role: "code"
          git_blob: "c77772d40545b8e15ea62a6ca49d25eace1d355a"
      unresolved: []
    - id: "release-pipeline-environment"
      sources:
        - path: "docs/_archive/RELEASE.md"
          role: "doc"
          git_blob: "c749b17a004e3cf47af6af61e82db4aa9d40494d"
        - path: "EasyKeyApp/Info.plist"
          role: "config"
          git_blob: "f4603871fa675111bd6db1472dfb04936ff3f645"
        - path: "Makefile"
          role: "config"
          git_blob: "b8fa0059c061eef05cb083ae69e8e7d46336aa64"
      unresolved: []
---
# Configuration

_Last reviewed: 2026-08-03_

EasyKey reads two configuration surfaces: a JSON settings document on disk
(`settings.json`, owned by `SettingsRepository`) and a handful of
`UserDefaults` keys owned by the app layer. Cloud credentials never appear in
either — they live in the Keychain (see `PRIVACY.md`).
Release-time behavior is additionally parameterized by CI environment
variables documented at the end. `Sensitive` means "must not be logged or
committed"; every row below defaults to `No` unless marked.

Ordered by how often a reader tunes each setting.

## Input and typing

Source: `EasyKeySettings.input` / `EasyKeySettings.typing`
(`InputSettings.swift`,
`TypingOptions.swift`).
Shortcuts are the `Shortcut` struct (key code + modifiers) from
`Shortcut.swift`; `Shortcut.none`
means disabled.

| Setting | Source | Default | Scope | Sensitive |
|---|---|---|---|---|
| Typing language | `input.language` | `vietnamese` | settings document | No |
| Input method (Telex / Simple Telex / VNI) | `input.inputMethod` | `simpleTelex` | settings document | No |
| Output encoding | `input.encoding` | `unicode` | settings document | No |
| Language switch shortcut | `input.switchShortcut` | `⌥Z` (keyCode 6 + option) | settings document | No |
| Spell check | `typing.spellCheck` | `true` | settings document | No |
| Restore invalid words | `typing.restoreInvalidWord` | `true` | settings document | No |
| Tone style | `typing.toneStyle` | `old` | settings document | No |
| Quick Telex consonants | `typing.quickTelexConsonants` | `false` | settings document | No |
| Standalone `w` → `ư` | `typing.standaloneWShortcut` | `true` | settings document | No |
| Bracket shortcuts (`[` `]` …) | `typing.bracketShortcuts` | `true` | settings document | No |
| Restore-word shortcut | `typing.restoreWordShortcut` | `none` | settings document | No |
| Uppercase first character | `typing.uppercaseFirstCharacter` | `false` | settings document | No |

## Translation

Source: `EasyKeySettings.translation`
(`TranslationOptions.swift`).
`preferredProviderID == nil` is the Automatic preference, resolved per-launch by
`TranslationProviderResolver.resolveEffectiveProvider` (Apple on macOS 15+,
else the first configured cloud provider in `cloudProviderOrder`). API keys are
Keychain items, never settings.

| Setting | Source | Default | Scope | Sensitive |
|---|---|---|---|---|
| Preferred provider (nil = Automatic) | `translation.preferredProviderID` | `nil` | settings document | No |
| Open translate shortcut | `translation.shortcut` | `⌥C` (keyCode 8 + option) | settings document | No |
| Default source language (nil = detect) | `translation.defaultSourceLanguage` | `nil` | settings document | No |
| OpenAI model | `translation.openAIModelIdentifier` | `gpt-4o-mini` | settings document | No |
| Anthropic model | `translation.anthropicModelIdentifier` | `claude-haiku-4-5` | settings document | No |
| Gemini model | `translation.geminiModelIdentifier` | `gemini-2.0-flash` | settings document | No |
| DeepL endpoint tier | `translation.deepLEndpoint` | `free` | settings document | No |
| OpenRouter model | `translation.openRouterModelIdentifier` | `openai/gpt-4o-mini` | settings document | No |
| Groq model | `translation.groqModelIdentifier` | `llama-3.1-8b-instant` | settings document | No |
| OpenAI-compatible model / endpoint | `translation.openAICompatibleModelIdentifier` / `openAICompatibleEndpoint` | `gpt-4o-mini` / `""` | settings document | No |
| Anthropic-compatible model / endpoint | `translation.anthropicCompatibleModelIdentifier` / `anthropicCompatibleEndpoint` | `claude-haiku-4-5` / `""` | settings document | No |
| Cloud disclosure acknowledgements | `translation.acknowledgedCloudDisclosureProviders` | `[]` | settings document | No |
| Translation enabled | `translation.isEnabled` | `false` | settings document | No |
| Show in menu popover | `translation.showInMenuPopover` | `false` | settings document | No |
| Cmd-C double-press enable / window | `translation.cmdCDoublePressEnabled` / `cmdCDoublePressWindowMs` | `false` / `400` ms | settings document | No |
| Auto-translate delay | `translation.autoTranslateDelayMs` | `500` (presets 250/500/750/1000/1500) | settings document | No |
| Panel size | `translation.panelSize` | `medium` | settings document | No |
| Session persistence | `translation.sessionPersistence` | `keepUntilRestart` | settings document | No |

## Clipboard

Source: `EasyKeySettings.clipboard`
(`ClipboardOptions.swift`).
The clipboard manager is off by default; capture filters by
`ClipboardContentKind.capturable` (text, url, image, file, video — `mixed` is
derived, never filtered).

| Setting | Source | Default | Scope | Sensitive |
|---|---|---|---|---|
| Capture enabled | `clipboard.isCaptureEnabled` | `false` | settings document | No |
| Open clipboard shortcut | `clipboard.shortcut` | `⌥V` (keyCode 9 + option) | settings document | No |
| Selection action | `clipboard.selectionAction` | `pasteImmediately` | settings document | No |
| Maximum entry count | `clipboard.maximumEntryCount` | `100` | settings document | No |
| Retention days | `clipboard.retentionDays` | `7` | settings document | No |
| Persist history (AES-GCM sealed) | `clipboard.persistsHistory` | `false` | settings document | No |
| Captured content kinds | `clipboard.capturedKinds` | text, url, image, file, video | settings document | No |
| Ignored source applications | `clipboard.ignoredApplicationBundleIdentifiers` | `[]` | settings document | No |

## Macros

Source: `EasyKeySettings.macro`
(`MacroOptions.swift`) plus
per-macro state in `MacroStore` (trigger/expansion/enabled; see
`MacroStore.swift`). Validation
limits: trigger ≤ 128 characters, expansion ≤ 16384 characters.

| Setting | Source | Default | Scope | Sensitive |
|---|---|---|---|---|
| Macros enabled | `macro.enabled` | `false` | settings document | No |
| Macros in English input | `macro.enabledInEnglish` | `false` | settings document | No |
| Auto-capitalize expansions | `macro.autoCapitalize` | `false` | settings document | No |

## Smart Switch

Source: `EasyKeySettings.smartSwitch`
(`SmartSwitchOptions.swift`).
Per-application values are keyed by `SmartSwitchStore`'s stable application key
(`bundle:` / `path:` / `name:`), stored in a separate Smart Switch document.

| Setting | Source | Default | Scope | Sensitive |
|---|---|---|---|---|
| Smart Switch enabled | `smartSwitch.enabled` | `false` | settings document | No |
| Remember encoding per app | `smartSwitch.rememberEncoding` | `false` | settings document | No |
| Per-application overrides | `smartSwitch.perApplicationValues` | `[:]` | settings document + Smart Switch document | No |

## Compatibility

Source: `EasyKeySettings.compatibility`
(`CompatibilityOptions.swift`).
Defaults put Chromium browsers in compatibility mode; `AppCompatibility` in
EasyKeyKit applies fixed per-app workarounds for Safari, Spotlight, and
VSCode.

| Setting | Source | Default | Scope | Sensitive |
|---|---|---|---|---|
| Other-language support | `compatibility.otherLanguageSupport` | `false` | settings document | No |
| Compatibility-mode applications | `compatibility.compatibilityModeApplicationBundleIdentifiers` | `com.google.Chrome`, `org.chromium.Chromium` | settings document | No |
| Ignored applications | `compatibility.ignoredApplicationBundleIdentifiers` | `[]` | settings document | No |

## System

Source: `EasyKeySettings.system`
(`SystemOptions.swift`).
`launchAtLogin` is applied via `SMAppService.loginItem` in
`LoginItemController.swift`;
menu popover widths are raw pixel values (280–640).

| Setting | Source | Default | Scope | Sensitive |
|---|---|---|---|---|
| Launch at login | `system.launchAtLogin` | `false` | settings document + SMAppService | No |
| Show Dock icon | `system.showDockIcon` | `false` | settings document | No |
| Gray menu-bar icon | `system.grayMenuIcon` | `false` | settings document | No |
| Show settings at launch | `system.showSettingsAtLaunch` | `false` | settings document | No |
| Check for updates | `system.checkForUpdates` | `true` | settings document | No |
| Menu popover width | `system.menuPopoverWidth` | `small` (360) | settings document | No |

## Converter

Source: `EasyKeySettings.converter`
(`ConverterOptions.swift`).

| Setting | Source | Default | Scope | Sensitive |
|---|---|---|---|---|
| Source encoding | `converter.sourceEncoding` | `unicode` | settings document | No |
| Destination encoding | `converter.destinationEncoding` | `unicode` | settings document | No |

## Interface language and onboarding

`UserDefaults.standard` keys owned by the app layer — not part of
`settings.json`:

| Setting | Source | Default | Scope | Sensitive |
|---|---|---|---|---|
| Interface language | `UserDefaults` key `interfaceLanguage` (shared with legacy `@AppStorage`) | `vietnamese` when unset | `EasyKeyApp/Localization/AppLanguage.swift` | No |
| Onboarding completed | `UserDefaults` key `hasCompletedOnboarding` | unset; `--ui-skip-onboarding` sets it under `--uitesting` | `EasyKeyApp/AppDelegate.swift` | No |

Values for `interfaceLanguage` are `system`, `en`, or `vi`
(`AppLanguage.load(from:)`); the system value resolves through
`Locale.preferredLanguages`.

## Panel display preferences

Transient panel state persisted per-surface in `UserDefaults.standard`:

| Setting | Source | Default | Scope | Sensitive |
|---|---|---|---|---|
| Clipboard panel keep-on-top | `UserDefaults` key `panel.clipboard.keepOnTop` | `false` | `ClipboardPanelPresenter` | No |
| Translation panel keep-on-top | `UserDefaults` key `panel.translation.keepOnTop` | `false` | `TranslationPanelPresenter` | No |

## Settings document

`SettingsRepository` persists `EasyKeySettings` as JSON at
`~/Library/Application Support/EasyKey/settings.json` (Application Support,
falling back to Caches, then temp). Writes are atomic, pretty-printed,
sorted-key, debounced 300 ms, and queued on a serial utility queue. Every
root field decodes with `decodeIfPresent` and its current default, so older
documents migrate without resetting unrelated preferences; `schemaVersion` is
currently 8. Import validation: file size ≤ 1 MiB
(`SettingsRepository.maxImportFileBytes`), schema version ≤ current, otherwise
`SettingsRepositoryError`. The app layer wraps the repository in the
`@MainActor` `ObservableSettingsStore` (`SettingsStore`), which exposes
`update`, key-path `binding`, `reset`, `export`, `import`, `load`, and
`saveNow`.

## Release pipeline environment

Release builds read build-setting substitutions and CI variables — documented
end-to-end in `RELEASE.md`; local builds leave feed and
key values empty so Sparkle is disabled rather than pointed at an untrusted
endpoint. Secrets are never printed and never committed; they are injected by
the CI secret environment at release time.

| Variable | Consumed as | Default | Scope | Sensitive |
|---|---|---|---|---|
| `SPARKLE_FEED_URL` | `Info.plist` `SUFeedURL` | empty (updates off) | CI variable | No |
| `SPARKLE_PUBLIC_ED_KEY` | `Info.plist` `SUPublicEDKey` | empty (updates off) | CI secret | Yes |
| `SPARKLE_PRIVATE_ED_KEY` | `sign_update` (appcast signing) | — | CI secret | Yes |
| `EASYKEY_SUPPORT_URL` | `Info.plist` `EasyKeySupportURL` | — | CI variable | No |
| `EASYKEY_PRIVACY_POLICY_URL` | `Info.plist` `EasyKeyPrivacyPolicyURL` | — | CI variable | No |
| `DEVELOPER_ID_APPLICATION`, `DEVELOPMENT_TEAM` | signing | — | CI secret | Yes |
| `BUILD_CERTIFICATE_BASE64`, `BUILD_CERTIFICATE_PASSWORD`, `KEYCHAIN_PASSWORD` | certificate import | — | CI secret | Yes |
| `NOTARY_APPLE_ID`, `NOTARY_APP_SPECIFIC_PASSWORD` | notarization (CI); `NOTARY_KEYCHAIN_PROFILE` for local notarytool | — | CI secret | Yes |
| `ARCHS`, `REQUIRED_ARCHS`, `TARGET_NAME`, `TAG_NAME` | DMG matrix build (`make local-dmg`) | per workflow matrix | workflow-internal | No |
