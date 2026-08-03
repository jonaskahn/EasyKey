---
id: "tech_stack"
title: "Tech Stack"
docforge_provenance:
  schema: "2.0"
  doc_id: "tech_stack"
  path: "docs/reference/tech-stack.md"
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
    - id: "tech-stack"
      sources:
        - path: "README.md"
          role: "doc"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
        - path: "EasyKey.xcodeproj/project.pbxproj"
          role: "manifest"
          git_blob: "3fc1f4a80e4851be8a519efbb99f80102a4b41d4"
      unresolved: []
    - id: "language-and-toolchain"
      sources:
        - path: "EasyKey.xcodeproj/project.pbxproj"
          role: "manifest"
          git_blob: "3fc1f4a80e4851be8a519efbb99f80102a4b41d4"
        - path: "docs/_archive/CONVENTIONS.md"
          role: "doc"
          git_blob: "878c15dcb2e9f1fd811a7432688b8b20c6b72512"
        - path: "README.md"
          role: "doc"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
      unresolved: []
    - id: "frameworks"
      sources:
        - path: "EasyEngineCore/Diagnostics/AppLog.swift"
          role: "code"
          git_blob: "5fc4b67c2fd3e17d5ba285cabad24e5e112951fa"
        - path: "EasyKeyApp/Settings/ObservableSettingsStore.swift"
          role: "code"
          git_blob: "c77772d40545b8e15ea62a6ca49d25eace1d355a"
        - path: "EasyKeyApp/Features/Clipboard/ClipboardPersistence.swift"
          role: "code"
          git_blob: "2f2f6e1c7c03071c95010c565309b55a06b15c34"
        - path: "EasyKeyApp/Coordination/LoginItemController.swift"
          role: "code"
          git_blob: "7833a6d82792ded3986386ac26e40b686feab12d"
        - path: "EasyKeyApp/UpdateService.swift"
          role: "code"
          git_blob: "27386d368017c0c64f38e75fbd5e23e62c7a4dd6"
        - path: "docs/_archive/THIRD_PARTY_NOTICES.md"
          role: "doc"
          git_blob: "8c0da23df063ee46dc734994bdd9b6e365eb7a72"
      unresolved: []
    - id: "persistence"
      sources:
        - path: "EasyEngineCore/Settings/SettingsRepository.swift"
          role: "code"
          git_blob: "f718fcf9ea3a84f0aa770650c15c8c059e450a19"
        - path: "EasyEngineCore/SmartSwitch/SmartSwitchStore.swift"
          role: "code"
          git_blob: "694b512e15a06e34e7df216ba74a4fc133e27f69"
        - path: "EasyEngineCore/Macros/MacroStore.swift"
          role: "code"
          git_blob: "b8a7256fcac4629b3824c752dd654f849170de08"
      unresolved: []
    - id: "testing-and-quality"
      sources:
        - path: "Makefile"
          role: "config"
          git_blob: "b8fa0059c061eef05cb083ae69e8e7d46336aa64"
        - path: ".swiftlint.yml"
          role: "config"
          git_blob: "90631d6319ce50e321f2e8f6936145b08d98d92f"
        - path: ".swiftformat"
          role: "config"
          git_blob: "ac27429273e1daa282d4a73177cebd2dae238705"
        - path: "README.md"
          role: "doc"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
      unresolved: []
    - id: "build-and-release"
      sources:
        - path: "Makefile"
          role: "config"
          git_blob: "b8fa0059c061eef05cb083ae69e8e7d46336aa64"
        - path: "Scripts/generate-appcast.py"
          role: "code"
          git_blob: "b11742e9715d352ad971f4ab8d5f3dabf5ef38d9"
        - path: "docs/_archive/RELEASE.md"
          role: "doc"
          git_blob: "c749b17a004e3cf47af6af61e82db4aa9d40494d"
        - path: "EasyKey.xcodeproj/project.pbxproj"
          role: "manifest"
          git_blob: "3fc1f4a80e4851be8a519efbb99f80102a4b41d4"
      unresolved: []
    - id: "why-this-stack-shape"
      sources:
        - path: "README.md"
          role: "doc"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
        - path: "docs/_archive/CONVENTIONS.md"
          role: "doc"
          git_blob: "878c15dcb2e9f1fd811a7432688b8b20c6b72512"
      unresolved: []
---
# Tech stack

_Last reviewed: 2026-08-03_

Declared versions where the repository states them; otherwise marked
unavailable rather than inferred from imports. Layer grouping follows what a
maintainer would change together.

| Layer | Technology | Version | Evidence path |
|---|---|---|---|
| Language | Swift, Swift 5 language mode | Swift 5.0 (`SWIFT_VERSION`); Xcode 15+ required | `EasyKey.xcodeproj/project.pbxproj`, [CONVENTIONS.md](../engineering/conventions.md), [product overview](../product/overview.md) |
| Minimum OS | macOS | 14.0 (`MACOSX_DEPLOYMENT_TARGET`, `LSMinimumSystemVersion`) | `EasyKey.xcodeproj/project.pbxproj`, `EasyKeyApp/Info.plist` |
| Application shell | SwiftUI + AppKit (`NSApplicationDelegate`, `NSPanel` subclasses, `NSWorkspace`) | system SDK | `EasyKeyApp/` |
| Domain logic | EasyEngineCore — framework-free typing, settings, macros, smart switch, converter, clipboard, translation | in-repo, no external dependency | `EasyEngineCore/` |
| Keyboard adapters | EasyKeyKit — `CGEvent` tap, Accessibility focus, event synthesis | in-repo | `EasyKeyKit/` |
| Reactive | Combine (`ObservableObject`/`@Published`) | system SDK | `EasyKeyApp/Settings/ObservableSettingsStore.swift` |
| Logging | OSLog (`Logger`, subsystem `one.ifelse.easykey`) | system SDK | `EasyEngineCore/Diagnostics/AppLog.swift` |
| Crypto | CryptoKit AES-GCM (clipboard persistence) | system SDK | `EasyKeyApp/Features/Clipboard/ClipboardPersistence.swift` |
| System integration | ServiceManagement (`SMAppService.loginItem`) | system SDK | `EasyKeyApp/Coordination/LoginItemController.swift` |
| In-app purchases | StoreKit | not used | absence of StoreKit imports in `EasyKeyApp/`, `EasyKeyKit/`, `EasyEngineCore/` |
| Updates | Sparkle 2 (SPM package, pinned exact 2.9.4; EdDSA-signed appcast) | 2.9.4 | `EasyKey.xcodeproj/project.pbxproj`, `THIRD_PARTY_NOTICES.md` (archived), `EasyKeyApp/UpdateService.swift` |
| Persistence | Foundation `JSONEncoder`/`JSONDecoder` documents (`settings.json`, macro and Smart Switch documents) | system SDK | `EasyEngineCore/Settings/SettingsRepository.swift`, `SmartSwitchStore.swift`, `MacroStore.swift` |
| Unit tests | XCTest | system SDK | `EasyKeyTests/` |
| UI tests | XCUITest | system SDK | `EasyKeyUITests/` |
| Static analysis | SwiftLint + SwiftFormat (configs kept in sync; installed via Homebrew) | unavailable (Homebrew-managed) | `.swiftlint.yml`, `.swiftformat`, `Makefile` |
| CI pipeline | Hosted macOS runners; parallel test shards (unit + UI shards) with merged coverage gate | runner image macOS 15 (declared in CI workflow; local mirror in `Makefile`) | `Makefile`, [product overview](../product/overview.md) |
| Build orchestration | `make` + `xcodebuild` (`EasyKey.xcodeproj`, scheme `EasyKeyApp`) | makefile-defined | `Makefile` |
| Release packaging | Shell scripts (`Scripts/*.sh`: archive, export, notarize, staple, DMG, verify) + Python 3 stdlib-only appcast generator | Python 3, stdlib only | `Scripts/generate-appcast.py`, [RELEASE.md](../engineering/release.md) |

## Language and toolchain

Swift compiles in Swift 5 language mode across all targets
(`SWIFT_VERSION = 5.0`); [CONVENTIONS.md](../engineering/conventions.md) forbids
introducing Swift 6-only syntax without an explicit migration. Xcode 15+ is
the documented build requirement ([product overview](../product/overview.md)); the CI
pipeline selects the latest stable Xcode on macOS 15 runners. The only
external Swift package is Sparkle, pinned to exact version 2.9.4.

## Frameworks

The app deliberately keeps Apple frameworks at the edges:
`EasyEngineCore` has no AppKit, SwiftUI, or Combine dependency (architecture
rule enforced by `ArchitectureFitnessTests`), `EasyKeyKit` adapts the domain
to macOS event taps and accessibility, and `EasyKeyApp` owns UI,
localization, coordination, and updates. Combine appears only at the
app layer (`ObservableSettingsStore`); CryptoKit only in clipboard
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
parallel shards, merges the result bundles, and enforces a 90% line-coverage
gate (excluding the login helper); the same shards run locally via
`make test-parallel`. SwiftLint and SwiftFormat configurations live at the
repo root and are kept in sync with each other (`.swiftlint.yml` ↔
`.swiftformat`); `make lint` / `make format` run them when installed.

## Build and release

`make` wraps `xcodebuild` for build, test, coverage, QA, and release targets
(`make qa`, `make local-dmg`, `make dmg`). Release packaging is shell scripts
under `Scripts/` (archive, export, notarize, staple, DMG creation, arch
verification) plus one Python 3 script, `Scripts/generate-appcast.py`, which
appends signed items to the Sparkle appcast. The release pipeline is
parameterized by CI variables and secrets — see
[RELEASE.md](../engineering/release.md) and the configuration reference.

## Why this stack shape

The three-layer split (app / kit / core) exists so the typing domain can be
tested and reasoned about with no macOS dependencies at all, which is what
makes the 90% coverage gate and the fixture-driven conformance tests
practical. Native frameworks plus a single pinned update dependency keep the
attack and dependency surface small for an accessibility-permission app that
deliberately avoids analytics and telemetry.
