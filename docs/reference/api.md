# API reference

_Last reviewed: 2026-08-15_

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

| Framework | Bundle identifier | Version marker | Content |
|---|---|---|---|
| EasyEngineCore | `com.easykey.EasyEngineCore` | none (shares app marketing version) | Typing engine, encodings, converter, macros, Smart Switch, clipboard model, translation model, settings, diagnostics |
| EasyKeyKit | `one.ifelse.easykeyKit` | `EasyKeyKit.version = "0.0.11"` | Keyboard service, event synthesis, compatibility rules |

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
| `EngineOutput` | `disposition` (`pass`/`suppress`), `edits` (`deleteBackward`/`insert`/`replaceBackward`), `sessionEffect` |
| `EngineConfiguration` | `inputMethod`, `outputEncoding`, `spellCheck`, `autoRestoreKeys`, `toneStyle`, `quickTelexConsonants`, `standaloneWShortcut`, `bracketShortcuts`, `uppercaseFirstCharacter`, `liveConfidenceScoring`, `liveConfidenceLowThreshold`, `liveConfidenceHighThreshold`, `iosUniKeyLikeMode`, `literalTechnicalTokens` |
| `SessionState` | composition state exposed by the engine |
| `TelexComposer` | rule application shared by the engine |
| `EncodingTable` | `unicode`, `unicodeCombining`, `tcvn3`, `vniWindows`, `cp1258` |
| `InputLanguage` | `vietnamese`, `english` |
| `InputMethod` | Telex / Simple Telex / VNI profiles |
| `ToneStyle`, `VietnameseCharacters`, `Tone`, `BufferAtom`, `DiacriticalMark` | supporting rule and data types |

Example: feeding the engine the keystrokes `v`, `i`, `e`, `t`, `s` with input
method Telex and encoding `unicode` yields a buffer of `viết`, and the output
instructs the caller to replace the current focused text. This exact case is
one of the conformance fixtures (`Fixtures/sample-telex.json`) exercised by the
test suite.

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

## Deprecated operations

| Operation | Deprecated in | Removed in | Replacement |
|---|---|---|---|
| none | — | — | — |

No API is currently deprecated; removals of internal settings keys (for
example the legacy `chromiumBrowserBundleIdentifiers` and
`quickStartEndConsonant` decode aliases) are handled by tolerant decoding
inside the option structs, not by public API churn.
