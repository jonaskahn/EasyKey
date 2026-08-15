# Configuration

_Last reviewed: 2026-08-15_

EasyKey reads two configuration surfaces: a JSON settings document on disk
(`settings.json`, owned by `SettingsRepository`) and a handful of
`UserDefaults` keys owned by the app layer. Cloud credentials never appear in
either — they live in the Keychain (see
[permissions.md](../security/permissions.md)).
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
| Live confidence scoring | `typing.liveConfidenceScoring` | `false` | settings document | No |
| Restore invalid words | `typing.restoreInvalidWord` | `true` | settings document | No |
| Live confidence low threshold | `typing.liveConfidenceLowThreshold` | `0.35` | settings document | No |
| Live confidence high threshold | `typing.liveConfidenceHighThreshold` | `0.80` | settings document | No |
| iOS-UniKey-like mode | `typing.iosUniKeyLikeMode` | `true` | settings document | No |
| Tone style | `typing.toneStyle` | `old` | settings document | No |
| Quick Telex consonants | `typing.quickTelexConsonants` | `false` | settings document | No |
| Standalone `w` → `ư` | `typing.standaloneWShortcut` | `true` | settings document | No |
| Bracket shortcuts (`[` `]` …) | `typing.bracketShortcuts` | `true` | settings document | No |
| Restore-word shortcut | `typing.restoreWordShortcut` | `none` | settings document | No |
| Literal technical tokens | `typing.literalTechnicalTokens` | `true` | settings document | No |
| Ignore function keys | `typing.ignoreFunctionKeys` | `true` | settings document | No |
| Uppercase first character | `typing.uppercaseFirstCharacter` | `false` | settings document | No |

## Translation

Source: `EasyKeySettings.translation`
(`TranslationOptions.swift`).
The default preferred provider is Apple (`.apple`). Selecting "Automatic"
stores `nil`, resolved per-launch by
`TranslationProviderResolver.resolveEffectiveProvider` — Apple on macOS 15+,
otherwise the first configured cloud provider in `cloudProviderOrder`. API
keys are Keychain items, never settings.

| Setting | Source | Default | Scope | Sensitive |
|---|---|---|---|---|
| Preferred provider | `translation.preferredProviderID` | `apple` (Apple); `nil` when Automatic is selected | settings document | No |
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
per-macro state in `MacroStore` (trigger/expansion/enabled/category; see
`MacroStore.swift`). Validation
limits: trigger ≤ 128 characters, expansion ≤ 16384 characters.

| Setting | Source | Default | Scope | Sensitive |
|---|---|---|---|---|
| Macros enabled | `macro.enabled` | `false` | settings document | No |
| Auto-capitalize expansions | `macro.autoCapitalize` | `false` | settings document | No |

Which input languages a macro applies to is per-macro (`Macro.category`:
`vietnamese`, `english`, `nineX`, `genZ`, or `both`), not a global option.

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
| Menu bar icon style | `system.menuBarIconStyle` | `style9` | settings document | No |
| Menu bar icon scale | `system.menuBarIconScale` | `percent130` (1.3×) | settings document | No |
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
currently 11. Import validation: file size ≤ 1 MiB
(`SettingsRepository.maxImportFileBytes`), schema version ≤ current, otherwise
`SettingsRepositoryError`. The app layer wraps the repository in the
`@MainActor` `SettingsStore` (`ObservableObject`), which exposes
`update`, key-path `binding`, `reset`, `export`, `import`, `load`, and
`saveNow`.

## Release pipeline environment

Release builds read build-setting substitutions and CI variables — documented
end-to-end in [distribution.md](../operations/distribution.md); local builds leave feed and
key values empty so Sparkle is disabled rather than pointed at an untrusted
endpoint (`UpdateService.hasReleaseConfiguration` rejects placeholder `$(` values).
The release workflow currently runs `make local-dmg` — ad-hoc signed, not
notarized — because Developer ID signing and notarization are staged but
disabled pending an Apple certificate; the certificate-import step was removed
from the release workflow and `make dmg` remains the fully signed path for when
it is re-enabled. Secrets are never printed and never committed; they are
injected by the CI secret environment at release time.

| Variable | Consumed as | Default | Scope | Sensitive |
|---|---|---|---|---|
| `SPARKLE_FEED_URL` | `Info.plist` `SUFeedURL` | empty (updates off) | CI variable | No |
| `SPARKLE_PUBLIC_ED_KEY` | `Info.plist` `SUPublicEDKey` | empty (updates off) | CI secret | Yes |
| `SPARKLE_PRIVATE_ED_KEY` | appcast signing (`sign_update`) | — | CI secret | Yes |
| `EASYKEY_SUPPORT_URL` | `Info.plist` `EasyKeySupportURL` | — | CI variable | No |
| `EASYKEY_PRIVACY_POLICY_URL` | `Info.plist` `EasyKeyPrivacyPolicyURL` | — | CI variable | No |
| `DEVELOPER_ID_APPLICATION`, `DEVELOPMENT_TEAM` | signing (staged; not consumed by the current release workflow) | — | CI secret | Yes |
| `APPLE_ID`, `APPLE_TEAM_ID`, `APPLE_APP_SPECIFIC_PASSWORD` | notarization (Apple ID alternative); `NOTARY_KEYCHAIN_PROFILE` for local notarytool | — | CI secret | Yes |
| `ARCHS`, `REQUIRED_ARCHS`, `TARGET_NAME`, `TAG_NAME` | DMG matrix build (`make local-dmg`) | per workflow matrix | workflow-internal | No |
