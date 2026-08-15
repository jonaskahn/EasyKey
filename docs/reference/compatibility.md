# Compatibility

_Last reviewed: 2026-08-15_

Compatibility here covers the frameworks and libraries built into this
repository. Newest first. "Tested by" means CI or a named test suite runs
against it — a version is marked supported only when there is test evidence,
not because it probably works. OS/device support is owned by
[platform-compatibility.md](platform-compatibility.md).

## In-repo frameworks

| Framework | Supported | Tested by | Deprecation | Status after |
|---|---|---|---|---|
| `EasyEngineCore` (framework) | macOS 14.0+, Swift 5 language mode | CI unit suites in `EasyKeyTests/` (engine, settings, macros, smart switch, clipboard, translation domain, architecture fitness) | not scheduled | functional |
| `EasyKeyKit` (framework) | macOS 14.0+, Swift 5 language mode | CI unit suites (`KeySynthesizerUtilityTests`, `KeyboardServiceIntegrationTests`, `KeyboardInputPipeline*Tests`, architecture fitness) | not scheduled | functional |
| `EasyKeyApp` (app target) | macOS 14.0+ | CI unit + XCUITest suites, 90% coverage gate (login helper excluded) | not scheduled | functional |
| `EasyKeyLoginHelper` (app target) | macOS 14.0+ | CI unit shards (`LoginHelperHardeningTests`, `LoginHelperWatchdogTests`, `LoginItemControllerTests`); excluded from the coverage gate (`Scripts/check-coverage.sh`) | not scheduled | functional |

Both frameworks compile with `MACOSX_DEPLOYMENT_TARGET = 14.0` and
`SWIFT_VERSION = 5.0` ([project.pbxproj](../../EasyKey.xcodeproj/project.pbxproj)),
and the codebase is constrained to Swift 5 language mode by
the engineering rulebook (notes/rulebook.md). Version markers: the app and
helper track the marketing version (currently 0.0.11, see
[CHANGELOG.md](../../CHANGELOG.md)); `EasyKeyKit` additionally exposes
`EasyKeyKit.version = "0.0.11"`.

## External dependencies

| Dependency | Version | Pinned | Tested by |
|---|---|---|---|
| Sparkle (SPM package, app updates) | 2.9.4 | exact version in the project file | release verification in [distribution.md](../operations/distribution.md) (Sparkle pin and signature checks); THIRD_PARTY_NOTICES.md |

Everything else builds against the macOS system SDK (SwiftUI, AppKit,
Combine, OSLog, CryptoKit, ServiceManagement, XCTest/XCUITest). No other
external libraries are linked; the test suites and scripts use system
tooling and Python 3 stdlib only.

## Distribution and versioning

The frameworks are **in-repo only**: there is no `Package.swift` manifest,
no CocoaPods/Carthage spec, and no published binary distribution — they are
built into the EasyKey application and never shipped as standalone artifacts.
Consumers outside this repository cannot depend on them; the documented
public surface is the one in [api.md](api.md). The app is versioned by
semantic tags (`v*`) and the marketing version; framework version parity is
assumed rather than maintained independently (see
[product overview](../product/overview.md) and [publishing.md](../engineering/publishing.md)).
