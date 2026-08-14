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
  tier: "spine"
  target_depth: "reference"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "compatibility"
      sources:
        - path: "EasyKey.xcodeproj/project.pbxproj"
          git_blob: "adead356c1e6f424159efb8e796d7682acb8bf4b"
          git_blob_normalized: "adead356c1e6f424159efb8e796d7682acb8bf4b"
          role: "manifest"
        - path: "README.md"
          git_blob: "8fc7891befa21173acaaaf1b19c8c30ad6bb3f97"
          git_blob_normalized: "8fc7891befa21173acaaaf1b19c8c30ad6bb3f97"
          role: "doc"
      unresolved: []
    - id: "in-repo-frameworks"
      sources:
        - path: "EasyKeyKit/EasyKeyKit.swift"
          git_blob: "c2a257acc1b06050b76e6f29eee06f39016336c0"
          git_blob_normalized: "c2a257acc1b06050b76e6f29eee06f39016336c0"
          role: "code"
        - path: "EasyEngineCore/Settings/EasyKeySettings.swift"
          git_blob: "aa8e22b824f59fd7a437d6af597ce6431ef10d57"
          git_blob_normalized: "aa8e22b824f59fd7a437d6af597ce6431ef10d57"
          role: "code"
        - path: "docs/_archive/rulebook.md"
          git_blob: "adbd3fec4e0f76f10542989e894a89e46dda4afd"
          git_blob_normalized: "adbd3fec4e0f76f10542989e894a89e46dda4afd"
          role: "doc"
        - path: "docs/operations/distribution.md"
          git_blob: "b62e29ea58adce238882da5f55c9e3a3fbb3aaa3"
          git_blob_normalized: "b62e29ea58adce238882da5f55c9e3a3fbb3aaa3"
          role: "doc"
        - path: "CHANGELOG.md"
          git_blob: "7a69fbbeae7940ae5ab7e08b7a86a8853a346b22"
          git_blob_normalized: "7a69fbbeae7940ae5ab7e08b7a86a8853a346b22"
          role: "doc"
      unresolved: []
    - id: "external-dependencies"
      sources:
        - path: "EasyKey.xcodeproj/project.pbxproj"
          git_blob: "adead356c1e6f424159efb8e796d7682acb8bf4b"
          git_blob_normalized: "adead356c1e6f424159efb8e796d7682acb8bf4b"
          role: "manifest"
        - path: "docs/_archive/THIRD_PARTY_NOTICES.md"
          git_blob: "d1c69d9291af721ef4d4d5c0555252d3cc05ec4a"
          git_blob_normalized: "d1c69d9291af721ef4d4d5c0555252d3cc05ec4a"
          role: "doc"
        - path: "docs/operations/distribution.md"
          git_blob: "b62e29ea58adce238882da5f55c9e3a3fbb3aaa3"
          git_blob_normalized: "b62e29ea58adce238882da5f55c9e3a3fbb3aaa3"
          role: "doc"
      unresolved: []
    - id: "distribution-and-versioning"
      sources:
        - path: "README.md"
          git_blob: "8fc7891befa21173acaaaf1b19c8c30ad6bb3f97"
          git_blob_normalized: "8fc7891befa21173acaaaf1b19c8c30ad6bb3f97"
          role: "doc"
        - path: "EasyKeyKit/EasyKeyKit.swift"
          git_blob: "c2a257acc1b06050b76e6f29eee06f39016336c0"
          git_blob_normalized: "c2a257acc1b06050b76e6f29eee06f39016336c0"
          role: "code"
        - path: "CHANGELOG.md"
          git_blob: "7a69fbbeae7940ae5ab7e08b7a86a8853a346b22"
          git_blob_normalized: "7a69fbbeae7940ae5ab7e08b7a86a8853a346b22"
          role: "doc"
      unresolved: []
---
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
| `EasyKeyLoginHelper` (app target) | macOS 14.0+ | manual release gates in [distribution.md](../operations/distribution.md); excluded from the coverage gate | not scheduled | functional |

Both frameworks compile with `MACOSX_DEPLOYMENT_TARGET = 14.0` and
`SWIFT_VERSION = 5.0` ([project.pbxproj](../../EasyKey.xcodeproj/project.pbxproj)),
and the codebase is constrained to Swift 5 language mode by
the archived engineering rulebook. Version markers: the app and
helper track the marketing version (currently 0.0.10, see
[CHANGELOG.md](../../CHANGELOG.md)); `EasyKeyKit` additionally exposes
`EasyKeyKit.version = "0.0.10"`.

## External dependencies

| Dependency | Version | Pinned | Tested by |
|---|---|---|---|
| Sparkle (SPM package, app updates) | 2.9.4 | exact version in the project file | release verification in [distribution.md](../operations/distribution.md) (Sparkle pin and signature checks); the archived third-party notices |

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
