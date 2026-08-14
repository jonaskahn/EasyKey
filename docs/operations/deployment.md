---
id: "deployment"
title: "Deployment"
description: "Environments, artifact path, rollout, rollback, verification"
docforge_provenance:
  schema: "2.0"
  doc_id: "deployment"
  path: "docs/operations/deployment.md"
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
    - id: "public-release"
      sources:
        - path: "Makefile"
          git_blob: "b0926ee99352f08ba3eb3475b4ef45bfc143fe65"
          role: "config"
        - path: "Scripts/ExportOptions.plist"
          git_blob: "055f67c2cf424682917ab22bb9384690d1830e7e"
          role: "config"
        - path: "Scripts/archive.sh"
          git_blob: "188d893ab5a009a3455ba75155b381b4f6f1c392"
          role: "code"
        - path: "Scripts/create-dmg.sh"
          git_blob: "28878a2d0cc4198f4b60426136282ceb8351ed2e"
          role: "code"
        - path: "Scripts/export.sh"
          git_blob: "e170e5fc9d887543ed6fffe7b757544380376ae1"
          role: "code"
        - path: "Scripts/notarize.sh"
          git_blob: "18256dcf44a32ce9c2cef44d2196ee44fef8fd63"
          role: "code"
        - path: "Scripts/qa-gate.sh"
          git_blob: "148320feb241615087d1cda4ef51cac8706e78bf"
          role: "code"
        - path: "Scripts/staple.sh"
          git_blob: "80200416ce69633be60a3d3317fcc27799ee7a7f"
          role: "code"
        - path: "Scripts/verify-arch.sh"
          git_blob: "3a880113167f02293703e9c864a819543a1afd59"
          role: "code"
        - path: "Scripts/verify-qa-artifacts.sh"
          git_blob: "11ce62a91f372b4527c134c17645b8c7b655f51b"
          role: "code"
        - path: "Scripts/verify-release.sh"
          git_blob: "14ed2a9a2ccb51ae5e5a1abc6df85820d82c43ae"
          role: "code"
        - path: "docs/engineering/release.md"
          git_blob: "2ce283a3b97b5c88404c873e91f1d2c20e429c18"
          git_blob_normalized: "2ce283a3b97b5c88404c873e91f1d2c20e429c18"
          role: "doc"
      unresolved: []
    - id: "ci-pipeline"
      sources:
        - path: "Makefile"
          git_blob: "b0926ee99352f08ba3eb3475b4ef45bfc143fe65"
          role: "config"
        - path: "Scripts/archive.sh"
          git_blob: "188d893ab5a009a3455ba75155b381b4f6f1c392"
          role: "code"
        - path: "docs/engineering/release.md"
          git_blob: "2ce283a3b97b5c88404c873e91f1d2c20e429c18"
          git_blob_normalized: "2ce283a3b97b5c88404c873e91f1d2c20e429c18"
          role: "doc"
      unresolved: []
    - id: "rollback"
      sources:
        - path: "Scripts/generate-appcast.py"
          git_blob: "b11742e9715d352ad971f4ab8d5f3dabf5ef38d9"
          role: "code"
        - path: "docs/engineering/release.md"
          git_blob: "2ce283a3b97b5c88404c873e91f1d2c20e429c18"
          git_blob_normalized: "2ce283a3b97b5c88404c873e91f1d2c20e429c18"
          role: "doc"
      unresolved: []
    - id: "environment-differences"
      sources:
        - path: "Makefile"
          git_blob: "b0926ee99352f08ba3eb3475b4ef45bfc143fe65"
          role: "config"
        - path: "README.md"
          git_blob: "0de1699403dbb6d0d24b58a2963cde1ac952a70e"
          role: "doc"
        - path: "docs/engineering/release.md"
          git_blob: "2ce283a3b97b5c88404c873e91f1d2c20e429c18"
          git_blob_normalized: "2ce283a3b97b5c88404c873e91f1d2c20e429c18"
          role: "doc"
      unresolved: []
---
# Deployment

_Last reviewed: 2026-08-13_

EasyKey is a macOS menu-bar utility with exactly one deployable artifact — a universal (arm64 + x86_64) `.app` packaged as a DMG — and one delivery environment: the public release channel. The repository has no staging environment and no separate `environments.md`; the only meaningful axis is local (developer machine) versus CI (tag-triggered workflow), covered under Environment differences. The maintainer is the sole authorized operator for both paths: local runs of `make dmg` / `make local-dmg`, and publishing the draft release that CI produces. Incident recovery belongs to the [runbooks](runbooks/README.md) section, not here.

## Public release

**Artifact source:** `Scripts/archive.sh` produces `build/archives/EasyKey.xcarchive` via `xcodebuild archive` (scheme `EasyKeyApp`, Release configuration, `ARCHS="arm64 x86_64"`, `ONLY_ACTIVE_ARCH=NO` by default). `Scripts/export.sh` exports that archive with `xcodebuild -exportArchive` using `Scripts/ExportOptions.plist` (`method = developer-id`) into `build/export/EasyKey.app`. `Scripts/create-dmg.sh` packages the app with `hdiutil` (UDZO format, volume name `EasyKey <version>`, an `/Applications` symlink) into `build/EasyKey-<version>-universal.dmg`, reading `CFBundleShortVersionString` from the app's `Info.plist`.

**Rollout strategy:** tag-push, draft-gated release — closest to a blue-green in effect. Pushing a `v*` tag builds the DMGs and creates a **draft** release; nothing is user-visible until a maintainer publishes the draft, and the Sparkle appcast gains its entry only after publication (`release: released`). The new version therefore becomes update-eligible at the moment of publication, not at build time. There is no canary or percentage rollout: every client that passes the EdDSA signature check sees the same new version.

1. Run `make qa` before packaging a candidate — verify: `Scripts/qa-gate.sh` exits 0 (tests pass, `Scripts/verify-qa-artifacts.sh` confirms the fixture suite, the conformance test, the keyboard-service integration test host, and the settings workflow UI tests all exist, and `Scripts/check-test-registration.sh` confirms every test is registered in the project).
2. Archive the release build — `Scripts/archive.sh` (or `make archive`) with `DEVELOPER_ID_APPLICATION`, `DEVELOPMENT_TEAM`, `SPARKLE_FEED_URL`, `SPARKLE_PUBLIC_ED_KEY`, `EASYKEY_SUPPORT_URL`, `EASYKEY_PRIVACY_POLICY_URL`; the script enforces HTTPS on all three URLs and fails on missing variables — verify: archive exists at `build/archives/EasyKey.xcarchive` and the script prints "Signed archive created".
3. Export the app — `Scripts/export.sh` (or `make export`); the script refuses to run without an existing archive — verify: `build/export/EasyKey.app` exists.
4. Verify architecture — `Scripts/verify-arch.sh` walks every Mach-O binary with `lipo -archs` — verify: every binary reports `arm64` and `x86_64` and the script prints "Architecture verification passed".
5. Verify the signature — `codesign --verify --deep --strict --verbose=2 build/export/EasyKey.app` — verify: exit 0.
6. Notarize the app — `Scripts/notarize.sh` (zips a `.app` with `ditto` before `xcrun notarytool submit ... --wait`; credentials from `NOTARY_KEYCHAIN_PROFILE` or `APPLE_ID`/`APPLE_TEAM_ID`/`APPLE_APP_SPECIFIC_PASSWORD`) — verify: `notarytool` reports success.
7. Staple the app — `Scripts/staple.sh` runs `xcrun stapler staple` then `xcrun stapler validate` — verify: both exit 0.
8. Create the DMG — `DMG_PATH=<path> Scripts/create-dmg.sh build/export/EasyKey.app` — verify: the DMG file exists at the target path.
9. Notarize and staple the DMG — same two scripts, now against the DMG — verify: notarytool success, `stapler validate` success.
10. Run release verification — `Scripts/verify-release.sh build/export/EasyKey.app <dmg>` — verify: exits 0 and prints "Release verification passed". It runs `verify-arch.sh` and `verify-macos-compatibility.sh` (macOS 14 deployment target, weak Translation linkage), then re-checks `codesign --verify --deep --strict`, `spctl --assess --type execute`, and for the DMG `xcrun stapler validate` plus `spctl --assess --type open --context context:primary-signature`; it also fails on missing bundled `LICENSE`, `NOTICE`, or `THIRD_PARTY_NOTICES.md`, on any development material under `fixtures/`, `sources/`, `diagnostics/`, or `capture/`, and on tracked `build/` output.

`make dmg` runs steps 2–10 as one target, gated by `release-config-check` (which fails unless `SPARKLE_PUBLIC_ED_KEY` is set). `make dmg` is the single verified signed path.

## CI pipeline

Pushing a `v*` tag triggers the release workflow (`release.yml`), which runs a matrix of three builds on `macos-15` runners — universal (`arm64 x86_64`), arm64-only, and amd64-only (`ARCHS`/`REQUIRED_ARCHS` overrides). Each job executes `make local-dmg` (the ad-hoc path, not `make dmg` — see below), then:

- Reads the built version and fails the job unless the tag matches it exactly (`v<built version>`), so a tag always names the artifact it carries.
- Renames the non-universal DMGs from `-universal` to their target name.
- Uploads each DMG as a workflow artifact (30-day retention).

A release job then downloads all three DMGs and runs `gh release create <tag> ... --generate-notes --draft`: the release is always created as a **draft**, and only the maintainer's manual publish exposes it to users. The draft gate is deliberate — nothing is auto-update-eligible until the release is public, because the Sparkle enclosure URL must resolve publicly.

**Current CI state, stated honestly:** the workflow carries a TODO to re-enable Developer ID signing and notarization (a certificate-import step plus `make dmg`) "once Apple cert is available". Today CI runs the ad-hoc `make local-dmg` path, so artifacts CI produces are ad-hoc signed and not notarized. The signed `make dmg` pipeline in the Public release section is fully scripted and documented in [release.md](../engineering/release.md), but it is not what CI executes today and not what public builds ship as.

## Rollback

There is no automated rollback — by design the draft gate is the primary mitigation, and the appcast is only updated after publication, so a broken build never reaches clients through the update channel. Rollback is a manual, maintainer-only procedure:

1. If the draft was never published — delete the draft release. Verify: no release page exists for the tag and the appcast contains no item for it.
2. If the release was published — re-issue the previous good version (create a release for the previous tag, or replace the assets on the current one) and regenerate `appcast.xml` with the bad `<item>` removed. `Scripts/generate-appcast.py` refuses to insert a duplicate build number or duplicate enclosure URL (it raises `ValueError`), so the feed can never silently contain two versions of the same build — the edit is a deliberate removal plus regeneration. Verify: the channel contains exactly one item per version and every enclosure URL resolves over HTTPS.
3. For users who already installed the bad version — clients cannot install an archive whose Sparkle EdDSA signature does not verify, so a malformed update is rejected client-side; a user with a genuinely bad signed version reinstalls the previous DMG manually. There is no server-side kill switch.

```bash
xmllint --noout appcast.xml
xcrun stapler validate build/EasyKey-<version>-universal.dmg
spctl --assess --type open --context context:primary-signature --verbose=4 build/EasyKey-<version>-universal.dmg
```

Authorized role and boundary: the maintainer, who holds release-write and `gh-pages` write access. There is no on-call rotation and no escalation path — diagnosis of a bad deployment lives in the [runbooks](runbooks/README.md) section.

## Environment differences

There is no separate environment document in this repository; the environment axis is entirely captured by three Make targets, all of which first pass `release-config-check`:

| Aspect | Local (`make local-dmg`) | CI tag push | Signed (`make dmg`) |
|---|---|---|---|
| Signing | ad-hoc (`CODE_SIGN_IDENTITY="-"`, `CODE_SIGN_STYLE=Automatic`, `DEVELOPMENT_TEAM=""`) | same ad-hoc path today | Developer ID (`CODE_SIGN_IDENTITY=$DEVELOPER_ID_APPLICATION`, Manual style) |
| Notarization | skipped | skipped (TODO to re-enable) | `notarize.sh` + `staple.sh` on the app and on the DMG |
| Verification | `verify-arch.sh` + `verify-macos-compatibility.sh` + content checks; `verify-release.sh` skips codesign/spctl when `RELEASE_LOCAL=1` | `make local-dmg` path plus tag-versus-version check | full `verify-release.sh` (codesign, `spctl`, stapler, macOS 14 compatibility) |
| Rollout | none (local file only) | draft release, human-published | same draft gate when published through CI |

Config is identical across all three: `SPARKLE_FEED_URL`, `SPARKLE_PUBLIC_ED_KEY`, `EASYKEY_SUPPORT_URL`, and `EASYKEY_PRIVACY_POLICY_URL` must all be set and HTTPS in the local and CI release paths (the signed path additionally requires `DEVELOPER_ID_APPLICATION` and `DEVELOPMENT_TEAM`, and notarization requires keychain or Apple ID credentials — stored in Keychain or CI secrets, never committed). [README](../README.md) and [release.md](../engineering/release.md) document the same split for end users and maintainers respectively.
