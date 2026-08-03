---
id: "adr-sparkle-updates"
title: "Adr Sparkle Updates"
docforge_provenance:
  schema: "2.0"
  doc_id: "adr-sparkle-updates"
  path: "docs/architecture/decisions/sparkle-updates.md"
  generated_at: "2026-08-03T08:44:33Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "reference"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "context-and-problem-statement"
      sources:
        - path: "EasyKeyApp/UpdateService.swift"
          git_blob: "27386d368017c0c64f38e75fbd5e23e62c7a4dd6"
          role: "code"
        - path: "docs/_archive/RELEASE.md"
          git_blob: "c749b17a004e3cf47af6af61e82db4aa9d40494d"
          role: "doc"
        - path: "Scripts/check-sparkle-pin.sh"
          git_blob: "d5fbfa88d05ef88b6d22a9d792292db0a054e75f"
          role: "code"
        - path: "Scripts/check-sparkle-pin.sh"
          git_blob: "d5fbfa88d05ef88b6d22a9d792292db0a054e75f"
          role: "history"
      unresolved: []
    - id: "decision"
      sources:
        - path: "EasyKeyApp/UpdateService.swift"
          git_blob: "27386d368017c0c64f38e75fbd5e23e62c7a4dd6"
          role: "code"
        - path: "Scripts/generate-appcast.py"
          git_blob: "b11742e9715d352ad971f4ab8d5f3dabf5ef38d9"
          role: "code"
        - path: "docs/_archive/RELEASE.md"
          git_blob: "c749b17a004e3cf47af6af61e82db4aa9d40494d"
          role: "doc"
      unresolved: []
    - id: "consequences"
      sources:
        - path: "Scripts/check-sparkle-pin.sh"
          git_blob: "d5fbfa88d05ef88b6d22a9d792292db0a054e75f"
          role: "code"
        - path: "docs/_archive/RELEASE.md"
          git_blob: "c749b17a004e3cf47af6af61e82db4aa9d40494d"
          role: "doc"
        - path: "docs/_archive/RELEASE.md"
          git_blob: "c749b17a004e3cf47af6af61e82db4aa9d40494d"
          role: "history"
      unresolved: []
    - id: "confirmation"
      sources:
        - path: "EasyKeyTests/UpdateServiceTests.swift"
          git_blob: "7a3f3c8bac4aa57271b3d8a71f14b4bb863f5ceb"
          role: "test"
        - path: "EasyKeyTests/UpdateServiceTestModeTests.swift"
          git_blob: "c424d171b14b52a2e252ab65961808ad0177df7e"
          role: "test"
        - path: "Scripts/test-release-config.sh"
          git_blob: "801f5bc80c467c8b10670db13775136c5d4d517f"
          role: "code"
      unresolved: []
---
# 6. Deliver signed updates via Sparkle 2 with a release-gated appcast

- **Status:** accepted
- **Date:** 2026-07-23
- **Deciders:** project maintainer

## Context and problem statement

EasyKey is distributed outside the App Store as a signed DMG, so it must update itself. Unauthenticated update metadata is an arbitrary-code-execution vector: an attacker who can replace an appcast entry can ship a fake archive. [docs/RELEASE.md](../../engineering/release.md) states the contract: EasyKey uses Sparkle 2, fetches an HTTPS appcast, and verifies every update with Sparkle's EdDSA signature before installation; EasyKey does not implement a custom updater or accept unauthenticated version metadata. `SUFeedURL` and `SUPublicEDKey` are supplied only by release build settings — local builds leave them empty so update checks are disabled rather than pointing at an untrusted endpoint. Two hardening commits secured the pipeline: be5c1b2 ("fix(security): pin Sparkle tarball download by SHA256") adds `Scripts/check-sparkle-pin.sh`, and aaa1d2f ("fix(security): parameterize SPARKLE_PUBLIC_ED_KEY build setting") makes the EdDSA public key a build setting injected from release configuration rather than a committed constant.

## Considered options

- **Sparkle 2 with an HTTPS appcast and EdDSA verification** — chosen.
- **Custom updater** — rejected: reimplementing verified update delivery is a security liability.
- **App Store distribution only** — rejected: the product is distributed as a direct DMG download.
- **Manual download prompts** — rejected: no automatic security patches, no signature-verification story.

## Decision

We chose **Sparkle 2**. `UpdateService` wraps `SPUStandardUpdaterController` and is only instantiated when the bundle actually carries a release configuration: an HTTPS `SUFeedURL` and a non-empty `SUPublicEDKey`, both free of unexpanded `$(` placeholders — otherwise updates are disabled. `Scripts/generate-appcast.py` inserts one release entry into the appcast XML with signature, length, and minimum-system-version fields, validating the DMG URL as absolute HTTPS. The `publish-appcast.yml` workflow signs the released DMG with Sparkle's `sign_update`, appends the entry to `appcast.xml` on the `gh-pages` branch (served over HTTPS), and fires only after a human publishes the draft release — nothing becomes auto-update-eligible before the enclosure URL is public. [docs/RELEASE.md](../../engineering/release.md) documents the full pipeline and its required inputs.

## Decision drivers

- Signed, verified updates are the security baseline for a network-updating desktop app; Sparkle is the established, audited implementation.
- EdDSA verification happens before any archive is opened, and the public key is injected per build rather than committed.
- The draft-release gate keeps unverified artifacts away from users.

## Option comparison

| Option | Good | Neutral | Bad |
|---|---|---|---|
| Sparkle 2 + signed appcast | battle-tested; EdDSA verification; OS-level integration | dependency lifecycle must be maintained (tarball pinning) | requires HTTPS hosting and key management |
| Custom updater | full control | — | homegrown crypto and update logic is a high-risk attack surface |
| App Store only | Apple-managed updates | — | incompatible with direct-DMG distribution |
| Manual download prompts | no update plumbing | — | users stay on old, vulnerable versions |

## Consequences

**Positive:** every delivered update is EdDSA-signed and verified before install; the update channel is disabled in local and test builds so it never polls an unconfigured endpoint; the Sparkle dependency is supply-chain-pinned (SHA256 pin enforced by `check-sparkle-pin.sh`), and the EdDSA public key is a parameterized build setting rather than a committed constant.

**Negative:** release engineering carries real weight — the `SPARKLE_PUBLIC_ED_KEY`/`SPARKLE_PRIVATE_ED_KEY` keypair must be generated and protected as release secrets; the appcast must be hosted and regenerated per release; update timing is partly out of the app's control (Sparkle's scheduler plus a randomized startup delay).

**Neutral:** update-check timing relies on Sparkle's default behavior (a check after the startup delay, then Sparkle's own scheduler interval); a manual "Check for Updates" path remains for users.

## Revisit if

- Sparkle is deprecated or its security posture changes.
- The app moves to App Store distribution (Sparkle becomes irrelevant).
- The EdDSA keypair needs rotation (document the rotation procedure before that happens).
- The tarball pin becomes impractical (for example Sparkle switches distribution channels).

## Confirmation

`UpdateServiceTests` and `UpdateServiceTestModeTests` pin the configuration gating (updates disabled in testing mode and without release configuration); `Scripts/test-release-config.sh` verifies release configuration inputs locally. The SHA-256 tarball pin (`expected_sha256` plus `shasum -a 256 -c -`) is enforced inline by the CI publish workflow, not by a Makefile or QA target: `Scripts/check-sparkle-pin.sh` is a manual verification aid, and `make qa` does not invoke either script.
