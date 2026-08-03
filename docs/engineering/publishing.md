---
id: "library_publishing"
title: "Library Publishing"
docforge_provenance:
  schema: "2.0"
  doc_id: "library_publishing"
  path: "docs/engineering/publishing.md"
  generated_at: "2026-08-03T08:44:07Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "deep-dive"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "artifacts"
      sources:
        - path: "EasyKey.xcodeproj/project.pbxproj"
          git_blob: "3fc1f4a80e4851be8a519efbb99f80102a4b41d4"
          role: "config"
        - path: "Makefile"
          git_blob: "b8fa0059c061eef05cb083ae69e8e7d46336aa64"
          role: "config"
        - path: "Scripts/archive.sh"
          git_blob: "188d893ab5a009a3455ba75155b381b4f6f1c392"
          role: "code"
      unresolved: []
    - id: "build-sign-publish"
      sources:
        - path: "Makefile"
          git_blob: "b8fa0059c061eef05cb083ae69e8e7d46336aa64"
          role: "config"
        - path: "Scripts/archive.sh"
          git_blob: "188d893ab5a009a3455ba75155b381b4f6f1c392"
          role: "code"
        - path: "Scripts/export.sh"
          git_blob: "e170e5fc9d887543ed6fffe7b757544380376ae1"
          role: "code"
        - path: "Scripts/verify-release.sh"
          git_blob: "3f24484dc3151e3bdfeace2c7610df3444474d15"
          role: "code"
      unresolved: []
    - id: "api-stability"
      sources:
        - path: "EasyKey.xcodeproj/project.pbxproj"
          git_blob: "3fc1f4a80e4851be8a519efbb99f80102a4b41d4"
          role: "config"
        - path: "README.md"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
          role: "doc"
        - path: "docs/_archive/CONVENTIONS.md"
          git_blob: "878c15dcb2e9f1fd811a7432688b8b20c6b72512"
          role: "doc"
      unresolved: []
    - id: "verify"
      sources:
        - path: "Scripts/verify-arch.sh"
          git_blob: "3a880113167f02293703e9c864a819543a1afd59"
          role: "code"
        - path: "Scripts/verify-release.sh"
          git_blob: "3f24484dc3151e3bdfeace2c7610df3444474d15"
          role: "code"
        - path: "Scripts/create-dmg.sh"
          git_blob: "28878a2d0cc4198f4b60426136282ceb8351ed2e"
          role: "code"
      unresolved: []
    - id: "rollback-deprecate"
      sources:
        - path: "Scripts/generate-appcast.py"
          git_blob: "b11742e9715d352ad971f4ab8d5f3dabf5ef38d9"
          role: "code"
        - path: "docs/_archive/RELEASE.md"
          git_blob: "c749b17a004e3cf47af6af61e82db4aa9d40494d"
          role: "doc"
        - path: "EasyKey.xcodeproj/project.pbxproj"
          git_blob: "3fc1f4a80e4851be8a519efbb99f80102a4b41d4"
          role: "config"
      unresolved: []
---
# Publishing

_Last reviewed: 2026-08-03_

**Honest state:** `EasyKeyKit` and `EasyEngineCore` are in-repository framework
targets of the EasyKey Xcode project. They are internal app modules: there is
no external publishing pipeline — no package manifest, no registry, no
podspec, no standalone release channel. This document describes the artifacts,
their version source, the build and signing tooling that applies to them, and
what does not exist for external distribution.

## Artifacts

| Artifact | Format | Produced by |
|---|---|---|
| EasyEngineCore.framework | Xcode framework (Mach-O, `product-type.framework`) | `xcodebuild` via `make build` (Debug) or `Scripts/archive.sh` (Release archive) |
| EasyKeyKit.framework | Xcode framework (Mach-O, `product-type.framework`) | same |
| EasyKey.app | app bundle embedding both frameworks | `Scripts/export.sh` from the archive |

**Version source:** `MARKETING_VERSION` (currently 0.0.7) and
`CURRENT_PROJECT_VERSION` (currently 5) in
`EasyKey.xcodeproj/project.pbxproj` — the same single source the app uses.
Downstream readers never re-derive it: `Scripts/create-dmg.sh` reads
`CFBundleShortVersionString` from the built app, and release tags must equal
`v<version>`.

## Build, sign, publish

1. Build — `make build` — verify: `** BUILD SUCCEEDED **` and both frameworks
   exist under `build/Build/Products/Debug/`. For a Release configuration,
   archive with `make archive` — verify: `Signed archive created:
   build/archives/EasyKey.xcarchive` (or `Local archive created` when
   `RELEASE_LOCAL=1`).
2. Sign — no standalone framework signing step exists; the frameworks are
   code-signed as part of the app archive. The archive step selects the
   identity: Developer ID Application certificate (`CODE_SIGN_IDENTITY` from
   the environment) for distribution, ad-hoc (`CODE_SIGN_IDENTITY="-"`) for
   local builds — verify: `Scripts/verify-release.sh` runs
   `codesign --verify --deep --strict` and `spctl` assessment on the exported
   app.
3. Publish — none. There is no registry or channel: no `Package.swift` exists
   anywhere in the repository, so the frameworks are not Swift packages, and
   they ship only inside the distributed DMG through the app release pipeline
   ([release.md](release.md)).

**Required gate:** the app-level gates — `make qa` (tests plus artifact
verification) and the CI 90% coverage gate — because the frameworks never
publish alone; there is no independent library release step to gate.

## API stability

Module definitions exist (`DEFINES_MODULE = YES` in
`EasyKey.xcodeproj/project.pbxproj`), so the frameworks import as modules
inside the app. `BUILD_LIBRARY_FOR_DISTRIBUTION` is **not** configured, so
library-evolution (ABI) stability for external consumers is not in effect.

The stability contract that does exist is process-level, not ABI-level: the
conventions require public API documentation at public boundaries
(CONVENTIONS.md section 2), the README lists "Public API documentation"
among enforced quality practices, and the fitness tests keep the dependency
direction stable. Those protect in-repo consumers; they do not constitute a
versioned public API.

Starting external distribution would require, none of which exists today: a
package manifest (Swift package or podspec), a versioned artifact
(separate from the app), library-evolution build settings, and a channel.
Treat this as an open gap, not a dormant pipeline.

## Verify

A consumer confirms the right artifact landed in the app bundle:

```bash
make verify-arch
```

Verify: `Architecture verification passed for: build/export/EasyKey.app` —
every Mach-O binary, including both embedded frameworks, contains arm64 and
x86_64. Or check one framework directly:

```bash
lipo -archs build/export/EasyKey.app/Contents/Frameworks/EasyEngineCore.framework/Versions/A/EasyEngineCore
```

Verify: `arm64 x86_64`. Then confirm the version: the `CFBundleShortVersionString`
of the exported app (`/usr/libexec/PlistBuddy -c 'Print
:CFBundleShortVersionString' build/export/EasyKey.app/Contents/Info.plist`)
must equal the release tag without the `v`.

## Rollback / deprecate

**Unpublish:** not supported — no external channel exists, so there is
nothing to pull back. A framework version never ships standalone; only the
app ships, and app rollback is the release guide's procedure.

**Deprecate:** not supported — with no versioned public API or distribution
channel, there is no mechanism to mark a framework version deprecated. API
change policy is the app's own release process.

**Patch forward:** the only evidenced path. Fix in the source tree, bump
`MARKETING_VERSION`, and release through the app pipeline
([release.md](release.md)). Note that the appcast tooling rejects re-inserting
an identical build or enclosure URL, so a re-ship requires a new build number.

Released changes: record in [CHANGELOG.md](../../CHANGELOG.md).
