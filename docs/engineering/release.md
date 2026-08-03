---
id: "release_guide"
title: "Release Guide"
docforge_provenance:
  schema: "2.0"
  doc_id: "release_guide"
  path: "docs/engineering/release.md"
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
    - id: "prerequisites"
      sources:
        - path: "docs/_archive/RELEASE.md"
          git_blob: "c749b17a004e3cf47af6af61e82db4aa9d40494d"
          role: "doc"
        - path: "EasyKey.xcodeproj/project.pbxproj"
          git_blob: "3fc1f4a80e4851be8a519efbb99f80102a4b41d4"
          role: "config"
      unresolved: []
    - id: "version"
      sources:
        - path: "EasyKey.xcodeproj/project.pbxproj"
          git_blob: "3fc1f4a80e4851be8a519efbb99f80102a4b41d4"
          role: "config"
        - path: "CHANGELOG.md"
          git_blob: "2da41e48235762ea13ff11b79fe8553d7df2ff96"
          role: "doc"
        - path: "Scripts/create-dmg.sh"
          git_blob: "28878a2d0cc4198f4b60426136282ceb8351ed2e"
          role: "code"
      unresolved: []
    - id: "build"
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
        - path: "Scripts/notarize.sh"
          git_blob: "18256dcf44a32ce9c2cef44d2196ee44fef8fd63"
          role: "code"
        - path: "Scripts/staple.sh"
          git_blob: "80200416ce69633be60a3d3317fcc27799ee7a7f"
          role: "code"
        - path: "Scripts/create-dmg.sh"
          git_blob: "28878a2d0cc4198f4b60426136282ceb8351ed2e"
          role: "code"
        - path: "README.md"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
          role: "doc"
      unresolved: []
    - id: "verification"
      sources:
        - path: "Scripts/verify-release.sh"
          git_blob: "3f24484dc3151e3bdfeace2c7610df3444474d15"
          role: "code"
        - path: "Scripts/verify-arch.sh"
          git_blob: "3a880113167f02293703e9c864a819543a1afd59"
          role: "code"
        - path: "docs/_archive/RELEASE.md"
          git_blob: "c749b17a004e3cf47af6af61e82db4aa9d40494d"
          role: "doc"
      unresolved: []
    - id: "publication"
      sources:
        - path: "Scripts/generate-appcast.py"
          git_blob: "b11742e9715d352ad971f4ab8d5f3dabf5ef38d9"
          role: "code"
        - path: "Scripts/check-sparkle-pin.sh"
          git_blob: "d5fbfa88d05ef88b6d22a9d792292db0a054e75f"
          role: "code"
        - path: "docs/_archive/RELEASE.md"
          git_blob: "c749b17a004e3cf47af6af61e82db4aa9d40494d"
          role: "doc"
        - path: "EasyKeyApp/UpdateService.swift"
          git_blob: "27386d368017c0c64f38e75fbd5e23e62c7a4dd6"
          role: "code"
      unresolved: []
    - id: "rollback"
      sources:
        - path: "Scripts/generate-appcast.py"
          git_blob: "b11742e9715d352ad971f4ab8d5f3dabf5ef38d9"
          role: "code"
        - path: "docs/_archive/RELEASE.md"
          git_blob: "c749b17a004e3cf47af6af61e82db4aa9d40494d"
          role: "doc"
      unresolved: []
---
# Release guide

_Last reviewed: 2026-08-03_

This is the procedure for shipping an EasyKey release: versioning, build,
verification, publication through the Sparkle update channel, and rollback.
The authoritative release document is [RELEASE.md](release.md); the record
of what changed in each release lives in [CHANGELOG.md](../../CHANGELOG.md).

## Prerequisites

Before starting a release:

- The version to ship is committed on `main` with CI green — lint, all test
  shards, and the 90% coverage gate pass (`make qa` is the local equivalent).
- The version number is bumped in `EasyKey.xcodeproj/project.pbxproj`
  (`MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`) and recorded in
  [CHANGELOG.md](../../CHANGELOG.md).
- Release inputs are available (RELEASE.md "Required Release Inputs"):
  `DEVELOPER_ID_APPLICATION`, `DEVELOPMENT_TEAM`, `SPARKLE_FEED_URL`,
  `SPARKLE_PUBLIC_ED_KEY`, `EASYKEY_SUPPORT_URL`, `EASYKEY_PRIVACY_POLICY_URL`,
  and `NOTARY_KEYCHAIN_PROFILE` (or the Apple ID notarization variables
  `APPLE_ID`, `APPLE_TEAM_ID`, `APPLE_APP_SPECIFIC_PASSWORD`).
- Credentials are stored in Keychain or CI secrets — never committed.

Access you will need, and who grants it: the Apple Developer Program account
(Developer ID certificate and notarization) held by the repository owner, and
the repository variables and secrets used by the release workflows.

## Version

**Scheme:** Semantic Versioning (the changelog states "versioning follows
Semantic Versioning"). Major: breaking changes · Minor: new features ·
Patch: bug fixes.

The version's single source of truth is `MARKETING_VERSION` (currently
0.0.7) with `CURRENT_PROJECT_VERSION` (currently 5) in
`EasyKey.xcodeproj/project.pbxproj`. Everything downstream reads it from the
built app's `Info.plist`: the DMG filename is `EasyKey-<version>-universal.dmg`
(`Scripts/create-dmg.sh` reads `CFBundleShortVersionString`), and the release
tag must match it — both release workflows abort when the tag is not
`v<version>`.

## Build

1. Run the QA gate before packaging a candidate — `make qa` — verify:
   `Phase 8 automated QA gate passed.` (required by RELEASE.md).
2. Signed distribution — `make dmg` — verify: `Release verification passed:
   build/export/EasyKey.app` and `build/EasyKey-<version>-universal.dmg`
   exists. This target runs the full sequence: release configuration check,
   archive (`Scripts/archive.sh`), export (`Scripts/export.sh`), architecture
   verification, code-signature verification, notarization and stapling of
   the app, DMG creation, notarization and stapling of the DMG, then release
   verification.
3. Current state of CI: the release workflow currently runs `make local-dmg`
   (ad-hoc signed, not notarized) because Developer ID signing and
   notarization are staged but disabled pending an Apple certificate; public
   builds are described as ad-hoc signed in the README. Use `make dmg` for a
   fully signed release until that is re-enabled.
4. Local alternative without Developer ID or notary credentials — `make
   local-dmg` — verify: `DMG created: build/EasyKey-<version>-universal.dmg`.
   Notarization and stapling are skipped.

## Verification

**Required gate:** `make qa` plus the release integrity checks — owned by the
maintainer performing the release.

1. `make verify-arch` — verify: `Architecture verification passed for:
   build/export/EasyKey.app` (every Mach-O binary contains arm64 and x86_64).
2. `make verify-release` — verify: the same message; the script also runs
   `codesign --verify --deep --strict`, `spctl` assessment, `stapler
   validate` on the DMG, confirms the bundled `LICENSE`, `NOTICE`, and
   `THIRD_PARTY_NOTICES.md`, rejects development material under
   `fixtures/`, `sources/`, `diagnostics/`, or `capture/` paths, and rejects
   tracked `build/` output.
3. Manual release gates (RELEASE.md): fresh, upgrade, and uninstall/reinstall
   installs; login helper after reboot and macOS upgrade; Accessibility stays
   authorized after replacing the app in place; Sparkle rejects an unsigned or
   incorrectly signed update archive; archive contents limited to EasyKey
   binaries, Sparkle, MIT `LICENSE`, `NOTICE`, and reviewed
   `THIRD_PARTY_NOTICES.md`; privacy copy matches runtime behavior; provider
   data-handling URLs reviewed; English/Vietnamese localization checks and
   accessibility passes on macOS 14.

## Publication

1. Push a tag `v<version>` to `main`. The release workflow builds three DMGs
   (universal, arm64, amd64) and creates a **draft** release with all three
   attached — verify: the draft appears on the Releases page with three
   DMGs named `EasyKey-<version>-<target>.dmg`.
2. Publish the draft. The draft gate is intentional: nothing is
   auto-update-eligible until the release is public, because the appcast
   enclosure URL must resolve publicly.
3. Publishing triggers the appcast workflow: it downloads the universal DMG,
   verifies the tag still matches the built version, downloads the pinned
   Sparkle tools — the SHA-256 pin (`expected_sha256`, checked inline with
   `shasum -a 256 -c -`) lives in the CI publish workflow;
   `Scripts/check-sparkle-pin.sh` is a manual verification aid that asserts the
   pin and its `shasum` check are present in the workflow — signs the DMG with
   Sparkle's `sign_update` using the private EdDSA key from CI secrets, and
   appends one `<item>` to `appcast.xml` on the `gh-pages` branch via
   `Scripts/generate-appcast.py` — verify: the appcast served at the
   configured `SPARKLE_FEED_URL` contains a new `<item>` whose enclosure URL
   resolves and whose `edSignature` is present.
4. In-app: `UpdateService` (`EasyKeyApp/UpdateService.swift`) configures
   `SPUStandardUpdaterController` with `startingUpdater: false`; `start()`,
   called from `AppCoordinator.start()` at launch, calls `startUpdater()` and
   Sparkle's standard schedule takes over — there is no custom delay,
   randomization, or check cadence. `checkForUpdates()` invokes Sparkle's
   user-initiated check. The updater is disabled entirely unless the release
   build configuration is present: `hasReleaseConfiguration` requires an HTTPS
   `SUFeedURL` and a non-empty `SUPublicEDKey` in the built app's Info.plist
   (no unresolved placeholders), so testing builds never check for updates.
   Users receive the update after step 2.

## Rollback

**Trigger:** a blocking defect in a released version — update fails Sparkle
signature verification, the app crashes at launch, or a privacy regression —
reported by users or found by the maintainer. Escalation: the repository
maintainer decides and acts.

1. Fix forward first — the only automated path. Fix in source, bump
   `MARKETING_VERSION` (patch for a bug fix), tag `v<new>`, and repeat the
   pipeline — verify: the new release is public and the appcast lists it.
2. If the broken item must stop being offered immediately: revert or edit the
   `appcast.xml` commit on the `gh-pages` branch and push. There is no
   automated unpublish; the appcast is a committed file. Note that
   `Scripts/generate-appcast.py` refuses to re-insert the same build or
   enclosure URL, so re-releasing an identical artifact requires a new build
   number — verify: `SPARKLE_FEED_URL` returns an appcast without the broken
   item.
3. Edit or delete the release on the Releases page to remove the DMG
   attachments — verify: the release page no longer offers the broken DMG.
   Already-updated clients keep the broken build until the patch from step 1
   ships.

Released changes: record in [CHANGELOG.md](../../CHANGELOG.md).
