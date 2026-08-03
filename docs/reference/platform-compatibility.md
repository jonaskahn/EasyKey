---
id: "platform_compatibility"
title: "Platform Compatibility"
docforge_provenance:
  schema: "2.0"
  doc_id: "platform_compatibility"
  path: "docs/reference/platform-compatibility.md"
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
    - id: "platform-compatibility"
      sources:
        - path: "EasyKey.xcodeproj/project.pbxproj"
          role: "manifest"
          git_blob: "3fc1f4a80e4851be8a519efbb99f80102a4b41d4"
        - path: "README.md"
          role: "doc"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
      unresolved: []
    - id: "supported-platforms"
      sources:
        - path: "EasyKey.xcodeproj/project.pbxproj"
          role: "manifest"
          git_blob: "3fc1f4a80e4851be8a519efbb99f80102a4b41d4"
        - path: "docs/_archive/RELEASE.md"
          role: "doc"
          git_blob: "c749b17a004e3cf47af6af61e82db4aa9d40494d"
        - path: "Makefile"
          role: "config"
          git_blob: "b8fa0059c061eef05cb083ae69e8e7d46336aa64"
        - path: "README.md"
          role: "doc"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
      unresolved: []
    - id: "feature-level-requirements"
      sources:
        - path: "EasyKeyKit/KeyboardService.swift"
          role: "code"
          git_blob: "3d2db069ec81fb639d6eb9a6fc69121580854d31"
        - path: "EasyKeyApp/Features/Translation/AppTranslationRuntime.swift"
          role: "code"
          git_blob: "c4df84fdde3f664cd167d91ce3a64b387e6ef30e"
        - path: "EasyKeyApp/Coordination/LoginItemController.swift"
          role: "code"
          git_blob: "7833a6d82792ded3986386ac26e40b686feab12d"
        - path: "EasyKeyApp/UpdateService.swift"
          role: "code"
          git_blob: "27386d368017c0c64f38e75fbd5e23e62c7a4dd6"
        - path: "docs/_archive/RELEASE.md"
          role: "doc"
          git_blob: "c749b17a004e3cf47af6af61e82db4aa9d40494d"
      unresolved: []
    - id: "deprecation-horizon"
      sources:
        - path: "README.md"
          role: "doc"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
        - path: "docs/_archive/RELEASE.md"
          role: "doc"
          git_blob: "c749b17a004e3cf47af6af61e82db4aa9d40494d"
      unresolved: []
---
# Platform compatibility

_Last reviewed: 2026-08-03_

Minimums are tested evidence, not aspiration: every row is backed by the
declared deployment target and/or CI and release-gate configuration. "Tested
by" distinguishes CI matrix runs from manual gates.

## Supported platforms

| OS / device / architecture | Minimum version | Tested by | Below minimum |
|---|---|---|---|
| macOS (all models) | 14.0 Sonoma (`MACOSX_DEPLOYMENT_TARGET` / `LSMinimumSystemVersion`) | CI builds against the 14.0 target on macOS 15 runners; unit suites; manual "macOS 14 Apple-surface tests" release gate in [RELEASE.md](../engineering/release.md) | refuses to run (Launch Services enforces `LSMinimumSystemVersion`) |
| Apple silicon (arm64) | 14.0 | CI release matrix builds an arm64 DMG; `make verify-arch` validates `arm64` | not applicable (same OS minimum) |
| Intel (x86_64) | 14.0 | CI release matrix builds an amd64 (x86_64) DMG; `make verify-arch` validates `x86_64` | not applicable (same OS minimum) |
| Universal builds | 14.0 | CI release matrix builds a universal DMG (`arm64 x86_64`) used by Sparkle; `make release` defaults to `ARCHS="arm64 x86_64"` | not applicable |

The app is macOS-only; there are no iOS, iPadOS, or watchOS targets.

## Feature-level requirements

| Feature | Requirement | Degradation when unmet |
|---|---|---|
| Keyboard transformation | Accessibility permission (`KeyboardService.requestAccessibilityPermission`); system-wide event tap | typing stays untransformed until granted — the app runs, the feature does not |
| On-device Apple Translation | macOS 15+ (`TranslationPlatformCapability` computed with `if #available(macOS 15.0, *)`) | on macOS 14 the Apple provider is unavailable; Automatic resolution falls back to the first configured cloud provider |
| Cloud translation providers | macOS 14+; optional per-provider API key in Keychain | provider cards hidden or marked setup-required until credentials exist |
| Sparkle updates | macOS 14+; HTTPS feed URL and EdDSA public key supplied at build time | update checks disabled — local builds ship with empty `SUFeedURL`/`SUPublicEDKey` |
| Launch at login | macOS 14+; `SMAppService.loginItem` (login helper target) | setting reports `unsupported`/`failed` status in the System settings card |
| Clipboard manager | macOS 14+; no special permission (system pasteboard APIs) | feature simply off by default; no entitlement required |

## Deprecation horizon

No older platform is currently deprecated and no removal date is scheduled:
macOS 14.0 support is the declared floor in
[product overview](../product/overview.md) and the project file, and release gates in
[RELEASE.md](../engineering/release.md) still mandate macOS 14 Apple-surface
testing. A future bump of the deployment target would be announced through
the changelog and release process first.
