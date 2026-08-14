---
id: "api_reference"
title: "Api Reference"
description: "Public surface, inputs/outputs, auth contract, limits, errors, compatibility source"
docforge_provenance:
  schema: "2.0"
  doc_id: "api_reference"
  path: "docs/reference/api.md"
  generated_at: "2026-08-13T11:11:02Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "spine"
  target_depth: "reference"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "api-reference"
      sources:
        - path: "EasyEngineCore/Engine/VietnameseEngine.swift"
          git_blob: "35a0190749c2ea1c5c37e5bd2c3bfed96f69fc03"
          git_blob_normalized: "35a0190749c2ea1c5c37e5bd2c3bfed96f69fc03"
          role: "code"
        - path: "EasyEngineCore/Engine/KeyEvent.swift"
          git_blob: "a4a486d2f583d6d3568be91be5387b7a321d03c9"
          git_blob_normalized: "a4a486d2f583d6d3568be91be5387b7a321d03c9"
          role: "code"
        - path: "EasyEngineCore/Engine/EngineOutput.swift"
          git_blob: "06aec453bfbcc6af20d8ac5f918571fe43fe3249"
          git_blob_normalized: "06aec453bfbcc6af20d8ac5f918571fe43fe3249"
          role: "code"
        - path: "EasyEngineCore/Engine/EncodingTable.swift"
          git_blob: "5b5b5b8b5a8f1e2d400d096e819deafb07e16588"
          git_blob_normalized: "5b5b5b8b5a8f1e2d400d096e819deafb07e16588"
          role: "code"
        - path: "EasyEngineCore/Engine/InputLanguage.swift"
          git_blob: "53381339582e91206ed1e64249e68782d597dd65"
          git_blob_normalized: "53381339582e91206ed1e64249e68782d597dd65"
          role: "code"
        - path: "EasyEngineCore/Engine/InputMethod.swift"
          git_blob: "819d471dfb0b167a557e274a2af9d2cdbf2e13bb"
          git_blob_normalized: "819d471dfb0b167a557e274a2af9d2cdbf2e13bb"
          role: "code"
        - path: "EasyEngineCore/Engine/TelexComposer.swift"
          git_blob: "2b42730f8b4154642ee53fa92ccc8d9bc63a093b"
          git_blob_normalized: "2b42730f8b4154642ee53fa92ccc8d9bc63a093b"
          role: "code"
      unresolved: []
    - id: "source-of-truth"
      sources:
        - path: "EasyEngineCore/Settings/EasyKeySettings.swift"
          git_blob: "aa8e22b824f59fd7a437d6af597ce6431ef10d57"
          git_blob_normalized: "aa8e22b824f59fd7a437d6af597ce6431ef10d57"
          role: "code"
        - path: "EasyKeyKit/Keyboard/Synthesis/KeySynthesizer.swift"
          git_blob: "d9d56d371db322150cd74a358258fe7243989bab"
          git_blob_normalized: "d9d56d371db322150cd74a358258fe7243989bab"
          role: "code"
        - path: "EasyKeyKit/Keyboard/KeyboardService.swift"
          git_blob: "3246c7e678b841077f3006877c3b2ead836e912b"
          git_blob_normalized: "3246c7e678b841077f3006877c3b2ead836e912b"
          role: "code"
        - path: "EasyKeyKit/EasyKeyKit.swift"
          git_blob: "c2a257acc1b06050b76e6f29eee06f39016336c0"
          git_blob_normalized: "c2a257acc1b06050b76e6f29eee06f39016336c0"
          role: "code"
      unresolved: []
    - id: "typing-engine"
      sources:
        - path: "EasyEngineCore/Engine/VietnameseEngine.swift"
          git_blob: "35a0190749c2ea1c5c37e5bd2c3bfed96f69fc03"
          git_blob_normalized: "35a0190749c2ea1c5c37e5bd2c3bfed96f69fc03"
          role: "code"
        - path: "EasyEngineCore/Engine/KeyEvent.swift"
          git_blob: "a4a486d2f583d6d3568be91be5387b7a321d03c9"
          git_blob_normalized: "a4a486d2f583d6d3568be91be5387b7a321d03c9"
          role: "code"
        - path: "EasyEngineCore/Engine/EngineOutput.swift"
          git_blob: "06aec453bfbcc6af20d8ac5f918571fe43fe3249"
          git_blob_normalized: "06aec453bfbcc6af20d8ac5f918571fe43fe3249"
          role: "code"
        - path: "EasyEngineCore/Engine/EncodingTable.swift"
          git_blob: "5b5b5b8b5a8f1e2d400d096e819deafb07e16588"
          git_blob_normalized: "5b5b5b8b5a8f1e2d400d096e819deafb07e16588"
          role: "code"
        - path: "EasyEngineCore/Engine/TelexComposer.swift"
          git_blob: "2b42730f8b4154642ee53fa92ccc8d9bc63a093b"
          git_blob_normalized: "2b42730f8b4154642ee53fa92ccc8d9bc63a093b"
          role: "code"
        - path: "EasyEngineCore/Engine/VietnameseTones.swift"
          git_blob: "0fc336e259b2c120d8590cc602a2b6c9459d42a1"
          git_blob_normalized: "0fc336e259b2c120d8590cc602a2b6c9459d42a1"
          role: "code"
        - path: "EasyEngineCore/Engine/EngineConfiguration.swift"
          git_blob: "300fdc2bd48af4f46cf2e9cd6f51dab9114c1781"
          git_blob_normalized: "300fdc2bd48af4f46cf2e9cd6f51dab9114c1781"
          role: "code"
      unresolved: []
    - id: "encoding-conversion"
      sources:
        - path: "EasyEngineCore/Converter/Converter.swift"
          git_blob: "0b990e8ce2106458e1816fd16ebb3613049cac21"
          git_blob_normalized: "0b990e8ce2106458e1816fd16ebb3613049cac21"
          role: "code"
        - path: "EasyEngineCore/Engine/EncodingTable.swift"
          git_blob: "5b5b5b8b5a8f1e2d400d096e819deafb07e16588"
          git_blob_normalized: "5b5b5b8b5a8f1e2d400d096e819deafb07e16588"
          role: "code"
      unresolved: []
    - id: "macros"
      sources:
        - path: "EasyEngineCore/Macros/MacroStore.swift"
          git_blob: "a5909fcd5e5e13b871c24d359a2e89f002ae239a"
          git_blob_normalized: "a5909fcd5e5e13b871c24d359a2e89f002ae239a"
          role: "code"
      unresolved: []
    - id: "smart-switch"
      sources:
        - path: "EasyEngineCore/SmartSwitch/SmartSwitchStore.swift"
          git_blob: "694b512e15a06e34e7df216ba74a4fc133e27f69"
          role: "code"
        - path: "EasyEngineCore/SmartSwitch/SmartSwitchOptions.swift"
          git_blob: "651f4dde5a9df0f03466c3185d904aa63c72f1af"
          role: "code"
      unresolved: []
    - id: "clipboard"
      sources:
        - path: "EasyEngineCore/Clipboard/ClipboardEntry.swift"
          git_blob: "2b6b2d0d1e12143a526f8aca275cee59a3a5b017"
          role: "code"
        - path: "EasyEngineCore/Clipboard/ClipboardOptions.swift"
          git_blob: "f1409bbfebea82ad1d8e76ec6d75612f0b1b7a93"
          role: "code"
      unresolved: []
    - id: "translation"
      sources:
        - path: "EasyEngineCore/Translation/TranslationProviderResolver.swift"
          git_blob: "9fe5786ed549713c4631839352100124f86cba13"
          git_blob_normalized: "9fe5786ed549713c4631839352100124f86cba13"
          role: "code"
        - path: "EasyEngineCore/Translation/TranslationLanguage.swift"
          git_blob: "93ca62cf9efab0493a297a5bbebd867de4252bca"
          git_blob_normalized: "93ca62cf9efab0493a297a5bbebd867de4252bca"
          role: "code"
        - path: "EasyEngineCore/Translation/TranslationOptions.swift"
          git_blob: "ac20f144cfffb6a896dfc2fe27c2b6651e48456c"
          git_blob_normalized: "ac20f144cfffb6a896dfc2fe27c2b6651e48456c"
          role: "code"
        - path: "EasyEngineCore/Translation/TranslationLanguagePolicy.swift"
          git_blob: "a72cd8efe7adac6b7149dff6c6f49570abe5174b"
          git_blob_normalized: "a72cd8efe7adac6b7149dff6c6f49570abe5174b"
          role: "code"
        - path: "EasyEngineCore/Translation/SupportedLanguages.swift"
          git_blob: "0091dea40cb4db68095afd1afe3127b319402260"
          git_blob_normalized: "0091dea40cb4db68095afd1afe3127b319402260"
          role: "code"
        - path: "EasyEngineCore/Translation/TranslationPlatformCapability.swift"
          git_blob: "414733ed3284bccb04ed05bb1cd1b0d6bd09e99a"
          git_blob_normalized: "414733ed3284bccb04ed05bb1cd1b0d6bd09e99a"
          role: "code"
        - path: "EasyKeyApp/Features/Translation/TranslationCredentialStore.swift"
          git_blob: "768aab956a8d02978101105e7a896b6d55c75376"
          git_blob_normalized: "768aab956a8d02978101105e7a896b6d55c75376"
          role: "code"
      unresolved: []
    - id: "settings"
      sources:
        - path: "EasyEngineCore/Settings/EasyKeySettings.swift"
          git_blob: "aa8e22b824f59fd7a437d6af597ce6431ef10d57"
          git_blob_normalized: "aa8e22b824f59fd7a437d6af597ce6431ef10d57"
          role: "code"
        - path: "EasyEngineCore/Settings/SettingsRepository.swift"
          git_blob: "8dbf2339135a67a57533869cca68d46cc6e8c991"
          git_blob_normalized: "8dbf2339135a67a57533869cca68d46cc6e8c991"
          role: "code"
        - path: "EasyEngineCore/Settings/SettingsMigration.swift"
          git_blob: "af7254b39294eaa98de15693f9ccde1ae6c3a789"
          git_blob_normalized: "af7254b39294eaa98de15693f9ccde1ae6c3a789"
          role: "code"
        - path: "EasyEngineCore/Settings/Shortcut.swift"
          git_blob: "32d36fb49bcc848bb8817c1cffa2a00c3d7fb994"
          git_blob_normalized: "32d36fb49bcc848bb8817c1cffa2a00c3d7fb994"
          role: "code"
      unresolved: []
    - id: "diagnostics"
      sources:
        - path: "EasyEngineCore/Diagnostics/AppLog.swift"
          git_blob: "827ef0baa84980d0df634f19d06d944c856a4293"
          git_blob_normalized: "827ef0baa84980d0df634f19d06d944c856a4293"
          role: "code"
      unresolved: []
    - id: "keyboard-adapters-easykeykit"
      sources:
        - path: "EasyKeyKit/Keyboard/KeyboardService.swift"
          git_blob: "3246c7e678b841077f3006877c3b2ead836e912b"
          git_blob_normalized: "3246c7e678b841077f3006877c3b2ead836e912b"
          role: "code"
        - path: "EasyKeyKit/Keyboard/Synthesis/KeySynthesizer.swift"
          git_blob: "d9d56d371db322150cd74a358258fe7243989bab"
          git_blob_normalized: "d9d56d371db322150cd74a358258fe7243989bab"
          role: "code"
        - path: "EasyKeyKit/Keyboard/KeyboardEventTap.swift"
          git_blob: "afd7e07bf098c7400aaccab85a72e77fac8a936d"
          git_blob_normalized: "afd7e07bf098c7400aaccab85a72e77fac8a936d"
          role: "code"
        - path: "EasyKeyKit/Keyboard/KeyboardInputPipeline.swift"
          git_blob: "81a9d66e22797ea2b1b0632ecddfcaf73fd06757"
          git_blob_normalized: "81a9d66e22797ea2b1b0632ecddfcaf73fd06757"
          role: "code"
        - path: "EasyKeyKit/Keyboard/SpotlightWindowDetector.swift"
          git_blob: "ab9966a65dc3f038110c81f2081fd81816599885"
          git_blob_normalized: "ab9966a65dc3f038110c81f2081fd81816599885"
          role: "code"
      unresolved: []
    - id: "app-compatibility-rules"
      sources:
        - path: "EasyKeyKit/Keyboard/Context/AppCompatibility.swift"
          git_blob: "9e4015582e88c1ee9962337e65cb62d7df586a96"
          git_blob_normalized: "9e4015582e88c1ee9962337e65cb62d7df586a96"
          role: "code"
      unresolved: []
    - id: "deprecated-api"
      sources:
        - path: "README.md"
          git_blob: "8fc7891befa21173acaaaf1b19c8c30ad6bb3f97"
          git_blob_normalized: "8fc7891befa21173acaaaf1b19c8c30ad6bb3f97"
          role: "doc"
      unresolved: []
---
# API reference

_Last reviewed: 2026-08-13_

**Source of truth:** the `public` declarations in the in-repo frameworks
`EasyEngineCore` and `EasyKeyKit` — there is no generated schema or
interface file. This page narrates that surface; if the two disagree, the
source wins. `EasyKeyApp` is the executable and its types are not public API
(protocols such as `TranslationProviding` are app-internal seams, not
libraries).

Naming drift to be aware of when reading issue-tracker vocabulary: there is
no `KeyboardOptions` type — keyboard behavior is `InputSettings` +
`TypingOptions`; and the task of per-app "Smart Switch preferences" is the
`SmartSwitchPreference` record kept by `SmartSwitchStore`, not a type called
`SmartSwitchPreferences`.

## Source of truth

| Framework | Bundle identifier | Version marker | Content |
|---|---|---|---|
| EasyEngineCore | `com.easykey.EasyEngineCore` | none (shares app marketing version) | Typing engine, encodings, converter, macros, Smart Switch, clipboard model, translation model, settings, diagnostics |
| EasyKeyKit | `one.ifelse.easykeyKit` | `EasyKeyKit.version = "0.0.10"` | Keyboard service, event synthesis, compatibility rules |

Dependency direction is enforced by architecture fitness tests:
`EasyKeyApp → EasyKeyKit → EasyEngineCore`; EasyEngineCore imports no
AppKit, SwiftUI, or Combine (see [tech-stack.md](tech-stack.md)).

## Typing engine

One streaming engine consumes raw keystrokes and emits edit instructions.
The buffer is recomputed from source keystrokes on every edit, which makes
backspace, repeat-to-undo, and word restoration exact. With
`literalTechnicalTokens` enabled, a token starting with a technical prefix
(`/`, `@`, `#`, `!`, `:`) at a word boundary is passed through
untransformed until the token ends.

| Type | Public surface |
|---|---|
| `VietnameseEngine` | `init(configuration:)`, `process(event: KeyEvent) -> EngineOutput`, `currentBuffer`, `reset()`, `resetComposition()`, `restoreRawKeys()`, `state: SessionState` |
| `KeyEvent` | `kind` (`character`, `backspace`, `space`, `return`, `tab`, arrows, `escape`, `forwardDelete`, `other`), modifier flags, `isUppercase` |
| `EngineOutput` | `disposition` (`pass`/`suppress`), `edits` (`deleteBackward`/`insert`/`replaceBackward`), `sessionEffect`, `passThrough`/`suppress` statics |
| `EngineConfiguration` | `inputMethod`, `outputEncoding`, `spellCheck`, `autoRestoreKeys`, `toneStyle`, `quickTelexConsonants`, `standaloneWShortcut`, `bracketShortcuts`, `uppercaseFirstCharacter`, `liveConfidenceScoring`, `liveConfidenceLowThreshold`, `liveConfidenceHighThreshold`, `iosUniKeyLikeMode`, `literalTechnicalTokens` |
| `SessionState` | composition state exposed by the engine |
| `TelexComposer` | rule application shared by the engine |
| `EncodingTable` | `unicode`, `unicodeCombining`, `tcvn3`, `vniWindows`, `cp1258` |
| `InputLanguage` | `vietnamese`, `english` |
| `InputMethod` | Telex / Simple Telex / VNI profiles |
| `ToneStyle`, `VietnameseCharacters`, `Tone`, `BufferAtom`, `DiacriticalMark` | supporting rule and data types |

Example: feeding the engine the characters `v`, `i`, `e`, `j`, `e`, `t` with
input method Telex and encoding `unicode` yields a buffer of `việt`, and the
output instructs the caller to replace the current focused text.

## Encoding conversion

| Type | Public surface |
|---|---|
| `Converter` | conversion entry point between encodings |
| `ConverterTransform` | transform cases (e.g. Unicode ↔ legacy) |
| `ConverterConfiguration` | source/destination encoding pair |
| `VietnameseEncoding` (protocol), `EncodingFactory` | public encoding protocol and factory; the shared codec (`EncodingCodec`) is internal to EasyEngineCore |
| `UnicodePrecomposedEncoding`, `UnicodeCombiningEncoding`, `VNIWindowsEncoding`, `TCVN3Encoding`, `CP1258Encoding` | concrete encodings |

## Macros

| Type | Public surface |
|---|---|
| `Macro` | `id`, `trigger`, `expansion`, `isEnabled`, `category`, `createdAt`, `updatedAt` |
| `MacroStore` | `add(trigger:expansion:isEnabled:category:now:)`, `edit`, `delete(id:)`, `replaceAll`, `insertSamples(_:)`, `search(_:)`, `changeActiveEncoding(to:)`, `encodedExpansion(for:)`, `expansion(forTypedTrigger:autoCapitalize:)`, `export(to:)`, `exportTSV()`, `previewImport(from:)`, `apply(_:resolvingConflicts:)`, `macros`; limits `maximumTriggerLength = 128`, `maximumExpansionLength = 16384` |
| `MacroCategory` | language zones: `vietnamese`, `english`, `nineX`, `genZ`, `both` |
| `MacroStoreError`, `MacroImportPreview`, `MacroImportResolution`, `MacroImportConflict` | validation and import result types |

## Smart Switch

| Type | Public surface |
|---|---|
| `SmartSwitchStore` | `handleAppFocus(_:currentChoice:now:) throws -> SmartSwitchFocusResult`, `choice(for:)`, `updateChoice`, `edit(key:choice:)`, `reset(key:)`, `clearAll()`, `flush()`, `preferences`, `search(_:)` |
| `SmartSwitchPreference` | `key`, `displayName`, `choice`, `lastUsedAt` (the per-app record) |
| `SmartSwitchChoice` | `language`, `encoding?` |
| `SmartSwitchOptions` | `enabled`, `rememberEncoding`, `perApplicationValues` |
| `ApplicationIdentity` | `bundleIdentifier?`, `path?`, `name?` → `stableKey` (`bundle:` / `path:` / `name:`) |
| `SmartSwitchFocusResult`, `SmartSwitchStoreError` | outcomes and errors |

## Clipboard

| Type | Public surface |
|---|---|
| `ClipboardEntry` | `id`, `fingerprint`, `capturedAt`, `source?`, `isPinned`, `items`, derived `kind` and `searchableText` |
| `ClipboardItem` | `kind`, `preview`, `representations` |
| `ClipboardItemPreview` | display projection (never used to restore payloads) |
| `ClipboardRepresentation` | `.string(typeIdentifier:value:)`, `.data(typeIdentifier:payloadReference:)`, `.fileURL(URL)` |
| `ClipboardContentKind` | `text`, `url`, `image`, `file`, `video`, `mixed`; `capturable` set |
| `ClipboardSource` | best-effort `applicationName?` / `bundleIdentifier?` — advisory, macOS exposes no pasteboard source |
| `ClipboardOptions` | capture policy (see [configuration.md](configuration.md)) |
| `ClipboardSelectionAction`, `ClipboardPinResult`, `ClipboardHistory` | actions and history container |

## Translation

| Type | Public surface |
|---|---|
| `TranslationProviderID` | `automatic`, `apple`, `deepL`, `google`, `openAI`, `anthropic`, `gemini`, `openRouter`, `groq`, `openAICompatible`, `anthropicCompatible` |
| `TranslationProviderResolver` | `availability(of:platformCapability:configuredCloudProviders:)`, `availableProviders(...)`, `resolveEffectiveProvider(preferredProviderID:platformCapability:configuredCloudProviders:) -> TranslationProviderResolution`, `cloudProviderOrder` |
| `TranslationLanguage` | `init?(bcp47:)`, `identifier`, `english`, `vietnamese` |
| `TranslationPlatformCapability` | `supportsAppleTranslation` |
| `TranslationOptions` | full policy surface — defaults and validation in [configuration.md](configuration.md) |
| `TranslationLanguagePolicy` | `swapped(source:target:)`, `defaultTarget(forInput:)` |
| `TranslationRequest`, `TranslationResponse`, `TranslationError`, `SupportedLanguages` | request/response model, error cases, language catalog |
| `TranslationProviding` | per-provider `translate(_:) async throws -> TranslationResponse`; cloud providers authenticate with an API key resolved from the Keychain-backed credential store (`TranslationCredentialStore`) and sent in the provider-specific request header (`x-goog-api-key`, `Authorization: Bearer`, etc.); the Apple on-device provider needs no credential |

## Settings

| Type | Public surface |
|---|---|
| `EasyKeySettings` | `schemaVersion` (currently 11) + 9 option groups (`input`, `typing`, `macro`, `compatibility`, `smartSwitch`, `system`, `converter`, `clipboard`, `translation`); forgiving decoder |
| `SettingsRepository` | `init(fileURL:)`, `settings` (public read-only current configuration), `update(_:)`, `reset()`, `export(to:)`, `import(from:)`, `load()`, `saveNow()`, `onSettingsChange`, `defaultFileURL`, `maxImportFileBytes = 1_048_576` |
| `SettingsDelta` | `delta(from:to:)` — per-group change flags, `hasAnyChange` |
| `Shortcut` | key code + modifier option set; `none`, `modifiersOnly`, `isActive`, `displayLabel` |
| `SettingsRepositoryError`, `ImportDiagnostics` | import validation errors and diagnostics |
| `InputSettings`, `TypingOptions`, `MacroOptions`, `CompatibilityOptions`, `SystemOptions`, `ConverterOptions`, `ClipboardOptions`, `TranslationOptions` | per-group option structs |

Schema migration (`SettingsMigration`, the stepwise `schemaVersion` bump) is
internal to EasyEngineCore — it is no longer public API, though the
version-bump loop remains exercised by tests.

## Diagnostics

| Type | Public surface |
|---|---|
| `AppLog` | `logger(_ category:) -> Logger` for categories `app`, `engine`, `keyboard`, `synth`, `smartSwitch`, `settings`, `update`, `loginItem`, `translation`; subsystem `one.ifelse.easykey`; never logs keystroke content |
| `AppIdentifiers` | `main = "one.ifelse.easykey"`, `loginHelper` |

## Keyboard adapters (EasyKeyKit)

| Type | Public surface |
|---|---|
| `KeyboardService` | `start()`, `stop()`, `update(settings:)`, `update(macros:)`, `togglePause()`, `setPaused(_:)`, `requestAccessibilityPermission()`, `refreshPermission()`, `setActiveApplication(_:)`, `refreshInputSource()`, `resetSession()`, `setCmdCDoublePressHandler(windowMs:handler:)`, `clearCmdCDoublePressHandler()`, `medianCallbackLatencyNanoseconds() -> UInt64?`, `health`, `isComposing`; `Health` and `Diagnostic` types; `defaultEmergencyPauseShortcut` |
| `KeySynthesizer` | `postBackspace(proxy:count:)`, `postUnicodeText(proxy:_:)`, `postPhysicalKey(proxy:keyCode:modifiers:)`, `postShiftLeft(proxy:count:)`, `isSelfPosted(_:)`, `markAsSelfPosted(_:)` |
| `KeyboardEventTap`, `KeyboardInputPipeline`, `KeyboardDiagnosticsRecorder`, `FocusedElementInspector`, `SpotlightWindowDetector` | event tap binding, pipeline, diagnostics ring buffer, AX focus inspection, Spotlight window polling |

## App compatibility rules

| Type | Public surface |
|---|---|
| `AppCompatibility` | `rules` (fixed rules: Safari `unicodeCombiningOutput`, Spotlight `spotlightSelection`, VSCode `alternateEmptyCharacter`), `rule(for:compatibilityModeApplicationBundleIdentifiers:)` |
| `AppCompatibilityRule` | `bundleIdentifier`, `workarounds` set (also `emptyCharacterInsertion`, `chromium`, `unicodeCombiningOutput`, `spotlightSelection`, `alternateEmptyCharacter`) |

## Deprecated API

| Operation | Deprecated in | Removed in | Replacement |
|---|---|---|---|
| none | — | — | — |

No API is currently deprecated; removals of internal settings keys (for
example the legacy `chromiumBrowserBundleIdentifiers` and
`quickStartEndConsonant` decode aliases) are handled by tolerant decoding
inside the option structs, not by public API churn.
