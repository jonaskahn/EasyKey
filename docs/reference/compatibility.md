---
id: "library_compatibility"
title: "Library Compatibility"
description: "Supported versions/platforms, tested matrix, deprecation behavior"
docforge_provenance:
  schema: "2.0"
  doc_id: "library_compatibility"
  path: "docs/reference/compatibility.md"
  generated_at: "2026-08-13T11:11:02Z"
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
          git_blob: "515597131540b043af2543b4d881e1509bbe8c40"
          git_blob_normalized: "515597131540b043af2543b4d881e1509bbe8c40"
          role: "manifest"
        - path: "README.md"
          git_blob: "adbd4f30d3c2f11bb855e6645195493a6c6a34f7"
          git_blob_normalized: "adbd4f30d3c2f11bb855e6645195493a6c6a34f7"
          role: "doc"
      unresolved: []
    - id: "in-repo-frameworks"
      sources:
        - path: "EasyKeyKit/EasyKeyKit.swift"
          git_blob: "0520693870b21891d4312dbbebf7ab0e28f5aa68"
          git_blob_normalized: "0520693870b21891d4312dbbebf7ab0e28f5aa68"
          role: "code"
        - path: "EasyEngineCore/Settings/EasyKeySettings.swift"
          git_blob: "aa8e22b824f59fd7a437d6af597ce6431ef10d57"
          git_blob_normalized: "aa8e22b824f59fd7a437d6af597ce6431ef10d57"
          role: "code"
        - path: "docs/engineering/conventions.md"
          git_blob: "f27ebfe19c8016812230d066d3de0cce2801672d"
          git_blob_normalized: "f27ebfe19c8016812230d066d3de0cce2801672d"
          role: "doc"
        - path: "CHANGELOG.md"
          git_blob: "d3242ff28ad2af793010bfffbc5a1bb5e2c4e3b4"
          git_blob_normalized: "d3242ff28ad2af793010bfffbc5a1bb5e2c4e3b4"
          role: "doc"
      unresolved: []
    - id: "external-dependencies"
      sources:
        - path: "EasyKey.xcodeproj/project.pbxproj"
          git_blob: "515597131540b043af2543b4d881e1509bbe8c40"
          git_blob_normalized: "515597131540b043af2543b4d881e1509bbe8c40"
          role: "manifest"
        - path: "docs/THIRD_PARTY_NOTICES.md"
          git_blob: "6d697f0974e0095717e5edd8a127d4b9c35512cb"
          git_blob_normalized: "6d697f0974e0095717e5edd8a127d4b9c35512cb"
          role: "doc"
      unresolved: []
    - id: "distribution-and-versioning"
      sources:
        - path: "README.md"
          git_blob: "adbd4f30d3c2f11bb855e6645195493a6c6a34f7"
          git_blob_normalized: "adbd4f30d3c2f11bb855e6645195493a6c6a34f7"
          role: "doc"
        - path: "EasyKeyKit/EasyKeyKit.swift"
          git_blob: "0520693870b21891d4312dbbebf7ab0e28f5aa68"
          git_blob_normalized: "0520693870b21891d4312dbbebf7ab0e28f5aa68"
          role: "code"
        - path: "CHANGELOG.md"
          git_blob: "d3242ff28ad2af793010bfffbc5a1bb5e2c4e3b4"
          git_blob_normalized: "d3242ff28ad2af793010bfffbc5a1bb5e2c4e3b4"
          role: "doc"
      unresolved: []
---
# Compatibility

_Last reviewed: 2026-08-13_

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
helper track the marketing version (currently 0.0.9, see
[CHANGELOG.md](../../CHANGELOG.md)); `EasyKeyKit` additionally exposes
`EasyKeyKit.version = "0.0.9"`.

## External dependencies

| Dependency | Version | Pinned | Tested by |
|---|---|---|---|
| Sparkle (SPM package, app updates) | 2.9.4 | exact version in the project file | release gates in [RELEASE.md](../engineering/release.md) (unsigned-archive rejection test); [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md) |

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
