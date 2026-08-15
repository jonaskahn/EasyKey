# Distribution

_Last reviewed: 2026-08-15_

EasyKey ships through two channels, both fed by the same universal artifact: direct download of a DMG from the repository's Releases page, and Sparkle in-app updates driven by an HTTPS appcast. What differs per channel is how the artifact is discovered and authenticated. There is no app-store channel — nothing in the repository evinces an app-store submission, approval, or timeline. Both pipelines run with `contents: write` workflow permissions (tag push for the direct channel, `release: released` for the appcast); publishing, revoking, and rolling back are all manual, maintainer-only actions.

## Direct download channel

1. Build — `make local-dmg` on a developer machine, or the tag-push release workflow on CI, which builds a matrix of three DMGs: universal (`arm64 x86_64`), arm64-only, and amd64-only (each non-universal DMG renamed from `-universal` to its target name). The workflow fails the job unless the tag equals the built version.
2. Sign — ad-hoc (`CODE_SIGN_IDENTITY="-"`, `CODE_SIGN_STYLE=Automatic`) in the current public path. The Developer ID path (`CODE_SIGN_IDENTITY=$DEVELOPER_ID_APPLICATION`, Manual style) is implemented in `Scripts/archive.sh` but is not what CI runs today — see Signing status.
3. Package — `Scripts/create-dmg.sh` builds a UDZO disk image (`hdiutil create`) containing the app plus an `/Applications` symlink, named `EasyKey-<version>-universal.dmg`.
4. Publish — the release workflow uploads the three DMGs and creates a **draft** release (`gh release create <tag> <dmgs> --draft`); the maintainer publishes the draft. README points end users at the latest release for download.
5. Verify — `Scripts/verify-arch.sh` confirms every Mach-O binary carries `arm64` and `x86_64`; `Scripts/verify-release.sh` (local path) enforces the bundled `LICENSE`, `NOTICE`, and `THIRD_PARTY_NOTICES.md`, rejects development material and tracked `build/` output. User-side verification: mount the DMG, drag EasyKey into Applications, grant Accessibility at first launch — and, for ad-hoc builds, expect the first-launch Gatekeeper block (Control-click → Open) because the app is not notarized.

## Sparkle update channel

1. Build — the same universal DMG; the appcast workflow requires exactly one `EasyKey-*-universal.dmg` in the release and fails otherwise.
2. Sign — on `release: released`, the appcast workflow downloads the pinned Sparkle 2.9.4 tool tarball and verifies its SHA-256 (`expected_sha256`, checked inline with `shasum -a 256 -c`) before executing anything; `Scripts/check-sparkle-pin.sh` guards that this pin and its check remain present in the workflow, and the changelog records the pin as a released security fix (0.0.7, 2026-07-23). The workflow then signs every released DMG with Sparkle's `sign_update --ed-key-file` using the `SPARKLE_PRIVATE_ED_KEY` secret, which never leaves CI secrets.
3. Publish — `Scripts/generate-appcast.py` inserts a new `<item>` into `appcast.xml` on the `gh-pages` branch: title, `pubDate`, Sparkle `version`/`shortVersionString`/`minimumSystemVersion`, and an enclosure carrying the DMG URL, byte length, and the EdDSA `edSignature`. The script validates that the enclosure URL is absolute HTTPS, that the minimum system version has numeric components only, and refuses to insert a duplicate build number or duplicate enclosure URL; writes are atomic and preserve file mode. The workflow commits and pushes `appcast.xml`.
4. Verify — the enclosure URL points at the published release's download path and is only written after the release is public (the trigger is `release: released`, so the URL always resolves for end users). Client-side, `UpdateService.hasReleaseConfiguration` enables Sparkle only when `SUFeedURL` is an HTTPS URL and `SUPublicEDKey` is a non-empty value with no build-setting tokens (`$(...)`); Sparkle then verifies the EdDSA signature of the downloaded archive before installing.

## Signing status

| Path | Code signing | Notarization | Shipping today? |
|---|---|---|---|
| `make local-dmg` | ad-hoc (`-`) | no | yes — CI runs this and public builds ship this way |
| `make dmg` | Developer ID (Manual) | yes — app and DMG via `notarize.sh` + `staple.sh` | no — scripted and documented, not wired into CI |

Current public builds are universal and ad-hoc signed, but not Developer ID notarized: the release workflow's explicit TODO (Developer ID signing and notarization staged "once Apple cert is available") documents this, and README instructs users who hit the Gatekeeper block to Control-click → Open (or System Settings → Privacy & Security → Open Anyway). The signed path is complete in the repository — `make dmg` archives with Developer ID, exports, notarizes and staples the app, creates the DMG, notarizes and staples the DMG, and runs full `verify-release.sh` including `spctl` assessment; required inputs — `DEVELOPER_ID_APPLICATION`, `DEVELOPMENT_TEAM`, and either `NOTARY_KEYCHAIN_PROFILE` or Apple ID notarization environment variables — are enforced by `Scripts/archive.sh` and `Scripts/notarize.sh`. Until a certificate lands, treat notarized distribution as future capability, not current behavior.

## Update and rollback

Updates run on Sparkle 2 through `SPUStandardUpdaterController` (`EasyKeyApp/Coordination/UpdateService.swift`). `start()` calls `startUpdater()` once at launch; `checkForUpdates()` covers the on-demand path; Sparkle's own scheduler handles subsequent checks. In testing mode (unless a custom test bundle supplies its own release configuration), or whenever the release configuration is absent — `SUFeedURL` not an HTTPS URL, `SUPublicEDKey` empty, or build-setting tokens present — the updater is disabled entirely rather than pointed at an untrusted endpoint, logged as "Sparkle disabled: testing mode, missing HTTPS feed, or EdDSA public key". `Info.plist` parameterizes the feed and key (`$(SPARKLE_FEED_URL)`, `$(SPARKLE_PUBLIC_ED_KEY)`), and `Scripts/test-release-config.sh` asserts the public key is never hardcoded in the Xcode project.

Rollback has the same rigor as publish: every appcast item is EdDSA-signed, and the feed only changes after a human publishes the release. To withdraw a version:

1. Remove its `<item>` from `appcast.xml` and push the `gh-pages` branch (the generator will not overwrite a duplicate, so removal is explicit and versioned).
2. Unpublish or delete the release so direct downloads stop resolving.
3. Tell affected users to reinstall the previous DMG — clients cannot install an archive whose signature does not verify, and there is no server-side kill switch to force a downgrade.

Authorized role for every step: the maintainer. No secret material appears in this procedure: `SPARKLE_PRIVATE_ED_KEY` exists only as a CI secret, and credentials are stored in Keychain or CI secrets.
