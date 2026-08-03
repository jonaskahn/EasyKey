---
id: "existing-release"
title: "Release Process"
docforge_provenance:
  schema: "2.0"
  doc_id: "existing-release"
  path: "docs/RELEASE.md"
  generated_at: "2026-08-03T10:27:57+00:00"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "reference"
  graph:
    provider: "codegraph"
    flow: "none"
  sections: []
---
# EasyKey Release Guide

## Updater Decision

EasyKey uses Sparkle 2. It fetches an HTTPS appcast and verifies every update
with Sparkle's EdDSA signature before installation. EasyKey does not implement a
custom updater or accept unauthenticated version metadata.

`SUFeedURL` and `SUPublicEDKey` are supplied only by release build settings.
Local builds leave them empty, so update checks are disabled rather than using an
untrusted endpoint. Publish each appcast over HTTPS and sign every archive with
Sparkle's `sign_update` tool before publishing its appcast entry.

## Required Release Inputs

- `DEVELOPER_ID_APPLICATION`: Developer ID Application certificate name.
- `DEVELOPMENT_TEAM`: Apple Developer team identifier.
- `SPARKLE_FEED_URL`: HTTPS URL for signed appcast.
- `SPARKLE_PUBLIC_ED_KEY`: Sparkle EdDSA public key (parameterized as `$(SPARKLE_PUBLIC_ED_KEY)` in Xcode build settings).
- `EASYKEY_SUPPORT_URL`: HTTPS support page URL.
- `EASYKEY_PRIVACY_POLICY_URL`: HTTPS privacy-policy URL.
- `NOTARY_KEYCHAIN_PROFILE`: `notarytool` keychain profile name.

CI uses `NOTARY_APPLE_ID`, `NOTARY_APP_SPECIFIC_PASSWORD`, and
`DEVELOPMENT_TEAM` instead of a local Keychain profile.

Store Apple credentials in Keychain or CI secrets. Never commit them.

## Automated Release + Appcast (CI)

Two workflows cover the pipeline:

- `.github/workflows/release.yml` — on tag push (`v*`), imports the Developer ID
  certificate, builds and notarizes universal, arm64, and amd64 DMGs (`make dmg`),
  and creates a **draft** GitHub Release with all three DMGs attached.
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
- Signing secrets: `BUILD_CERTIFICATE_BASE64`, `BUILD_CERTIFICATE_PASSWORD`,
  `KEYCHAIN_PASSWORD`, `DEVELOPER_ID_APPLICATION`, and `DEVELOPMENT_TEAM`.
- Notarization secrets: `NOTARY_APPLE_ID` and `NOTARY_APP_SPECIFIC_PASSWORD`.
- Sparkle secrets: `SPARKLE_PUBLIC_ED_KEY` and `SPARKLE_PRIVATE_ED_KEY` (EdDSA
  keypair from Sparkle's `generate_keys`; private key never leaves CI secrets).

In-app behavior: `UpdateService` checks the appcast once per launch, after a
randomized 30-60s startup delay (`UpdateService.startupCheckDelayRange`), then
defers to Sparkle's own scheduled interval for subsequent checks.

## Architecture

CI publishes **universal** (arm64 + x86_64), arm64-only, and amd64-only
(x86_64) DMGs. Sparkle uses `EasyKey-<version>-universal.dmg`; architecture-
specific DMGs are additional manual downloads. Scripts accept `ARCHS` and
`REQUIRED_ARCHS` overrides for these builds. Verify with `make verify-arch`
(or `Scripts/verify-arch.sh`).

## Build And Distribute

Before packaging a candidate, run `make qa` (tests plus provenance/artifact checks).

### Signed distribution (Developer ID)

1. Run `Scripts/archive.sh` with required release inputs (or `make archive`).
2. Run `Scripts/export.sh` (or `make export`).
3. Notarize and staple the app.
4. Create the DMG.
5. Notarize and staple the DMG.
6. Run release integrity, architecture, Gatekeeper, and stapler validation.

`make dmg` performs this complete sequence. `Scripts/notarize.sh` accepts either
`NOTARY_KEYCHAIN_PROFILE` or Apple ID notarization environment variables.

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
