---
id: "library_compatibility"
title: "Library Compatibility"
docforge_provenance:
  schema: "2.0"
  doc_id: "library_compatibility"
  path: "docs/reference/compatibility.md"
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
    - id: "compatibility"
      sources:
        - path: "EasyKey.xcodeproj/project.pbxproj"
          role: "manifest"
          git_blob: "3fc1f4a80e4851be8a519efbb99f80102a4b41d4"
        - path: "README.md"
          role: "doc"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
      unresolved: []
    - id: "in-repo-frameworks"
      sources:
        - path: "EasyKeyKit/EasyKeyKit.swift"
          role: "code"
          git_blob: "76482ec56440968c9f78d2fce59c0c3cfa7d0ca1"
        - path: "EasyEngineCore/Settings/EasyKeySettings.swift"
          role: "code"
          git_blob: "b42c58c6e3f1eba416bca3c809ba579441fe87cc"
        - path: "docs/_archive/CONVENTIONS.md"
          role: "doc"
          git_blob: "878c15dcb2e9f1fd811a7432688b8b20c6b72512"
        - path: "CHANGELOG.md"
          role: "doc"
          git_blob: "2da41e48235762ea13ff11b79fe8553d7df2ff96"
      unresolved: []
    - id: "external-dependencies"
      sources:
        - path: "EasyKey.xcodeproj/project.pbxproj"
          role: "manifest"
          git_blob: "3fc1f4a80e4851be8a519efbb99f80102a4b41d4"
        - path: "docs/_archive/THIRD_PARTY_NOTICES.md"
          role: "doc"
          git_blob: "8c0da23df063ee46dc734994bdd9b6e365eb7a72"
      unresolved: []
    - id: "distribution-and-versioning"
      sources:
        - path: "README.md"
          role: "doc"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
        - path: "EasyKeyKit/EasyKeyKit.swift"
          role: "code"
          git_blob: "76482ec56440968c9f78d2fce59c0c3cfa7d0ca1"
        - path: "CHANGELOG.md"
          role: "doc"
          git_blob: "2da41e48235762ea13ff11b79fe8553d7df2ff96"
      unresolved: []
---
# Compatibility

_Last reviewed: 2026-08-03_

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
| `EasyKeyLoginHelper` (app target) | macOS 14.0+ | manual release gates in [RELEASE.md](../engineering/release.md); excluded from the coverage gate | not scheduled | functional |

Both frameworks compile with `MACOSX_DEPLOYMENT_TARGET = 14.0` and
`SWIFT_VERSION = 5.0` ([project.pbxproj](../../EasyKey.xcodeproj/project.pbxproj)),
and the codebase is constrained to Swift 5 language mode by
[CONVENTIONS.md](../engineering/conventions.md). Version markers: the app and
helper track the marketing version (currently 0.0.7, see
[CHANGELOG.md](../../CHANGELOG.md)); `EasyKeyKit` additionally exposes
`EasyKeyKit.version = "0.0.7"`.

## External dependencies

| Dependency | Version | Pinned | Tested by |
|---|---|---|---|
| Sparkle (SPM package, app updates) | 2.9.4 | exact version in the project file | release gates in [RELEASE.md](../engineering/release.md) (unsigned-archive rejection test); `THIRD_PARTY_NOTICES.md` (archived) |

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
[product overview](../product/overview.md) and [RELEASE.md](../engineering/release.md)).
