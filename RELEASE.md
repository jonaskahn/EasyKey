# EasyKey Release Guide

## Updater Decision

EasyKey uses Sparkle 2. It fetches an HTTPS appcast and verifies every update
with Sparkle's EdDSA signature before installation. EasyKey does not implement a
custom updater or accept unauthenticated version metadata.

`SUFeedURL` and `SUPublicEDKey` are supplied only by release build settings.
Local builds leave them empty, so update checks are disabled rather than using an
untrusted endpoint. Publish each appcast over HTTPS and sign every archive with
Sparkle's `generate_appcast` tooling before upload.

## Required Release Inputs

- `DEVELOPER_ID_APPLICATION`: Developer ID Application certificate name.
- `DEVELOPMENT_TEAM`: Apple Developer team identifier.
- `SPARKLE_FEED_URL`: HTTPS URL for signed appcast.
- `SPARKLE_PUBLIC_ED_KEY`: Sparkle EdDSA public key.
- `EASYKEY_SUPPORT_URL`: HTTPS support page URL.
- `EASYKEY_PRIVACY_POLICY_URL`: HTTPS privacy-policy URL.
- `NOTARY_KEYCHAIN_PROFILE`: `notarytool` keychain profile name.

Store Apple credentials in Keychain or CI secrets. Never commit them.

## Automated Release + Appcast (CI)

Two workflows cover the pipeline:

- `.github/workflows/release.yml` — on tag push (`v*`), builds an ad-hoc
  universal DMG (`make local-dmg`) with `SPARKLE_FEED_URL` / `SPARKLE_PUBLIC_ED_KEY`
  baked in, and creates a **draft** GitHub Release with the DMG attached.
- `.github/workflows/publish-appcast.yml` — fires on `release: released`
  (i.e. once a maintainer publishes the draft), signs the released DMG with
  Sparkle's `sign_update`, and appends a new `<item>` to `appcast.xml` on the
  `gh-pages` branch via `Scripts/generate-appcast.py`.

The draft gate is intentional: nothing is auto-update-eligible until a human
publishes the release, since the appcast enclosure URL must resolve publicly.

Required repo configuration (already set for this repo):

- Variables: `SPARKLE_FEED_URL` = `https://jonaskahn.github.io/EasyKey/appcast.xml`
  (served from the `gh-pages` branch, GitHub Pages enabled), `EASYKEY_SUPPORT_URL`,
  `EASYKEY_PRIVACY_POLICY_URL`.
- Secrets: `SPARKLE_PUBLIC_ED_KEY`, `SPARKLE_PRIVATE_KEY` (EdDSA keypair from
  Sparkle's `generate_keys` tool — public key embeds in the app, private key
  signs releases and never leaves CI secrets).

In-app behavior: `UpdateService` checks the appcast once per launch, after a
randomized 30-60s startup delay (`UpdateService.startupCheckDelayRange`), then
defers to Sparkle's own scheduled interval for subsequent checks.

## Architecture

Release archives and DMGs are **universal** (arm64 + x86_64) in a single
`EasyKey.app` / `EasyKey-<version>-universal.dmg`. Scripts pass
`ARCHS="arm64 x86_64"` and `ONLY_ACTIVE_ARCH=NO`. Verify with
`make verify-arch` (or `Scripts/verify-arch.sh`).

## Build And Distribute

Before packaging a candidate, run `make qa` (tests plus provenance/artifact checks).

### Signed distribution (Developer ID)

1. Run `Scripts/archive.sh` with required release inputs (or `make archive`).
2. Run `Scripts/export.sh` (or `make export`).
3. Run `Scripts/notarize.sh build/export/EasyKey.app`.
4. Run `Scripts/staple.sh build/export/EasyKey.app`.
5. Run `Scripts/verify-release.sh` / `make verify-release` (and `make verify-arch`).
6. Run `Scripts/create-dmg.sh build/export/EasyKey.app`.
7. Staple and assess generated DMG before publishing it.

Or: `make dmg` (archive → export → verify → DMG; still requires env vars).

### Local universal DMG (no secrets)

When Developer ID / notary credentials are unavailable:

```bash
make local-dmg
```

Produces an ad-hoc-signed universal app under `build/export/EasyKey.app` and
`build/EasyKey-<version>-universal.dmg`. Notarization and stapling are skipped; set the
required release inputs and use the signed path above before shipping.

## Manual Release Gates

- Fresh install, upgrade install, uninstall/reinstall.
- Login helper starts after reboot and after macOS upgrade.
- Accessibility remains authorized after replacing app in same location; document
  reauthorization if bundle identity or signing team changes.
- Sparkle rejects an unsigned or incorrectly signed update archive.
- Archive contains only EasyKey binaries, Sparkle, MIT `LICENSE`, independent
  implementation `NOTICE`, and reviewed `THIRD_PARTY_NOTICES.md`.
- Verify privacy copy still matches runtime behavior: typing local; Apple Translation
  local; cloud requests sent directly to selected provider only from EasyKey translation
  surfaces, on explicit translation or configured auto-translation; credentials in
  Keychain; no translation history/source/result persistence.
- Review every provider data-handling URL in `PRIVACY.md` and Translation settings.
  Provider names and links are informational and must not imply sponsorship or endorsement.
- Run English/Vietnamese localization checks, macOS 14 Apple-surface tests, automated
  accessibility audits, and manual VoiceOver/keyboard/large-text/reduced-motion passes.
