# Publishing

_Last reviewed: 2026-08-15_

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

**Version source:** `MARKETING_VERSION` (currently 0.0.11) and
`CURRENT_PROJECT_VERSION` (currently 9) in
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
   documented in [distribution](../operations/distribution.md).

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
(the engineering rulebook (notes/rulebook.md), section 2), and the fitness tests keep the dependency
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
app ships, and app rollback is documented in
[distribution](../operations/distribution.md).

**Deprecate:** not supported — with no versioned public API or distribution
channel, there is no mechanism to mark a framework version deprecated. API
change policy is the app's own release process.

**Patch forward:** the only evidenced path. Fix in the source tree, bump
`MARKETING_VERSION`, and release through the app pipeline
([distribution](../operations/distribution.md)). Note that the appcast tooling
rejects re-inserting an identical build or enclosure URL, so a re-ship
requires a new build number.

Released changes: record in [CHANGELOG.md](../../CHANGELOG.md).
