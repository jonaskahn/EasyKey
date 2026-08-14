---
id: "platform_compatibility"
title: "Platform Compatibility"
description: "OS/device/architecture matrix, minimums, tested evidence, degradation, deprecation"
docforge_provenance:
  schema: "2.0"
  doc_id: "platform_compatibility"
  path: "docs/reference/platform-compatibility.md"
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
    - id: "platform-compatibility"
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
    - id: "supported-platforms"
      sources:
        - path: "EasyKey.xcodeproj/project.pbxproj"
          git_blob: "adead356c1e6f424159efb8e796d7682acb8bf4b"
          git_blob_normalized: "adead356c1e6f424159efb8e796d7682acb8bf4b"
          role: "manifest"
        - path: "Makefile"
          git_blob: "b0926ee99352f08ba3eb3475b4ef45bfc143fe65"
          git_blob_normalized: "b0926ee99352f08ba3eb3475b4ef45bfc143fe65"
          role: "config"
        - path: "README.md"
          git_blob: "8fc7891befa21173acaaaf1b19c8c30ad6bb3f97"
          git_blob_normalized: "8fc7891befa21173acaaaf1b19c8c30ad6bb3f97"
          role: "doc"
        - path: "Scripts/verify-macos-compatibility.sh"
          git_blob: "2685842ca427b505b561e0154e5eb2d5fc27fd6a"
          git_blob_normalized: "2685842ca427b505b561e0154e5eb2d5fc27fd6a"
          role: "code"
        - path: "Scripts/verify-macos-compatibility.sh"
          git_blob: "2685842ca427b505b561e0154e5eb2d5fc27fd6a"
          git_blob_normalized: "2685842ca427b505b561e0154e5eb2d5fc27fd6a"
          role: "history"
      unresolved: []
    - id: "feature-level-requirements"
      sources:
        - path: "EasyKeyKit/Keyboard/KeyboardService.swift"
          git_blob: "3246c7e678b841077f3006877c3b2ead836e912b"
          git_blob_normalized: "3246c7e678b841077f3006877c3b2ead836e912b"
          role: "code"
        - path: "EasyKeyApp/Features/Translation/AppTranslationRuntime.swift"
          git_blob: "4f6f75d8aa093c688ec77d6722ba0cc62769b87d"
          git_blob_normalized: "4f6f75d8aa093c688ec77d6722ba0cc62769b87d"
          role: "code"
        - path: "EasyKeyApp/Coordination/LoginItemController.swift"
          git_blob: "7833a6d82792ded3986386ac26e40b686feab12d"
          git_blob_normalized: "7833a6d82792ded3986386ac26e40b686feab12d"
          role: "code"
        - path: "EasyKeyApp/Coordination/UpdateService.swift"
          git_blob: "186960351c6c963cfee981caef34e7aa8a544457"
          git_blob_normalized: "186960351c6c963cfee981caef34e7aa8a544457"
          role: "code"
      unresolved: []
    - id: "deprecation-horizon"
      sources:
        - path: "README.md"
          git_blob: "8fc7891befa21173acaaaf1b19c8c30ad6bb3f97"
          git_blob_normalized: "8fc7891befa21173acaaaf1b19c8c30ad6bb3f97"
          role: "doc"
      unresolved: []
---
# Platform compatibility

_Last reviewed: 2026-08-15_

Minimums are tested evidence, not aspiration: every row is backed by the
declared deployment target and/or CI and release-gate configuration. "Tested
by" distinguishes CI matrix runs from manual gates.

## Supported platforms

| OS / device / architecture | Minimum version | Tested by | Below minimum |
|---|---|---|---|
| macOS (all models) | 14.0 Sonoma (`MACOSX_DEPLOYMENT_TARGET` / `LSMinimumSystemVersion`) | CI builds against the 14.0 target on macOS 15 runners; `Scripts/verify-macos-compatibility.sh` gates every app bundle (Mach-O `minos`, weak Translation linkage, `LSMinimumSystemVersion`); unit suites; release verification in [distribution.md](../operations/distribution.md) | refuses to run (Launch Services enforces `LSMinimumSystemVersion`) |
| Apple silicon (arm64) | 14.0 | CI release matrix builds an arm64 DMG; `make verify-arch` validates `arm64` | not applicable (same OS minimum) |
| Intel (x86_64) | 14.0 | CI release matrix builds an amd64 (x86_64) DMG; `make verify-arch` validates `x86_64` | not applicable (same OS minimum) |
| Universal builds | 14.0 | CI release matrix builds a universal DMG (`arm64 x86_64`) used by Sparkle; `make release` defaults to `ARCHS="arm64 x86_64"` | not applicable |

The app is macOS-only; there are no iOS, iPadOS, or watchOS targets.

## Feature-level requirements

| Feature | Requirement | Degradation when unmet |
|---|---|---|
| Keyboard transformation | Accessibility permission (`KeyboardService.requestAccessibilityPermission`); system-wide event tap | typing stays untransformed until granted — the app runs, the feature does not |
| On-device Apple Translation | macOS 15+ (`TranslationPlatformCapability` is constructed by the app layer; Apple Translation is gated with `if #available(macOS 15.0, *)` in `AppTranslationRuntime`) | on macOS 14 the Apple provider is unavailable; Automatic resolution falls back to the first configured cloud provider |
| Cloud translation providers | macOS 14+; optional per-provider API key in Keychain | provider cards hidden or marked setup-required until credentials exist |
| Sparkle updates | macOS 14+; HTTPS feed URL and EdDSA public key supplied at build time | update checks disabled — local builds ship with empty `SUFeedURL`/`SUPublicEDKey` |
| Launch at login | macOS 14+; `SMAppService.loginItem` (login helper target) | setting reports `unsupported`/`failed` status in the System settings card |
| Clipboard manager | macOS 14+; no special permission (system pasteboard APIs) | feature simply off by default; no entitlement required |

## Deprecation horizon

No older platform is currently deprecated and no removal date is scheduled:
macOS 14.0 support is the declared floor in
[product overview](../product/overview.md) and the project file. A future bump of
the deployment target would be announced through the changelog and release
process first.
