# Reference

_Last reviewed: 2026-08-15_

This file is the lookup table for EasyKey: what every setting controls, which versions the stack is built from, what is supported and tested, and the limitations to read before building on the project. Reach for it when you need a fact, not an explanation — the explanations live in the architecture, product, and engineering sections.

## At a glance

This section covers the facts of the repository: configuration surfaces and settings, known limitations and trade-offs, and the declared tech stack. The public API surface of `EasyEngineCore` and `EasyKeyKit`, framework-level compatibility, and OS/architecture compatibility are documented in separate files under `reference/`. Every version or minimum stated here is backed by declared evidence (build settings, manifests, or test suites) rather than aspiration.

## Scope and boundaries

This section owns *facts and limits*: what is configured, supported, tested, and named. It does not own how the system is designed ([architecture](architecture.md)), the workflows for building and releasing ([engineering](engineering.md)), or the product story ([product](product.md)). Where a fact is claimed, the owning document states its evidence; this page only routes to it.

| You want to | Read |
|---|---|
| Check what is unsupported or deliberately limited before building on it | [Limitations](#limitations) below |
| Use the public API of the in-repo frameworks | [api.md](reference/api.md) |
| Check which frameworks are supported and tested | [compatibility.md](reference/compatibility.md) |
| Check OS, architecture, and build-form minimums | [platform-compatibility.md](reference/platform-compatibility.md) |

## Configuration

EasyKey reads two configuration surfaces: a JSON settings document on disk (`settings.json`, owned by `SettingsRepository`) and a handful of `UserDefaults` keys owned by the app layer. Cloud credentials never appear in either — they live in the Keychain (see [permissions](security/permissions.md)). Release-time behavior is additionally parameterized by CI environment variables documented at the end. `Sensitive` means "must not be logged or committed"; every row below defaults to `No` unless marked.

Ordered by how often a reader tunes each setting.

### Input and typing

Source: `EasyKeySettings.input` / `EasyKeySettings.typing` (`InputSettings.swift`, `TypingOptions.swift`). Shortcuts are the `Shortcut` struct (key code + modifiers) from `Shortcut.swift`; `Shortcut.none` means disabled.

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

### Translation

Source: `EasyKeySettings.translation` (`TranslationOptions.swift`). The default preferred provider is Apple (`.apple`). Selecting "Automatic" stores `nil`, resolved per-launch by `TranslationProviderResolver.resolveEffectiveProvider` — Apple on macOS 15+, otherwise the first configured cloud provider in `cloudProviderOrder`. API keys are Keychain items, never settings.

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

### Clipboard

Source: `EasyKeySettings.clipboard` (`ClipboardOptions.swift`). The clipboard manager is off by default; capture filters by `ClipboardContentKind.capturable` (text, url, image, file, video — `mixed` is derived, never filtered).

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

### Macros

Source: `EasyKeySettings.macro` (`MacroOptions.swift`) plus per-macro state in `MacroStore` (trigger/expansion/enabled/category; see `MacroStore.swift`). Validation limits: trigger ≤ 128 characters, expansion ≤ 16384 characters.

| Setting | Source | Default | Scope | Sensitive |
|---|---|---|---|---|
| Macros enabled | `macro.enabled` | `false` | settings document | No |
| Auto-capitalize expansions | `macro.autoCapitalize` | `false` | settings document | No |

Which input languages a macro applies to is per-macro (`Macro.category`: `vietnamese`, `english`, `nineX`, `genZ`, or `both`), not a global option.

### Smart Switch

Source: `EasyKeySettings.smartSwitch` (`SmartSwitchOptions.swift`). Per-application values are keyed by `SmartSwitchStore`'s stable application key (`bundle:` / `path:` / `name:`), stored in a separate Smart Switch document.

| Setting | Source | Default | Scope | Sensitive |
|---|---|---|---|---|
| Smart Switch enabled | `smartSwitch.enabled` | `false` | settings document | No |
| Remember encoding per app | `smartSwitch.rememberEncoding` | `false` | settings document | No |
| Per-application overrides | `smartSwitch.perApplicationValues` | `[:]` | settings document + Smart Switch document | No |

### Compatibility

Source: `EasyKeySettings.compatibility` (`CompatibilityOptions.swift`). Defaults put Chromium browsers in compatibility mode; `AppCompatibility` in EasyKeyKit applies fixed per-app workarounds for Safari, Spotlight, and VSCode.

| Setting | Source | Default | Scope | Sensitive |
|---|---|---|---|---|
| Other-language support | `compatibility.otherLanguageSupport` | `false` | settings document | No |
| Compatibility-mode applications | `compatibility.compatibilityModeApplicationBundleIdentifiers` | `com.google.Chrome`, `org.chromium.Chromium` | settings document | No |
| Ignored applications | `compatibility.ignoredApplicationBundleIdentifiers` | `[]` | settings document | No |

### System

Source: `EasyKeySettings.system` (`SystemOptions.swift`). `launchAtLogin` is applied via `SMAppService.loginItem` in `LoginItemController.swift`; menu popover widths are raw pixel values (280–640).

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

### Converter

Source: `EasyKeySettings.converter` (`ConverterOptions.swift`).

| Setting | Source | Default | Scope | Sensitive |
|---|---|---|---|---|
| Source encoding | `converter.sourceEncoding` | `unicode` | settings document | No |
| Destination encoding | `converter.destinationEncoding` | `unicode` | settings document | No |

### Interface language and onboarding

`UserDefaults.standard` keys owned by the app layer — not part of `settings.json`:

| Setting | Source | Default | Scope | Sensitive |
|---|---|---|---|---|
| Interface language | `UserDefaults` key `interfaceLanguage` (shared with legacy `@AppStorage`) | `vietnamese` when unset | `EasyKeyApp/Localization/AppLanguage.swift` | No |
| Onboarding completed | `UserDefaults` key `hasCompletedOnboarding` | unset; `--ui-skip-onboarding` sets it under `--uitesting` | `EasyKeyApp/AppDelegate.swift` | No |

Values for `interfaceLanguage` are `system`, `en`, or `vi` (`AppLanguage.load(from:)`); the system value resolves through `Locale.preferredLanguages`.

### Panel display preferences

Transient panel state persisted per-surface in `UserDefaults.standard`:

| Setting | Source | Default | Scope | Sensitive |
|---|---|---|---|---|
| Clipboard panel keep-on-top | `UserDefaults` key `panel.clipboard.keepOnTop` | `false` | `ClipboardPanelPresenter` | No |
| Translation panel keep-on-top | `UserDefaults` key `panel.translation.keepOnTop` | `false` | `TranslationPanelPresenter` | No |

### Settings document

`SettingsRepository` persists `EasyKeySettings` as JSON at `~/Library/Application Support/EasyKey/settings.json` (Application Support, falling back to Caches, then temp). Writes are atomic, pretty-printed, sorted-key, debounced 300 ms, and queued on a serial utility queue. Every root field decodes with `decodeIfPresent` and its current default, so older documents migrate without resetting unrelated preferences; `schemaVersion` is currently 11. Import validation: file size ≤ 1 MiB (`SettingsRepository.maxImportFileBytes`), schema version ≤ current, otherwise `SettingsRepositoryError`. The app layer wraps the repository in the `@MainActor` `SettingsStore` (`ObservableObject`), which exposes `update`, key-path `binding`, `reset`, `export`, `import`, `load`, and `saveNow`.

### Release pipeline environment

Release builds read build-setting substitutions and CI variables — documented end-to-end in [distribution.md](operations/distribution.md); local builds leave feed and key values empty so Sparkle is disabled rather than pointed at an untrusted endpoint (`UpdateService.hasReleaseConfiguration` rejects placeholder `$(` values). The release workflow currently runs `make local-dmg` — ad-hoc signed, not notarized — because Developer ID signing and notarization are staged but disabled pending an Apple certificate; the certificate-import step was removed from the release workflow and `make dmg` remains the fully signed path for when it is re-enabled. Secrets are never printed and never committed; they are injected by the CI secret environment at release time.

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

## Limitations

Read this before building on EasyKey. Several limits are deliberate consequences of macOS platform behavior or of the app's privacy posture — they are trade-offs, not defects.

### Known limitations

Design constraints and deliberate trade-offs — the shape of the system, not defects.

| Area | Limitation | Impact | Workaround | Tracking |
|---|---|---|---|---|
| Spotlight typing | Typing Vietnamese into Spotlight (`⌘Space`) can look briefly broken right after opening it, then self-correct. Spotlight never activates as an application, so the only dependable signal that keystrokes are going to it is an on-screen window owned by the `Spotlight` process; EasyKey polls `CGWindowListCopyWindowInfo` for that window (0.3 s detection cache) and switches composition to a selection-replacement workaround instead of plain backspaces. | Users who start typing immediately after invoking Spotlight see a moment of literal keystrokes or duplicated characters before the detector catches up. | Pause a beat before typing, or retype; restarting EasyKey helps if it persists. No API exists to fix it from outside Spotlight. | This page |
| Ignored-applications filtering | The ignored-application lists (typing and clipboard) are best-effort filters, not a security boundary: macOS cannot always identify the source application of a clipboard change or focus event. | Content copied in an ignored app can still be captured; typing rules can still apply where a filter missed the app. | Do not rely on these lists for confidentiality; disable capture entirely when it matters. | [product](product.md), `ClipboardSource` in `ClipboardEntry.swift` |
| Clipboard source attribution | `ClipboardSource.applicationName` / `bundleIdentifier` are advisory: macOS exposes no pasteboard source, so attribution can be missing or wrong. | The clipboard panel may show no source or a misattributed one. | Treat source display as informational only. | `ClipboardEntry.swift` |
| Accessory app windows | The app runs as an accessory (`LSUIElement`, activation policy `.accessory`), so its windows do not appear in the Dock or Cmd-Tab and cannot reliably become the key window in normal operation. | Users cannot switch to EasyKey like a regular app; paste-in-place and panel focus depend on panel subclasses overriding `canBecomeKey`. | Panels are presented from the menu bar; Settings opens from the menu. No workaround needed for normal use. | `AppDelegate.swift`, `Info.plist` |
| Apple Translation availability | On-device Apple Translation exists only on macOS 15+ (`AppTranslationRuntime` builds the Apple provider only under `if #available(macOS 15.0, *)` and constructs `TranslationPlatformCapability(supportsAppleTranslation: false)` on older systems). On macOS 14 the Apple provider is unsupported and Automatic resolution falls back to a configured cloud provider. | macOS 14 users get no on-device translation option. | Configure a cloud provider, or leave translation off. | `AppTranslationRuntime.swift`, `TranslationPlatformCapability.swift` |
| Ad-hoc signed distribution | Current public builds are universal and ad-hoc signed but not Developer ID notarized. | Gatekeeper blocks first launch with an "unidentified developer" warning. | Control-click → Open, or System Settings → Privacy & Security → Open Anyway. | [distribution.md](operations/distribution.md) |

### Known issues

Defects under investigation.

| Issue | Symptom | Affected versions | Status |
|---|---|---|---|
| Headless CI hit-testing | Real-window click-then-verify-effect UI tests cannot reliably run on hosted macOS CI runners: the accessibility tree is queryable and `isHittable` reports true, but window activation never lands, so tests flake or fail. EasyKey therefore activates as a `.regular` app under `--uitesting`. | CI only; not a shipped-app behavior | Known; the affected test shard is executed but never blocks merge (the CI workflow's `ui-known-broken-on-hosted-runner` shard runs with `continue-on-error`; see the [Makefile](../Makefile) shard filters and the AppDelegate comment). |
| Parallel UI test shards | `make test-parallel` runs its shards serially on one Mac because every shard launches the same `EasyKey.app` bundle (`EasyKeyTests` is app-hosted via `TEST_HOST`), so concurrent shards would kill each other's app instances mid-test ("Lost connection to the application"). | Local runs of the sharded target | Known; `make test` (serial) is the reliable local default; CI runs each shard on its own runner and can parallelize. |
| Spotlight startup detection race | The `CGWindowListCopyWindowInfo` poll does not see the Spotlight panel instantly; keystrokes in that gap bypass the workaround. | All macOS versions | Documented platform behavior, not fixable from outside Spotlight. |

### Not supported

Things a reasonable person expects and will not find.

- Input Method Kit input sources. EasyKey uses a `CGEvent` tap plus the Accessibility API instead — a deliberate architecture choice (see [product](product.md)); no IMK input source is produced.
- Any non-macOS platform. The deployment target is macOS 14.0+ (`MACOSX_DEPLOYMENT_TARGET`, `LSMinimumSystemVersion`); the build defines no iOS, iPadOS, or other Apple-platform targets in the Xcode project.
- Cloud-translation proxying. EasyKey sends source text directly to the selected provider from translation surfaces only; there is no EasyKey relay server, and this is a privacy feature, not a gap.
- Notarized distribution as of the current public release. The release pipeline is wired for Developer ID signing and notarization (see [distribution.md](operations/distribution.md)) but requires certificate and notary credentials that current builds do not ship with.
- Synchronizing or cloud-backed clipboard history. Persisted history is AES-GCM sealed with a device-only, non-synchronizing Keychain key (`ClipboardKeyStore`); no clipboard data leaves the device.

### Scale and performance envelope

| Dimension | Tested limit | Notes |
|---|---|---|
| Clipboard entries per history | Default 100 (`ClipboardOptions.maximumEntryCount`), configurable | Beyond the cap, oldest unpinned entries are trimmed (retention default 7 days). |
| Settings import file size | 1 MiB (`SettingsRepository.maxImportFileBytes`) | Larger files are rejected with `SettingsRepositoryError.importFileTooLarge`. |
| Macro trigger length | 128 characters (`MacroStore.maximumTriggerLength`) | Longer triggers are rejected at add/edit. |
| Macro expansion length | 16384 characters (`MacroStore.maximumExpansionLength`) | Beyond this the store refuses to save. |
| Auto-translate delay presets | 250–1500 ms (`TranslationOptions.AutoTranslateDelayPreset`) | Values outside presets are rejected by the settings model. |
| Keyboard callback latency | Measured, surfaced via `KeyboardService.medianCallbackLatencyNanoseconds` and the System health card | No published upper bound; latency tests assert no unbounded growth during sustained typing. |

Beyond these figures the system is untested rather than known to fail.

### Deployment-specific caveats

- On macOS 14, translation settings expose cloud providers only; the Apple card is hidden because the platform capability is false.
- Release verification in [distribution.md](operations/distribution.md) covers the artifact checks (`verify-arch.sh` for both architectures, `verify-release.sh` for bundled LICENSE/NOTICE/THIRD_PARTY_NOTICES, and spctl assessment on the signed path).
- `make test-parallel` is a sharded convenience; treat its failures as suspicious until confirmed by a serial `make test` run.
- Spotlight behavior notes above apply to every macOS version EasyKey supports.

## Technology stack

Declared versions where the repository states them; otherwise marked unavailable rather than inferred from imports. Layer grouping follows what a maintainer would change together.

| Layer | Technology | Version | Evidence path |
|---|---|---|---|
| Language | Swift, Swift 5 language mode | Swift 5.0 (`SWIFT_VERSION`); Xcode 15+ required | `EasyKey.xcodeproj/project.pbxproj`, the engineering rulebook (notes/rulebook.md), [setup](engineering.md) |
| Minimum OS | macOS | 14.0 (`MACOSX_DEPLOYMENT_TARGET`, `LSMinimumSystemVersion`) | `EasyKey.xcodeproj/project.pbxproj`, `EasyKeyApp/Info.plist` |
| Application shell | SwiftUI + AppKit (`NSApplicationDelegate`, `NSPanel` subclasses, `NSWorkspace`) | system SDK | `EasyKeyApp/` |
| Domain logic | EasyEngineCore — framework-free typing, settings, macros, smart switch, converter, clipboard, translation | in-repo, no external dependency | `EasyEngineCore/` |
| Keyboard adapters | EasyKeyKit — `CGEvent` tap, Accessibility focus, event synthesis | in-repo | `EasyKeyKit/` |
| Reactive | Combine (`ObservableObject`/`@Published`) | system SDK | `EasyKeyApp/Settings/SettingsStore.swift` |
| Logging | OSLog (`Logger`, subsystem `one.ifelse.easykey`) | system SDK | `EasyEngineCore/Diagnostics/AppLog.swift` |
| Crypto | CryptoKit AES-GCM (clipboard persistence) | system SDK | `EasyKeyApp/Features/Clipboard/ClipboardPersistence.swift` |
| System integration | ServiceManagement (`SMAppService.loginItem`) | system SDK | `EasyKeyApp/Coordination/LoginItemController.swift` |
| In-app purchases | StoreKit | not used | absence of StoreKit imports in `EasyKeyApp/`, `EasyKeyKit/`, `EasyEngineCore/` |
| Updates | Sparkle 2 (SPM package, pinned exact 2.9.4; EdDSA-signed appcast) | 2.9.4 | `EasyKey.xcodeproj/project.pbxproj`, THIRD_PARTY_NOTICES.md, `EasyKeyApp/Coordination/UpdateService.swift` |
| Persistence | Foundation `JSONEncoder`/`JSONDecoder` documents (`settings.json`, macro and Smart Switch documents) | system SDK | `EasyEngineCore/Settings/SettingsRepository.swift`, `SmartSwitchStore.swift`, `MacroStore.swift` |
| Unit tests | XCTest | system SDK | `EasyKeyTests/` |
| UI tests | XCUITest | system SDK | `EasyKeyUITests/` |
| Static analysis | SwiftLint + SwiftFormat (configs kept in sync; installed via Homebrew) | unavailable (Homebrew-managed) | `.swiftlint.yml`, `.swiftformat`, `Makefile` |
| CI pipeline | Hosted macOS runners; parallel test shards (unit + UI shards) with merged coverage gate | runner image macOS 15 (declared in CI workflow); coverage gate and shard grouping mirrored in `Makefile` | `Makefile`, [product](product.md) |
| Build orchestration | `make` + `xcodebuild` (`EasyKey.xcodeproj`, scheme `EasyKeyApp`) | makefile-defined | `Makefile` |
| Release packaging | Shell scripts (`Scripts/*.sh`: archive, export, notarize, staple, DMG, verify) + Python 3 stdlib-only appcast generator | Python 3, stdlib only | `Scripts/generate-appcast.py`, [distribution.md](operations/distribution.md) |

### Language and toolchain

Swift compiles in Swift 5 language mode across all targets (`SWIFT_VERSION = 5.0`); the engineering rulebook (notes/rulebook.md) forbids introducing Swift 6-only syntax without an explicit migration. Xcode 15+ is the documented build requirement ([setup](engineering.md)); the CI pipeline selects the latest stable Xcode (`setup-xcode` `latest-stable`) on macOS 15 runners. The only external Swift package is Sparkle, pinned to exact version 2.9.4.

### Frameworks

The app deliberately keeps Apple frameworks at the edges: `EasyEngineCore` has no AppKit, SwiftUI, or Combine dependency (architecture rule enforced by `ArchitectureFitnessTests`), `EasyKeyKit` adapts the domain to macOS event taps and accessibility, and `EasyKeyApp` owns UI, localization, coordination, and updates. Combine appears only at the app layer (`SettingsStore`, an `ObservableObject`); CryptoKit only in clipboard persistence; ServiceManagement only in the login-item controller; Sparkle only in `UpdateService`. StoreKit is not used — there are no purchases in the app.

### Persistence

All persistent documents are Foundation JSON written atomically: settings (`settings.json` under Application Support, debounced 300 ms), macros (`MacroStore`), Smart Switch preferences (`SmartSwitchStore`, schema-versioned document), and optionally encrypted clipboard history. `UserDefaults` is used only for a small app-layer set: interface language, onboarding completion, and panel keep-on-top flags.

### Testing and quality

XCTest unit suites cover the domain and app layers; XCUITest suites cover settings, onboarding, and workflows. The CI pipeline splits tests into per-runner parallel shards, merges the result bundles, and enforces a 90% line-coverage gate (excluding the login helper); locally `make test-parallel` runs a coarser grouping (one unit shard + three UI shards) serially, because every shard launches the same `EasyKey.app` bundle and concurrent shards would kill each other's app instances (see the Makefile note). SwiftLint and SwiftFormat configurations live at the repo root and are kept in sync with each other (`.swiftlint.yml` ↔ `.swiftformat`); `make lint` / `make format` run them when installed.

### Build and release

`make` wraps `xcodebuild` for build, test, coverage, QA, and release targets (`make qa`, `make local-dmg`, `make dmg`). Release packaging is shell scripts under `Scripts/` (archive, export, notarize, staple, DMG creation, arch verification) plus one Python 3 script, `Scripts/generate-appcast.py`, which appends signed items to the Sparkle appcast. The release pipeline is parameterized by CI variables and secrets — see [distribution.md](operations/distribution.md) and the configuration reference above.

### Why this stack shape

The three-layer split (app / kit / core) exists so the typing domain can be tested and reasoned about with no macOS dependencies at all, which is what makes the 90% coverage gate and the fixture-driven conformance tests practical. Native frameworks plus a single pinned update dependency keep the attack and dependency surface small for an accessibility-permission app that deliberately avoids analytics and telemetry.

## Related sections

- [Architecture](architecture.md) — the design that these facts constrain and describe.
- [Engineering](engineering.md) — the workflows that consume these versions and minimums.
- [Operations](operations/README.md) — the deployment and distribution facts these minimums feed into.
- [Product](product.md) — the product story the reference facts describe.
