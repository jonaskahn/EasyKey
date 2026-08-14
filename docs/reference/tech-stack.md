---
id: "tech_stack"
title: "Tech Stack"
description: "Detected languages/versions; runtimes/SDKs; primary frameworks per layer; datastores and messaging; build/package/dependency-management tooling; test and CI..."
docforge_provenance:
  schema: "2.0"
  doc_id: "tech_stack"
  path: "docs/reference/tech-stack.md"
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
    - id: "tech-stack"
      sources:
        - path: "README.md"
          git_blob: "8fc7891befa21173acaaaf1b19c8c30ad6bb3f97"
          git_blob_normalized: "8fc7891befa21173acaaaf1b19c8c30ad6bb3f97"
          role: "doc"
        - path: "EasyKey.xcodeproj/project.pbxproj"
          git_blob: "adead356c1e6f424159efb8e796d7682acb8bf4b"
          git_blob_normalized: "adead356c1e6f424159efb8e796d7682acb8bf4b"
          role: "manifest"
      unresolved: []
    - id: "language-and-toolchain"
      sources:
        - path: "EasyKey.xcodeproj/project.pbxproj"
          git_blob: "adead356c1e6f424159efb8e796d7682acb8bf4b"
          git_blob_normalized: "adead356c1e6f424159efb8e796d7682acb8bf4b"
          role: "manifest"
        - path: "docs/_archive/rulebook.md"
          git_blob: "adbd3fec4e0f76f10542989e894a89e46dda4afd"
          git_blob_normalized: "adbd3fec4e0f76f10542989e894a89e46dda4afd"
          role: "doc"
        - path: "README.md"
          git_blob: "8fc7891befa21173acaaaf1b19c8c30ad6bb3f97"
          git_blob_normalized: "8fc7891befa21173acaaaf1b19c8c30ad6bb3f97"
          role: "doc"
      unresolved: []
    - id: "frameworks"
      sources:
        - path: "EasyEngineCore/Diagnostics/AppLog.swift"
          git_blob: "827ef0baa84980d0df634f19d06d944c856a4293"
          git_blob_normalized: "827ef0baa84980d0df634f19d06d944c856a4293"
          role: "code"
        - path: "EasyKeyApp/Settings/SettingsStore.swift"
          git_blob: "65074f5684006b032e635e9bcf80ad7bf37f4929"
          git_blob_normalized: "65074f5684006b032e635e9bcf80ad7bf37f4929"
          role: "code"
        - path: "EasyKeyApp/Features/Clipboard/ClipboardPersistence.swift"
          git_blob: "2f2f6e1c7c03071c95010c565309b55a06b15c34"
          git_blob_normalized: "2f2f6e1c7c03071c95010c565309b55a06b15c34"
          role: "code"
        - path: "EasyKeyApp/Coordination/LoginItemController.swift"
          git_blob: "7833a6d82792ded3986386ac26e40b686feab12d"
          git_blob_normalized: "7833a6d82792ded3986386ac26e40b686feab12d"
          role: "code"
        - path: "EasyKeyApp/Coordination/UpdateService.swift"
          git_blob: "186960351c6c963cfee981caef34e7aa8a544457"
          git_blob_normalized: "186960351c6c963cfee981caef34e7aa8a544457"
          role: "code"
        - path: "docs/_archive/THIRD_PARTY_NOTICES.md"
          git_blob: "d1c69d9291af721ef4d4d5c0555252d3cc05ec4a"
          git_blob_normalized: "d1c69d9291af721ef4d4d5c0555252d3cc05ec4a"
          role: "doc"
      unresolved: []
    - id: "persistence"
      sources:
        - path: "EasyEngineCore/Settings/SettingsRepository.swift"
          git_blob: "8dbf2339135a67a57533869cca68d46cc6e8c991"
          git_blob_normalized: "8dbf2339135a67a57533869cca68d46cc6e8c991"
          role: "code"
        - path: "EasyEngineCore/SmartSwitch/SmartSwitchStore.swift"
          git_blob: "694b512e15a06e34e7df216ba74a4fc133e27f69"
          git_blob_normalized: "694b512e15a06e34e7df216ba74a4fc133e27f69"
          role: "code"
        - path: "EasyEngineCore/Macros/MacroStore.swift"
          git_blob: "a5909fcd5e5e13b871c24d359a2e89f002ae239a"
          git_blob_normalized: "a5909fcd5e5e13b871c24d359a2e89f002ae239a"
          role: "code"
      unresolved: []
    - id: "testing-and-quality"
      sources:
        - path: "Makefile"
          git_blob: "b0926ee99352f08ba3eb3475b4ef45bfc143fe65"
          git_blob_normalized: "b0926ee99352f08ba3eb3475b4ef45bfc143fe65"
          role: "config"
        - path: ".swiftlint.yml"
          git_blob: "90631d6319ce50e321f2e8f6936145b08d98d92f"
          git_blob_normalized: "90631d6319ce50e321f2e8f6936145b08d98d92f"
          role: "config"
        - path: ".swiftformat"
          git_blob: "ac27429273e1daa282d4a73177cebd2dae238705"
          git_blob_normalized: "ac27429273e1daa282d4a73177cebd2dae238705"
          role: "config"
        - path: "README.md"
          git_blob: "8fc7891befa21173acaaaf1b19c8c30ad6bb3f97"
          git_blob_normalized: "8fc7891befa21173acaaaf1b19c8c30ad6bb3f97"
          role: "doc"
      unresolved: []
    - id: "build-and-release"
      sources:
        - path: "Makefile"
          git_blob: "b0926ee99352f08ba3eb3475b4ef45bfc143fe65"
          git_blob_normalized: "b0926ee99352f08ba3eb3475b4ef45bfc143fe65"
          role: "config"
        - path: "Scripts/generate-appcast.py"
          git_blob: "b11742e9715d352ad971f4ab8d5f3dabf5ef38d9"
          git_blob_normalized: "b11742e9715d352ad971f4ab8d5f3dabf5ef38d9"
          role: "code"
        - path: "docs/operations/distribution.md"
          git_blob: "b62e29ea58adce238882da5f55c9e3a3fbb3aaa3"
          git_blob_normalized: "b62e29ea58adce238882da5f55c9e3a3fbb3aaa3"
          role: "doc"
        - path: "EasyKey.xcodeproj/project.pbxproj"
          git_blob: "adead356c1e6f424159efb8e796d7682acb8bf4b"
          git_blob_normalized: "adead356c1e6f424159efb8e796d7682acb8bf4b"
          role: "manifest"
      unresolved: []
    - id: "why-this-stack-shape"
      sources:
        - path: "README.md"
          git_blob: "8fc7891befa21173acaaaf1b19c8c30ad6bb3f97"
          git_blob_normalized: "8fc7891befa21173acaaaf1b19c8c30ad6bb3f97"
          role: "doc"
      unresolved: []
---
# Tech stack

_Last reviewed: 2026-08-15_

Declared versions where the repository states them; otherwise marked
unavailable rather than inferred from imports. Layer grouping follows what a
maintainer would change together.

| Layer | Technology | Version | Evidence path |
|---|---|---|---|
| Language | Swift, Swift 5 language mode | Swift 5.0 (`SWIFT_VERSION`); Xcode 15+ required | `EasyKey.xcodeproj/project.pbxproj`, the archived engineering rulebook, [setup](../engineering/setup.md) |
| Minimum OS | macOS | 14.0 (`MACOSX_DEPLOYMENT_TARGET`, `LSMinimumSystemVersion`) | `EasyKey.xcodeproj/project.pbxproj`, `EasyKeyApp/Info.plist` |
| Application shell | SwiftUI + AppKit (`NSApplicationDelegate`, `NSPanel` subclasses, `NSWorkspace`) | system SDK | `EasyKeyApp/` |
| Domain logic | EasyEngineCore — framework-free typing, settings, macros, smart switch, converter, clipboard, translation | in-repo, no external dependency | `EasyEngineCore/` |
| Keyboard adapters | EasyKeyKit — `CGEvent` tap, Accessibility focus, event synthesis | in-repo | `EasyKeyKit/` |
| Reactive | Combine (`ObservableObject`/`@Published`) | system SDK | `EasyKeyApp/Settings/SettingsStore.swift` |
| Logging | OSLog (`Logger`, subsystem `one.ifelse.easykey`) | system SDK | `EasyEngineCore/Diagnostics/AppLog.swift` |
| Crypto | CryptoKit AES-GCM (clipboard persistence) | system SDK | `EasyKeyApp/Features/Clipboard/ClipboardPersistence.swift` |
| System integration | ServiceManagement (`SMAppService.loginItem`) | system SDK | `EasyKeyApp/Coordination/LoginItemController.swift` |
| In-app purchases | StoreKit | not used | absence of StoreKit imports in `EasyKeyApp/`, `EasyKeyKit/`, `EasyEngineCore/` |
| Updates | Sparkle 2 (SPM package, pinned exact 2.9.4; EdDSA-signed appcast) | 2.9.4 | `EasyKey.xcodeproj/project.pbxproj`, the archived third-party notices, `EasyKeyApp/Coordination/UpdateService.swift` |
| Persistence | Foundation `JSONEncoder`/`JSONDecoder` documents (`settings.json`, macro and Smart Switch documents) | system SDK | `EasyEngineCore/Settings/SettingsRepository.swift`, `SmartSwitchStore.swift`, `MacroStore.swift` |
| Unit tests | XCTest | system SDK | `EasyKeyTests/` |
| UI tests | XCUITest | system SDK | `EasyKeyUITests/` |
| Static analysis | SwiftLint + SwiftFormat (configs kept in sync; installed via Homebrew) | unavailable (Homebrew-managed) | `.swiftlint.yml`, `.swiftformat`, `Makefile` |
| CI pipeline | Hosted macOS runners; parallel test shards (unit + UI shards) with merged coverage gate | runner image macOS 15 (declared in CI workflow; local mirror in `Makefile`) | `Makefile`, [product overview](../product/overview.md) |
| Build orchestration | `make` + `xcodebuild` (`EasyKey.xcodeproj`, scheme `EasyKeyApp`) | makefile-defined | `Makefile` |
| Release packaging | Shell scripts (`Scripts/*.sh`: archive, export, notarize, staple, DMG, verify) + Python 3 stdlib-only appcast generator | Python 3, stdlib only | `Scripts/generate-appcast.py`, [distribution.md](../operations/distribution.md) |

## Language and toolchain

Swift compiles in Swift 5 language mode across all targets
(`SWIFT_VERSION = 5.0`); the archived engineering rulebook forbids
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
