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
          git_blob: "7d28327dbb97b2e90d36bcc4dcd61c43a34d699d"
          git_blob_normalized: "7d28327dbb97b2e90d36bcc4dcd61c43a34d699d"
          role: "manifest"
        - path: "README.md"
          git_blob: "0de1699403dbb6d0d24b58a2963cde1ac952a70e"
          git_blob_normalized: "0de1699403dbb6d0d24b58a2963cde1ac952a70e"
          role: "doc"
      unresolved: []
    - id: "in-repo-frameworks"
      sources:
        - path: "EasyKeyKit/EasyKeyKit.swift"
          git_blob: "fe7a078e829ab8377ecef7015657c02911034e6b"
          git_blob_normalized: "fe7a078e829ab8377ecef7015657c02911034e6b"
          role: "code"
        - path: "EasyEngineCore/Settings/EasyKeySettings.swift"
          git_blob: "aa8e22b824f59fd7a437d6af597ce6431ef10d57"
          git_blob_normalized: "aa8e22b824f59fd7a437d6af597ce6431ef10d57"
          role: "code"
        - path: "docs/engineering/conventions.md"
          git_blob: "3aefa68f5f4f8144c46f57517d76e1a26b304ea6"
          git_blob_normalized: "3aefa68f5f4f8144c46f57517d76e1a26b304ea6"
          role: "doc"
        - path: "CHANGELOG.md"
          git_blob: "b72eafd32f54bae88a13c1982b928b6b383fc5c6"
          git_blob_normalized: "b72eafd32f54bae88a13c1982b928b6b383fc5c6"
          role: "doc"
      unresolved: []
    - id: "external-dependencies"
      sources:
        - path: "EasyKey.xcodeproj/project.pbxproj"
          git_blob: "7d28327dbb97b2e90d36bcc4dcd61c43a34d699d"
          git_blob_normalized: "7d28327dbb97b2e90d36bcc4dcd61c43a34d699d"
          role: "manifest"
        - path: "docs/THIRD_PARTY_NOTICES.md"
          git_blob: "6d697f0974e0095717e5edd8a127d4b9c35512cb"
          git_blob_normalized: "6d697f0974e0095717e5edd8a127d4b9c35512cb"
          role: "doc"
      unresolved: []
    - id: "distribution-and-versioning"
      sources:
        - path: "README.md"
          git_blob: "0de1699403dbb6d0d24b58a2963cde1ac952a70e"
          git_blob_normalized: "0de1699403dbb6d0d24b58a2963cde1ac952a70e"
          role: "doc"
        - path: "EasyKeyKit/EasyKeyKit.swift"
          git_blob: "fe7a078e829ab8377ecef7015657c02911034e6b"
          git_blob_normalized: "fe7a078e829ab8377ecef7015657c02911034e6b"
          role: "code"
        - path: "CHANGELOG.md"
          git_blob: "b72eafd32f54bae88a13c1982b928b6b383fc5c6"
          git_blob_normalized: "b72eafd32f54bae88a13c1982b928b6b383fc5c6"
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
helper track the marketing version (currently 0.0.10, see
[CHANGELOG.md](../../CHANGELOG.md)); `EasyKeyKit` additionally exposes
`EasyKeyKit.version = "0.0.10"`.

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
