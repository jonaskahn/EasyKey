---
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
          git_blob: "adead356c1e6f424159efb8e796d7682acb8bf4b"
          git_blob_normalized: "adead356c1e6f424159efb8e796d7682acb8bf4b"
          role: "manifest"
        - path: "README.md"
          git_blob: "8687b8acd6307c86df97aeaf869a85c5c041e671"
          git_blob_normalized: "8687b8acd6307c86df97aeaf869a85c5c041e671"
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
        - path: "docs/engineering/rulebook.md"
          git_blob: "dba86c139b41f2fe59027bab1f0e9982fd8d0e00"
          git_blob_normalized: "dba86c139b41f2fe59027bab1f0e9982fd8d0e00"
          role: "doc"
        - path: "docs/operations/distribution.md"
          git_blob: "8d83cebf8fd01048b8f098b01c20ee30294eeb36"
          git_blob_normalized: "8d83cebf8fd01048b8f098b01c20ee30294eeb36"
          role: "doc"
        - path: "CHANGELOG.md"
          git_blob: "9061aefe76f0145208e2f7730ebaaa03b6321aa1"
          git_blob_normalized: "9061aefe76f0145208e2f7730ebaaa03b6321aa1"
          role: "doc"
      unresolved: []
    - id: "external-dependencies"
      sources:
        - path: "EasyKey.xcodeproj/project.pbxproj"
          git_blob: "adead356c1e6f424159efb8e796d7682acb8bf4b"
          git_blob_normalized: "adead356c1e6f424159efb8e796d7682acb8bf4b"
          role: "manifest"
        - path: "docs/THIRD_PARTY_NOTICES.md"
          git_blob: "6d697f0974e0095717e5edd8a127d4b9c35512cb"
          git_blob_normalized: "6d697f0974e0095717e5edd8a127d4b9c35512cb"
          role: "doc"
        - path: "docs/operations/distribution.md"
          git_blob: "8d83cebf8fd01048b8f098b01c20ee30294eeb36"
          git_blob_normalized: "8d83cebf8fd01048b8f098b01c20ee30294eeb36"
          role: "doc"
      unresolved: []
    - id: "distribution-and-versioning"
      sources:
        - path: "README.md"
          git_blob: "8687b8acd6307c86df97aeaf869a85c5c041e671"
          git_blob_normalized: "8687b8acd6307c86df97aeaf869a85c5c041e671"
          role: "doc"
        - path: "EasyKeyKit/EasyKeyKit.swift"
          git_blob: "c2a257acc1b06050b76e6f29eee06f39016336c0"
          git_blob_normalized: "c2a257acc1b06050b76e6f29eee06f39016336c0"
          role: "code"
        - path: "CHANGELOG.md"
          git_blob: "9061aefe76f0145208e2f7730ebaaa03b6321aa1"
          git_blob_normalized: "9061aefe76f0145208e2f7730ebaaa03b6321aa1"
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
[rulebook.md](../engineering/rulebook.md). Version markers: the app and
helper track the marketing version (currently 0.0.10, see
[CHANGELOG.md](../../CHANGELOG.md)); `EasyKeyKit` additionally exposes
`EasyKeyKit.version = "0.0.10"`.

## External dependencies

| Dependency | Version | Pinned | Tested by |
|---|---|---|---|
| Sparkle (SPM package, app updates) | 2.9.4 | exact version in the project file | release verification in [distribution.md](../operations/distribution.md) (Sparkle pin and signature checks); [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md) |

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
