---
id: "distribution"
title: "Distribution"
description: "Artifact, build, signing, packaging, channels, verification, update/rollback"
docforge_provenance:
  schema: "2.0"
  doc_id: "distribution"
  path: "docs/operations/distribution.md"
  generated_at: "2026-08-13T11:23:28Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "deep-dive"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "direct-download-channel"
      sources:
        - path: "Makefile"
          git_blob: "06aa63c4ea11d09c149d6fb44b499e07f014f117"
          role: "config"
        - path: "README.md"
          git_blob: "adbd4f30d3c2f11bb855e6645195493a6c6a34f7"
          role: "doc"
        - path: "Scripts/create-dmg.sh"
          git_blob: "28878a2d0cc4198f4b60426136282ceb8351ed2e"
          role: "code"
        - path: "Scripts/verify-arch.sh"
          git_blob: "3a880113167f02293703e9c864a819543a1afd59"
          role: "code"
        - path: "Scripts/verify-release.sh"
          git_blob: "14ed2a9a2ccb51ae5e5a1abc6df85820d82c43ae"
          role: "code"
        - path: "docs/engineering/release.md"
          git_blob: "91aa96ce7f0812ac8d64a6215138d53e485833a6"
          role: "doc"
      unresolved: []
    - id: "sparkle-update-channel"
      sources:
        - path: "EasyKeyApp/Info.plist"
          git_blob: "f4603871fa675111bd6db1472dfb04936ff3f645"
          role: "config"
        - path: "EasyKeyApp/Coordination/UpdateService.swift"
          git_blob: "27386d368017c0c64f38e75fbd5e23e62c7a4dd6"
          role: "code"
        - path: "Scripts/check-sparkle-pin.sh"
          git_blob: "d5fbfa88d05ef88b6d22a9d792292db0a054e75f"
          role: "code"
        - path: "Scripts/generate-appcast.py"
          git_blob: "b11742e9715d352ad971f4ab8d5f3dabf5ef38d9"
          role: "code"
        - path: "docs/engineering/release.md"
          git_blob: "91aa96ce7f0812ac8d64a6215138d53e485833a6"
          role: "doc"
        - path: "Scripts/check-sparkle-pin.sh"
          git_blob: "d5fbfa88d05ef88b6d22a9d792292db0a054e75f"
          role: "history"
      unresolved: []
    - id: "signing-status"
      sources:
        - path: "Makefile"
          git_blob: "06aa63c4ea11d09c149d6fb44b499e07f014f117"
          role: "config"
        - path: "README.md"
          git_blob: "adbd4f30d3c2f11bb855e6645195493a6c6a34f7"
          role: "doc"
        - path: "Scripts/archive.sh"
          git_blob: "188d893ab5a009a3455ba75155b381b4f6f1c392"
          role: "code"
        - path: "Scripts/notarize.sh"
          git_blob: "18256dcf44a32ce9c2cef44d2196ee44fef8fd63"
          role: "code"
        - path: "Scripts/staple.sh"
          git_blob: "80200416ce69633be60a3d3317fcc27799ee7a7f"
          role: "code"
        - path: "Scripts/verify-release.sh"
          git_blob: "14ed2a9a2ccb51ae5e5a1abc6df85820d82c43ae"
          role: "code"
        - path: "docs/engineering/release.md"
          git_blob: "91aa96ce7f0812ac8d64a6215138d53e485833a6"
          role: "doc"
      unresolved: []
    - id: "update-and-rollback"
      sources:
        - path: "EasyKeyApp/Info.plist"
          git_blob: "f4603871fa675111bd6db1472dfb04936ff3f645"
          role: "config"
        - path: "EasyKeyApp/Coordination/UpdateService.swift"
          git_blob: "27386d368017c0c64f38e75fbd5e23e62c7a4dd6"
          role: "code"
        - path: "Scripts/generate-appcast.py"
          git_blob: "b11742e9715d352ad971f4ab8d5f3dabf5ef38d9"
          role: "code"
        - path: "docs/engineering/release.md"
          git_blob: "91aa96ce7f0812ac8d64a6215138d53e485833a6"
          role: "doc"
      unresolved: []
---
# Distribution

_Last reviewed: 2026-08-13_

EasyKey ships through two channels, both fed by the same universal artifact: direct download of a DMG from the repository's Releases page, and Sparkle in-app updates driven by an HTTPS appcast. What differs per channel is how the artifact is discovered and authenticated. There is no app-store channel — nothing in the repository evinces an app-store submission, approval, or timeline. The authorized operator for every channel is the maintainer, who holds release-write and `gh-pages` write access; publishing, revoking, and rolling back are all manual, maintainer-only actions.

## Direct download channel

1. Build — `make local-dmg` on a developer machine, or the tag-push release workflow on CI, which builds a matrix of three DMGs: universal (`arm64 x86_64`), arm64-only, and amd64-only (each non-universal DMG renamed from `-universal` to its target name). The workflow fails the job unless the tag equals the built version.
2. Sign — ad-hoc (`CODE_SIGN_IDENTITY="-"`, `CODE_SIGN_STYLE=Automatic`) in the current public path. The Developer ID path (`CODE_SIGN_IDENTITY=$DEVELOPER_ID_APPLICATION`, Manual style) is implemented in `Scripts/archive.sh` but is not what CI runs today — see Signing status.
3. Package — `Scripts/create-dmg.sh` builds a UDZO disk image (`hdiutil create`) containing the app plus an `/Applications` symlink, named `EasyKey-<version>-universal.dmg`.
4. Publish — the release workflow uploads the three DMGs and creates a **draft** release (`gh release create <tag> <dmgs> --draft`); the maintainer publishes the draft. [README](../README.md) points end users at the latest release for download.
5. Verify — `Scripts/verify-arch.sh` confirms every Mach-O binary carries `arm64` and `x86_64`; `Scripts/verify-release.sh` (local path) enforces the bundled `LICENSE`, `NOTICE`, and `THIRD_PARTY_NOTICES.md`, rejects development material and tracked `build/` output. User-side verification: mount the DMG, drag EasyKey into Applications, grant Accessibility at first launch — and, for ad-hoc builds, expect the first-launch Gatekeeper block (Control-click → Open) because the app is not notarized.

## Sparkle update channel

1. Build — the same universal DMG; the appcast workflow requires exactly one `EasyKey-*-universal.dmg` in the release and fails otherwise.
2. Sign — on `release: released`, the appcast workflow downloads the pinned Sparkle 2.9.4 tool tarball and verifies its SHA-256 (`expected_sha256`, checked inline with `shasum -a 256 -c`) before executing anything; `Scripts/check-sparkle-pin.sh` guards that this pin and its check remain present in the workflow, a pin in place since commit `be5c1b2` ("fix(security): pin Sparkle tarball download by SHA256"). The workflow then signs every released DMG with Sparkle's `sign_update --ed-key-file` using the `SPARKLE_PRIVATE_ED_KEY` secret, which never leaves CI secrets.
3. Publish — `Scripts/generate-appcast.py` inserts a new `<item>` into `appcast.xml` on the `gh-pages` branch: title, `pubDate`, Sparkle `version`/`shortVersionString`/`minimumSystemVersion`, and an enclosure carrying the DMG URL, byte length, and the EdDSA `edSignature`. The script validates that the enclosure URL is absolute HTTPS, that the minimum system version has numeric components only, and refuses to insert a duplicate build number or duplicate enclosure URL; writes are atomic and preserve file mode. The workflow commits and pushes `appcast.xml`.
4. Verify — the enclosure URL points at the published release's download path and is only written after the release is public (the trigger is `release: released`, so the URL always resolves for end users). Client-side, `UpdateService.hasReleaseConfiguration` enables Sparkle only when `SUFeedURL` is an HTTPS URL and `SUPublicEDKey` is a non-empty value with no build-setting tokens (`$(...)`); Sparkle then verifies the EdDSA signature of the downloaded archive before installing, per [release.md](../engineering/release.md).

## Signing status

| Path | Code signing | Notarization | Shipping today? |
|---|---|---|---|
| `make local-dmg` | ad-hoc (`-`) | no | yes — CI runs this and public builds ship this way |
| `make dmg` | Developer ID (Manual) | yes — app and DMG via `notarize.sh` + `staple.sh` | no — scripted and documented, not wired into CI |

Current public builds are universal and ad-hoc signed, but not Developer ID notarized: [README](../README.md) states this and instructs users to Control-click → Open (or System Settings → Privacy & Security → Open Anyway) on first launch. The signed path is complete in the repository — `make dmg` archives with Developer ID, exports, notarizes and staples the app, creates the DMG, notarizes and staples the DMG, and runs full `verify-release.sh` including `spctl` assessment; required inputs are listed in [release.md](../engineering/release.md) (`DEVELOPER_ID_APPLICATION`, `DEVELOPMENT_TEAM`, and either `NOTARY_KEYCHAIN_PROFILE` or Apple ID notarization environment variables). CI's release workflow carries an explicit TODO to re-enable this path once an Apple Developer certificate is available. Until then, treat notarized distribution as future capability, not current behavior.

## Update and rollback

Updates run on Sparkle 2 through `SPUStandardUpdaterController` (`EasyKeyApp/Coordination/UpdateService.swift`). `start()` calls `startUpdater()` once at launch; `checkForUpdates()` covers the on-demand path; Sparkle's own scheduler handles subsequent checks. In testing mode (unless a custom test bundle supplies its own release configuration), or whenever the release configuration is absent — `SUFeedURL` not an HTTPS URL, `SUPublicEDKey` empty, or build-setting tokens present — the updater is disabled entirely rather than pointed at an untrusted endpoint, logged as "Sparkle disabled: testing mode, missing HTTPS feed, or EdDSA public key". `Info.plist` parameterizes the feed and key (`$(SPARKLE_FEED_URL)`, `$(SPARKLE_PUBLIC_ED_KEY)`), and `Scripts/test-release-config.sh` asserts the public key is never hardcoded in the Xcode project.

Rollback has the same rigor as publish: every appcast item is EdDSA-signed, and the feed only changes after a human publishes the release. To withdraw a version:

1. Remove its `<item>` from `appcast.xml` and push the `gh-pages` branch (the generator will not overwrite a duplicate, so removal is explicit and versioned).
2. Unpublish or delete the release so direct downloads stop resolving.
3. Tell affected users to reinstall the previous DMG — clients cannot install an archive whose signature does not verify, and there is no server-side kill switch to force a downgrade.

Authorized role for every step: the maintainer. No secret material appears in this procedure: `SPARKLE_PRIVATE_ED_KEY` exists only as a CI secret, and credentials are stored in Keychain or CI secrets per [release.md](../engineering/release.md).
