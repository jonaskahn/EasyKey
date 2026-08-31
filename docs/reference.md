# Reference

_Last reviewed: 2026-08-27_

Lookup for EasyKey settings, known limits, declared stack, and compatibility. Engineers use it to see what a preference actually reads; beginners use it to see defaults and why a change can do nothing. Typing, launch, and threat detail live in sibling sections, not here.

## At a glance

| Need | Section |
|---|---|
| Which preference wins, default, and why a toggle did nothing | [Configuration](#configuration) |
| What the product will not do, and numeric caps | [Limitations](#limitations) |
| Languages, frameworks, CI, Sparkle | [Technology stack](#technology-stack) |
| Domain words used in other docs | [Glossary](#glossary) |
| Caller HTTP/SDK surface | [API reference](#api-reference) |
| Library versions this repo pins | [Library compatibility](#library-compatibility) |
| OS, Mac, architecture | [Platform compatibility](#platform-compatibility) |

Reading paths: settings and defaults here; structure in [architecture.md](architecture.md); how to build in [engineering.md](engineering.md); threats and Keychain in [security.md](security.md); end-to-end order in [flows.md](flows.md). Parent index: [README.md](README.md).

## Scope and boundaries

This file owns configuration lookup, the limitations register, declared stack, glossary pointers, and the profile sections below. It does not own first-run install ([engineering.md](engineering.md)), hard architectural bounds ([architecture.md](#constraints)), remediable debt ([architecture.md](#technical-debt)), or permission/TCC lifecycle ([security.md](security.md)). Compact layout has no extra files under a `docs/reference/` folder.

## Configuration

Precedence (first match wins): (1) in-memory store after a Settings change; (2) `settings.json` under Application Support `EasyKey/` (Caches, then temp, if Application Support is missing); (3) `EasyKeySettings` struct defaults when the file is absent or invalid. Schema version **11**; missing keys decode to current defaults. Interface language is a separate UserDefaults key (`interfaceLanguage`), not that JSON. Bundle keys (minimum OS, Sparkle feed, support URL) are compile-time product config; the Settings UI cannot override them. Clipboard byte/pin caps and concealed-pasteboard rejection are policy, not preferences. Import of a settings file refuses payloads over **1 048 576** bytes. Translation API keys are Keychain items, never settings JSON.

**Why a change can have no effect:** Apple as preferred provider on macOS 14 is unsupported; clipboard and translation stay inert while their enable flags are off; `Check for updates` is stored but Sparkle still starts when the feed and EdDSA key resolve.

| Setting | Default | Scope | Sensitivity | Validation |
|---|---|---|---|---|
| Input language | Vietnamese | typing JSON | public | `vietnamese` \| `english` |
| Input method | Simple Telex | typing JSON | public | Telex, Simple Telex, VNI |
| Typing encoding | Unicode | typing JSON | public | Unicode, Unicode combining, TCVN3, VNI Windows, CP1258 |
| Switch-language shortcut | Option+Z | typing JSON | public | captured shortcut; reserved system chords refused |
| Spell check | on | typing JSON | public | bool |
| Restore invalid word | on | typing JSON | public | bool |
| Tone style | old | typing JSON | public | old \| new |
| Quick Telex consonants | off | typing JSON | public | bool |
| Standalone W shortcut | on | typing JSON | public | bool |
| Bracket shortcuts | on | typing JSON | public | bool |
| Restore-word shortcut | none | typing JSON | public | shortcut or none |
| Uppercase first character | off | typing JSON | public | bool |
| Live confidence scoring | off | typing JSON | public | bool; bands 0.35 / 0.80; advisory only |
| iOS UniKey-like mode | on | typing JSON | public | bool |
| Literal technical tokens | on | typing JSON | public | bool |
| Ignore function keys | on | typing JSON | public | bool |
| Converter source / destination | Unicode / Unicode | encoding JSON | public | same encoding enum |
| Smart Switch | off | smart-switch JSON | public | bool; optional per-app language+encoding |
| Remember encoding with Smart Switch | off | smart-switch JSON | public | bool |
| Translation feature | off | translation JSON | public | bool; no network until on and a provider is available |
| Preferred translation provider | Apple | translation JSON | public | Apple ignored on macOS 14; `automatic` stored as unset |
| Translate shortcut | Option+C | translation JSON | public | shortcut |
| Default source language | auto (`nil`) | translation JSON | public | BCP-47; built-in `en` / `vi` helpers |
| Show translation in menu popover | off | translation JSON | public | bool |
| Double ⌘C to translate | off | translation JSON | public | window 400 ms |
| Auto-translate delay | 500 ms | translation JSON | public | 250 / 500 / 750 / 1000 / 1500 |
| Translate panel size | medium | translation JSON | public | compact…extraLarge |
| Session persistence | keep until restart | translation JSON | public | clear on close \| keep |
| DeepL endpoint | free | translation JSON | public | free \| pro |
| Cloud model identifiers | gpt-4o-mini; claude-haiku-4-5; gemini-2.0-flash; openai/gpt-4o-mini; llama-3.1-8b-instant | translation JSON | public | strings; compatible endpoints default empty |
| Cloud disclosure acknowledgements | empty | translation JSON | public | provider ids only; not content |
| Clipboard capture | off | clipboard JSON | public | bool |
| Clipboard shortcut | Option+V | clipboard JSON | public | shortcut |
| Selection action | paste immediately | clipboard JSON | public | paste immediately \| copy only |
| History size | 100 | clipboard JSON | public | picker 50 / 100 / 200 / 500 |
| Retention days | 7 | clipboard JSON | public | picker 1 / 7 / 14 / 30 |
| Persist clipboard history | off | clipboard JSON | public | bool; AES-GCM + Keychain when on |
| Captured kinds | all capturable | clipboard JSON | public | kind set |
| Clipboard ignored apps | empty | clipboard JSON | public | bundle ids |
| Macros | off | macros JSON | public | bool |
| Macro auto-capitalize | off | macros JSON | public | bool |
| Other-language support | off | behavior JSON | public | bool |
| Compatibility-mode apps | Chrome, Chromium | behavior JSON | public | bundle ids |
| Ignored apps (typing) | empty | behavior JSON | public | bundle ids |
| Launch at login | off | system JSON | public | SMAppService; helper may fail independently |
| Show Dock icon | off | system JSON | public | bool |
| Gray menu icon | off | system JSON | public | bool |
| Show Settings at launch | off | system JSON | public | bool |
| Check for updates (toggle) | on | system JSON | public | **stored; not wired to Sparkle start** |
| Menu popover width | small (360) | system JSON | public | 280…640 |
| Menu-bar icon style | 9 | system JSON | public | 1–12 |
| Menu-bar icon scale | 130% | system JSON | public | 100–150 step 10 |
| Interface language | Vietnamese if unset | UserDefaults | public | system \| en \| vi; catalogs `en` and `vi` |
| Onboarding completed | unset until finished | UserDefaults | public | bool key `hasCompletedOnboarding` |
| Marketing version | 0.0.14 | bundle | public | `CFBundleShortVersionString` |
| Minimum OS | 14.0 | bundle | public | `LSMinimumSystemVersion` |
| Menu-bar accessory | on | bundle | public | `LSUIElement` |
| Sparkle feed | `the HTTPS appcast URL in the bundle | bundle | public URL | HTTPS; live updater also needs EdDSA key |
| Sparkle EdDSA public key | build/release secret | bundle | **secret value omitted** | required with feed for a live updater |
| Support URL | `the project repository URL (Debug/Release in project) | bundle | public | release workflow may override |
| Privacy-policy URL | empty in project | bundle | public | empty until a release value is supplied |

## Limitations

Entries ordered by how often a reader hits them. Review date on every row: **2026-08-27**. Hard OS/TCC physics: [architecture.md](#constraints). Engineering shortcuts: [architecture.md](#technical-debt).

**Known limitations (deliberate)**

| Trigger | Impact | Workaround | Evidence |
|---|---|---|---|
| README “processed locally” vs shipped updater and optional cloud | Sparkle still fetches an HTTPS appcast and may download a the release archive host DMG; opted-in cloud translation sends source text to that provider | Treat typing/macros as local; treat updates and cloud translation as network | README private-by-design; Sparkle feed + EdDSA; translation off until enabled |
| Clipboard capture default off | Option+V history stays empty until enabled | Settings → Clipboard | `ClipboardOptions.isCaptureEnabled` default false |
| Encrypted clipboard persistence default off | History is RAM-only and lost at quit | Enable persist in Clipboard settings | `persistsHistory` default false |
| Translation feature default off | Option+C / panel does nothing useful until enabled; no cloud until a provider is configured | Settings → Translation; Apple on macOS 15+ needs no key | `TranslationOptions.isEnabled` default false |
| macOS 14 | Apple Translation is not in the provider list (`unsupportedOnPlatform`) | Use an opted-in cloud provider, or run macOS 15+ | `#available(macOS 15.0)` capability; resolver tests |
| Concealed / password-manager pasteboard types | Those copies never enter history | Copy non-sensitive content | fixed identifier set; not a setting |
| Clipboard payload larger than 10 MiB or retained pool 100 MiB | Event dropped or older unpinned entries evicted | Smaller copies; unpin | `ClipboardLimits` |
| 25 pinned clipboard entries | Further pins refused (`pinnedLimitReached`); no silent eviction of pins | Unpin one | `ClipboardHistory.maximumPinnedEntries` |
| UI language catalogs | Only English and Vietnamese strings | System preference maps `vi*` → vi, else en | `AppLanguage.supportedCodes` |
| Not an Input Method Kit IME | Composition is a session event tap, not a system IME | Grant Accessibility; pause in games/terminals via ignored apps | architecture non-goal |

**Known issues (defect or mismatch under investigation)**

| Trigger | Impact | Workaround | Evidence |
|---|---|---|---|
| System “Check for updates” off | Sparkle still starts when feed + EdDSA are configured; only the in-app check button is the explicit check path | Use firewall/network policy, or omit feed/key at build | architecture debt row; UpdateService starts when configured |
| Opening Spotlight (`⌘Space`) | Overlay has no activation event; Chromium workarounds can apply until Spotlight is detected | Wait until Spotlight is visible, then type | pipeline Spotlight resolver; README still warns of a brief glitch; CHANGELOG claims the typing glitch was fixed |

**Not supported (no fix in flight)**

| Trigger | Impact | Workaround | Evidence |
|---|---|---|---|
| iOS, iPadOS, watchOS, visionOS | No app | Use a Mac | macOS deployment target only |
| App Store sandbox as the host is built today | Host is unsandboxed | Direct distribution | architecture constraint |
| Public HTTP API for third-party callers | Nothing to integrate against over the network | None | no OpenAPI; see [API reference](#api-reference) |
| Analytics / telemetry SDK | None shipped | None needed | architecture non-goal |

**Scale and performance envelope (tested numeric bounds)**

| Trigger | Impact | Workaround | Evidence |
|---|---|---|---|
| Clipboard history count | Unpinned entries prune to the selected cap (default 100) | Raise picker 50–500 | `maximumEntryCount` + history tests |
| Clipboard pin cap 25 | Pin refused | Unpin | pin tests |
| Per-event 10 MiB / retained 100 MiB | Skip or trim | Smaller payloads | `ClipboardLimits` |
| Settings import > 1 MiB | Import rejected | Smaller file | `SettingsRepository.maxImportFileBytes` |

No measured CPU/GPU/FPS budgets in-repo; do not treat coverage % as a user envelope.

## Technology stack

Declared versions only (not lockfile transitives). Failure behavior of integrations: [architecture.md](#dependencies).

| Layer | Technology | Declared version / role |
|---|---|---|
| Language | Swift | `SWIFT_VERSION` 5.0 |
| Runtime | macOS AppKit / SwiftUI host | deployment 14.0; accessory `LSUIElement` |
| App | EasyKey.app | menu bar, settings, clipboard, translation, Sparkle, login registration |
| Kit | EasyKeyKit.framework | CGEvent tap and keyboard pipeline |
| Core | EasyEngineCore.framework | Vietnamese engine and settings models; Foundation-only |
| Helper | EasyKeyLoginHelper.app | nested login item; open host then exit |
| On-device MT | Translation.framework | weak-linked; macOS 15+ |
| Cloud MT | URLSession HTTPS | DeepL, Google, OpenAI, Anthropic, Gemini, OpenRouter, Groq, compatible endpoints; no vendor SDK packages |
| Secrets | macOS Keychain | clipboard AES key; translation credentials; this-device |
| Settings store | JSON | Application Support `EasyKey/settings.json` |
| Updates | Sparkle (SPM exact) | **2.9.4**; appcast HTTPS + EdDSA |
| Tests | XCTest + XCUITest | hosted by EasyKey.app; UI tests change activation policy |
| CI | the CI pipeline | `macos-15`; Xcode `latest-stable`; SwiftFormat + SwiftLint |
| Release hosts | HTTPS appcast + DMG enclosure | appcast XML; DMG enclosure |
| Coverage gate | CI badge / workflow | 90% line goal (login helper excluded in architecture) |

## Glossary

Alphabetical by term. Definitions here are pointers; depth lives in the owning document.

| Term | Definition | Owning document |
|---|---|---|
| Accessory / `LSUIElement` | Process with no Dock tile unless the user enables Show Dock icon | [architecture.md](architecture.md) |
| Apple Translation | On-device Translation.framework path; absent on macOS 14 | [Limitations](#limitations) |
| Appcast | Sparkle HTTPS feed listing update enclosures | [architecture.md](architecture.md) |
| Clipboard capture | Pasteboard monitoring; **off** until enabled | [Configuration](#configuration) |
| Compatibility mode | Per-app typing workarounds (default Chrome/Chromium ids) | [Configuration](#configuration) |
| EasyEngineCore | In-process engine and settings types; not a published package | [architecture.md](architecture.md) |
| EasyKeyKit | In-process event-tap pipeline | [architecture.md](architecture.md) |
| Encoding table | Output character set (Unicode, combining, TCVN3, VNI Windows, CP1258) | [Configuration](#configuration) |
| Input language | Vietnamese vs English **typing**, distinct from UI language | [Configuration](#configuration) |
| Interface language | UI `en` / `vi` / follow system | [Configuration](#configuration) |
| Simple Telex | Default input method | [Configuration](#configuration) |
| Smart Switch | Optional per-app remembered language (and encoding) | [Configuration](#configuration) |
| Sparkle | Signed auto-update client; needs feed URL + public EdDSA key | [architecture.md](architecture.md) |
| Telex / VNI | Alternate Vietnamese input methods | [Configuration](#configuration) |

## API reference

Compatibility source: **none**. This repository does not ship `openapi.yaml`, a GraphQL schema, or a versioned public client SDK. EasyEngineCore and EasyKeyKit are embedded Xcode frameworks consumed in-process. Sparkle’s appcast is an update feed (HTTPS GET of XML), not a product REST surface. Auth and rate-limit classes for a caller API do not exist. No deprecated HTTP operations. Error envelope and 429 contracts are unselected (`api_errors` / `api_rate_limits` not in this file’s members).

| Method / path | Purpose | Request | Response | Example | Auth | Rate-limit class | Deprecated |
|---|---|---|---|---|---|---|---|
| — | No public operations | — | — | — | — | — | — |

## Library compatibility

Newest declared pin first. OS minimums: [Platform compatibility](#platform-compatibility). No consumer migration guide (unselected).

| Artifact | Version | Evidence | After support ends |
|---|---|---|---|
| Sparkle | 2.9.4 exact | SPM `exactVersion` + `Package.resolved` 2.9.4 | Unknown; pin must be bumped in the Xcode project |
| Swift language mode | 5.0 | `SWIFT_VERSION` | Unknown |
| EasyEngineCore / EasyKeyKit | unversioned (embedded) | same app binary | Same as the app; not independently versioned for external clients |

Untested library versions are **unknown**, not compatible by default.

## Platform compatibility

| OS | Device | Architecture | Minimum | Evidence | Below minimum | Deprecation horizon |
|---|---|---|---|---|---|---|
| macOS 14.0+ | Mac | Apple silicon | 14.0 | `MACOSX_DEPLOYMENT_TARGET` 14.0; README | Installer/runtime refuse (`LSMinimumSystemVersion`) | Unstated |
| macOS 14.0+ | Mac | Intel | 14.0 | README “Apple silicon or Intel” | Same refuse | Unstated; **CI does not prove Intel** (`macos-15` runners) |
| macOS 15.0+ | Mac | same as above | 15.0 for Apple Translation only | `#available(macOS 15.0)` + resolver tests | App still runs on 14; Apple provider missing | Unstated |

Permissions and TCC: [security.md](security.md).
