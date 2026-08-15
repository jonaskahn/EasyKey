# Tech stack

_Last reviewed: 2026-08-15_

Declared versions where the repository states them; otherwise marked
unavailable rather than inferred from imports. Layer grouping follows what a
maintainer would change together.

| Layer | Technology | Version | Evidence path |
|---|---|---|---|
| Language | Swift, Swift 5 language mode | Swift 5.0 (`SWIFT_VERSION`); Xcode 15+ required | `EasyKey.xcodeproj/project.pbxproj`, the engineering rulebook (notes/rulebook.md), [setup](../engineering/setup.md) |
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
| CI pipeline | Hosted macOS runners; parallel test shards (unit + UI shards) with merged coverage gate | runner image macOS 15 (declared in CI workflow); coverage gate and shard grouping mirrored in `Makefile` | `Makefile`, [product overview](../product/overview.md) |
| Build orchestration | `make` + `xcodebuild` (`EasyKey.xcodeproj`, scheme `EasyKeyApp`) | makefile-defined | `Makefile` |
| Release packaging | Shell scripts (`Scripts/*.sh`: archive, export, notarize, staple, DMG, verify) + Python 3 stdlib-only appcast generator | Python 3, stdlib only | `Scripts/generate-appcast.py`, [distribution.md](../operations/distribution.md) |

## Language and toolchain

Swift compiles in Swift 5 language mode across all targets
(`SWIFT_VERSION = 5.0`); the engineering rulebook (notes/rulebook.md) forbids
introducing Swift 6-only syntax without an explicit migration. Xcode 15+ is
the documented build requirement ([setup](../engineering/setup.md)); the CI
pipeline selects the latest stable Xcode (`setup-xcode` `latest-stable`) on
macOS 15 runners. The only external Swift package is Sparkle, pinned to exact
version 2.9.4.

## Frameworks

The app deliberately keeps Apple frameworks at the edges:
`EasyEngineCore` has no AppKit, SwiftUI, or Combine dependency (architecture
rule enforced by `ArchitectureFitnessTests`), `EasyKeyKit` adapts the domain
to macOS event taps and accessibility, and `EasyKeyApp` owns UI,
localization, coordination, and updates. Combine appears only at the
app layer (`SettingsStore`, an `ObservableObject`); CryptoKit only in clipboard
persistence; ServiceManagement only in the login-item controller; Sparkle
only in `UpdateService`. StoreKit is not used — there are no purchases in
the app.

## Persistence

All persistent documents are Foundation JSON written atomically: settings
(`settings.json` under Application Support, debounced 300 ms), macros
(`MacroStore`), Smart Switch preferences (`SmartSwitchStore`, schema-versioned
document), and optionally encrypted clipboard history. `UserDefaults` is used
only for a small app-layer set: interface language, onboarding completion,
and panel keep-on-top flags.

## Testing and quality

XCTest unit suites cover the domain and app layers; XCUITest suites cover
settings, onboarding, and workflows. The CI pipeline splits tests into
per-runner parallel shards, merges the result bundles, and enforces a 90%
line-coverage gate (excluding the login helper); locally `make test-parallel`
runs a coarser grouping (one unit shard + three UI shards) serially, because
every shard launches the same `EasyKey.app` bundle and concurrent shards
would kill each other's app instances (see the Makefile note). SwiftLint and
SwiftFormat configurations live at the repo root and are kept in sync with
each other (`.swiftlint.yml` ↔ `.swiftformat`); `make lint` / `make format`
run them when installed.

## Build and release

`make` wraps `xcodebuild` for build, test, coverage, QA, and release targets
(`make qa`, `make local-dmg`, `make dmg`). Release packaging is shell scripts
under `Scripts/` (archive, export, notarize, staple, DMG creation, arch
verification) plus one Python 3 script, `Scripts/generate-appcast.py`, which
appends signed items to the Sparkle appcast. The release pipeline is
parameterized by CI variables and secrets — see
[distribution.md](../operations/distribution.md) and the configuration reference.

## Why this stack shape

The three-layer split (app / kit / core) exists so the typing domain can be
tested and reasoned about with no macOS dependencies at all, which is what
makes the 90% coverage gate and the fixture-driven conformance tests
practical. Native frameworks plus a single pinned update dependency keep the
attack and dependency surface small for an accessibility-permission app that
deliberately avoids analytics and telemetry.
