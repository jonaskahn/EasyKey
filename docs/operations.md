# Operations

_Last reviewed: 2026-10-16_

Treat CI green and a the release archive draft as **hosted-runner trust**, not as proof that Accessibility, onboarding UI, or Apple TranslationSession tests passed on a real Mac. Signing is a separate claim: the Release workflow runs `make dmg`, whose `verify-release` step asserts Developer ID signing, the hardened runtime, notarization stapling and `spctl` acceptance, so a green Release job is evidence of those — not of real-Mac behavior. This file is the compact operations section for operators and engineers who ship EasyKey.app: how a change reaches a DMG and Sparkle appcast, what you can actually observe, and which failure modes are named but not written as procedures. Local checkout setup and everyday test commands belong in the engineering section; threat and secret handling belong in the security section.

## At a glance

A change lands on `main` through the CI workflow (lint, standalone Core/Kit builds, sharded tests, 90% coverage). Shipping a user-visible build is a **tag `v*` → Release workflow (`make dmg`) → draft the release archive → a human publishes the release → Publish Appcast writes `appcast.xml` on `gh-pages`**. Installed apps then pull that HTTPS feed through Sparkle. Two trust paths stay distinct: hosted `macos-15` runners decide merge, and an operator Mac with a logged-in GUI session is the only place Accessibility/window-activation and TranslationSession tests are expected to be real. The Release workflow imports the Developer ID certificate from GitHub secrets and signs and notarizes every DMG; `make dmg` on an operator Mac runs the identical path for local reproduction.

Reading paths: [Deployment](#deployment) for environments and rollback; [Observability](#observability) for signals and blind spots; [Distribution](#distribution) for the release archive host and Sparkle; [Runbook index](#runbook-index) for named incidents. Parent index: [Documentation](README.md). Written sibling for structure: [architecture.md](architecture.md).

## Scope and boundaries

This file owns CI merge gates, the coverage gate, DMG artifact paths, the release archive and Sparkle publish, OSLog/export, and the runbook register. It does not own local clone/setup, everyday `make test` pedagogy, product behavior, runtime flow steps, threat modeling, or Keychain/TCC policy. Neighbouring sections: architecture (deployable blocks and Sparkle-in-context), engineering (contributor build/test), security (permissions and secrets), reference (user-visible settings), product, flows, contributing, decisions. Compact layout has **no unmerged files** under an operations folder; every selected operations member is a heading below.

## Deployment

**Guarantee.** Merge trusts blocking CI shards plus the 90% coverage job. User-facing shipping trusts a published the release archive plus a pushed appcast. Those are not the same gate.

**Environments (name every one, then detail).** the CI pipeline CI (`macos-15`, push/PR to `main`). the CI pipeline Release (`macos-15` tag `v*`, then Ubuntu to attach assets). Operator Mac (signed `make dmg`, same path CI runs). Installed user Mac (Sparkle client). There is no blue-green, canary, or rolling fleet: CI is merge-to-`main`; Release is **gated draft-then-publish**; Sparkle is a **single appcast** (broadcast).

**CI (`macos-15`).** Artifact is the checkout plus `xcodebuild` products under `build/`. Rollout is merge to `main` (concurrency group `ci-*`, cancel-in-progress). Jobs: `lint` (`swiftformat --lint .`, `swiftlint lint`); `structure` (test-target registration script, standalone EasyEngineCore then EasyKeyKit Debug builds); `test` matrix (four unit shards, five UI shards, plus `ui-known-broken-on-hosted-runner`); `coverage` after all test shards (threshold `90`, LoginHelper lines excluded). Each blocking test shard: 60-minute job timeout, per-test allowance 600s, **no** retry-on-failure, fail if the shard executed zero tests. Verify: every blocking shard green; coverage prints `Coverage gate passed (>= 90%)`. Rollback: revert the merge commit and re-run CI. **Do not treat a green merge as AX/onboarding/TranslationSession proof** — shard `ui-known-broken-on-hosted-runner` uses `continue-on-error` so those tests never block merge.

**Release (tag `v*`).** Artifact is `make dmg` (Developer ID signed, hardened runtime, notarized and stapled). Matrix: universal (`arm64 x86_64`), arm64, amd64 (`x86_64`); non-universal DMGs are renamed off the `-universal` suffix. Requires `SPARKLE_FEED_URL`, `SPARKLE_PUBLIC_ED_KEY`, support and privacy HTTPS URLs, plus the signing/notarization secrets listed under [Distribution](#distribution). The job first runs **Import Developer ID certificate**, which decodes `APPLE_SIGN_P12_BASE64` into a throwaway keychain under `$RUNNER_TEMP`, unlocks it for `codesign`, and exports `DEVELOPER_ID_APPLICATION` (the certificate SHA-1) and `DEVELOPMENT_TEAM` for the build step. Verify: `CFBundleShortVersionString` equals the tag without the `v` prefix; upload `EasyKey-*-{universal,arm64,amd64}.dmg`; `verify-release` inside `make dmg` prints `Release verification passed` after `codesign --verify`, the hardened-runtime flag check, `spctl --assess --type execute` and stapler/`spctl` checks on the DMG. Rollout: `gh release create --draft`. Rollback: leave the draft unpublished or delete the draft; do not fire Publish Appcast. A missing secret fails the import step with `run 'make update-secrets' first`, so no unsigned artifact can reach the draft.

**Operator Mac (signed).** Run `make dmg` with the same credentials CI uses, supplied as environment variables instead of GitHub secrets (`DEVELOPER_ID_APPLICATION`, `DEVELOPMENT_TEAM`, `SPARKLE_PUBLIC_ED_KEY`, `APPLE_ID`, `APPLE_TEAM_ID`, `APPLE_APP_SPECIFIC_PASSWORD`, plus the Sparkle/support/privacy URLs). Path: `release-config-check` → archive → export → arch check → `codesign --verify --deep --strict` → notarize app → staple app → create DMG → notarize DMG → staple DMG → `verify-release`. Verify: that command prints `Release verification passed` and `spctl`/stapler checks succeed. This is a local reproduction of the CI Release job, not a separate distribution path. Rollback: do not upload; keep the previous published DMG as the channel artifact. Incident recovery after a bad **published** feed is not a deploy step (register below).

**Installed Mac.** No server rollout. Verify: Sparkle starts only when the bundle has HTTPS `SUFeedURL` and a non-placeholder `SUPublicEDKey`, and never from a test process. Rollback: install the previous the release archive DMG; Sparkle does not auto-rollback.

**Local vs CI test layout.** `make coverage` / `make test` run the full hosted bundle on **your** Mac (including tests CI skips from blocking shards). `make test-parallel` is four coarse shards run **serially** on one Mac (UI and app-hosted unit tests cannot share one `EasyKey.app`). CI is **not** a Makefile mirror: four unit + five UI + one known-broken shard, each on its own runner.

## Observability

**Alert intent first.** Nothing pages. CI job failure is a merge/release check (stop merge or stop a release job). App and keyboard health is **log-for-later** (OSLog + Settings health pill). Coverage below 90% fails the `coverage` job, not an on-call rotation.

| Signal | Source | Visible in | Owner | Alert intent |
|---|---|---|---|---|
| Latency | Keyboard tap callback durations (in-process ring, median helper) | Process memory / tests, not a dashboard | Keyboard maintainer | Log-only; no threshold wired to a page |
| Traffic | No request-rate or session-count telemetry | Absent | — | None; not a product metric |
| Errors | `AppLog.error` (public); CI/`xcodebuild` non-zero; Sparkle disabled/start logs | Console (`subsystem` `one.ifelse.easykey`); the CI pipeline; xcresult artifacts (14 days) | Whoever owns the failing job or log category | CI: fail the check. Process: log-only |
| Saturation | No CPU/queue/disk SLO | Absent | — | None |

**Correlation.** Filter Console or `log` with subsystem `one.ifelse.easykey` and category (`app`, `engine`, `keyboard`, `synth`, `smartSwitch`, `settings`, `update`, `loginItem`, `translation`). Export from the app: last **60 minutes**, max **2000** entries, default categories **app / keyboard / settings** only, credentials redacted, file mode `0600`. Tie a merge failure to `xcresult-*` then merged `test-results`. Keyboard Health pill shows tap `active` vs permission/paused; it is not a distributed trace id.

**Blind spots.** No pager, no APM, no production analytics SDK. Default log export omits `engine`, `synth`, `update`, `loginItem`, `translation`. Keyboard debug (`EASYKEY_KEYBOARD_DEBUG`) is off unless you set it. Hosted-runner AX/window-key and TranslationSession SIGSEGV tests can fail while merge stays green. Coverage can still ingest that shard’s bundle when it produces results; LoginHelper is excluded from the percentage. No tracing from Sparkle download to a user machine. In-process diagnostics never leave the Mac.

## Distribution

**Channels in use.** (1) Internal/ad-hoc DMG — operator `make local-dmg`, used for local smoke builds only. (2) Direct download — the release archive host DMGs. (3) In-app Sparkle — the appcast host `appcast.xml` after a **published** (not draft) release. No App Store or TestFlight channel is evidenced. Authorized roles: a repo actor who can push `v*` tags and publish a release; the CI pipeline (`contents: write`) imports the Developer ID certificate, signs and notarizes each DMG, creates the draft, signs Sparkle enclosures with `SPARKLE_PRIVATE_ED_KEY`, and the CI bot commits the appcast. The Apple material itself lives in GitHub secrets, staged with `make update-secrets` by whoever holds the Developer ID identity and the notarization credentials. Never put key material in docs.

**Secrets staging (`make update-secrets`).** Names are auto-detected from `.github/workflows`, so a workflow rename is picked up automatically. `make update-secrets --list` audits the expected names without writing anything; `make update-secrets` prompts for each (empty input keeps the existing value). The Developer ID `.p12` is **exported from the login keychain** with `security export` (overridable with `KEYCHAIN=`) and never pasted; the Sparkle keypair is **read** from the keychain and only regenerated under `--rotate-sparkle`, because installed apps trust the public key already shipped to them. Local copies land under `$EASYKEY_SECRET_DIR` (default `/Volumes/WS/Secret/easykey`) with mode 600. Expected inventory: `APPLE_SIGN_P12_BASE64`, `APPLE_SIGN_P12_PASSWORD`, `APPLE_TEAM_ID`, `APPLE_ID`, `APPLE_APP_SPECIFIC_PASSWORD`, `SPARKLE_PRIVATE_ED_KEY`, `SPARKLE_PUBLIC_ED_KEY` (secrets); `SPARKLE_FEED_URL`, `EASYKEY_SUPPORT_URL`, `EASYKEY_PRIVACY_POLICY_URL` (variables). Rotation is a re-run plus the new value typed at its prompt.

**Ad-hoc / CI DMG.** Build: `make local-dmg` with HTTPS Sparkle feed URL, public EdDSA key, support URL, privacy URL. Sign: ad-hoc (`CODE_SIGN_IDENTITY=-`). Package: `create-dmg` → `build/EasyKey-<version>-universal.dmg` (arch matrix may rename). Publish: CI uploads workflow artifacts only until `gh release create --draft`. Verify: tag matches short version; `verify-release` in `RELEASE_LOCAL=1` skips Developer ID/`spctl`/stapler. Update: cut a new tag. Rollback: do not publish the draft. This channel is for local iteration — it is not what ships to users.

**the release archive host (direct download).** Build/package: same Release workflow DMGs (universal is what Sparkle consumes). Sign: Developer ID with hardened runtime, notarized and stapled on CI via `make dmg`; `verify-release` asserts the signature, the runtime flag, `spctl` and the stapled ticket. Publish: convert the draft to a public release (human). Verify: `gh release download` yields exactly one `EasyKey-*-universal.dmg` for appcast. Update: publish a newer tag. Rollback: keep the previous public DMG; do not point the appcast at the bad tag (or revert the appcast commit).

**Sparkle (installed apps).** Build: reuse the published universal DMG. Sign: download Sparkle **2.9.4** tarball, verify pinned SHA-256, `sign_update` with the private EdDSA key; pin check script greps the workflow for `expected_sha256` and `shasum`. Package: enclosure URL `the project repository URL Publish: `generate-appcast.py` updates `gh-pages/appcast.xml` (HTTPS URL, positive length, unique build, no DOCTYPE) then `git push`. Verify: tag matches mounted app short version; feed URL in the bundle is HTTPS. Update: next published release rewrites the appcast. Rollback: revert the `gh-pages` appcast commit so clients keep the previous enclosure. Sparkle is suppressed in tests so it cannot throw a blocking “Update failed” sheet.

## Runbook index

No folded runbook section is in this file, so **no procedure is written below**. Rows are named from CI and publish evidence only. Register-only means: you can see the trigger; you must not treat this table as verified diagnosis steps.

| Runbook | Recovers | Trigger | Status |
|---|---|---|---|
| Hosted-runner AX / window activation | Correct interpretation of merge (not GUI trust) | Onboarding grant/click-through, sidebar, licenses sheet, preview/macro typing tests on `ui-known-broken-on-hosted-runner` | register only |
| TranslationSession on hosted runner | Test-process stability vs merge | `testAppleTranslationSessionBridge_*` SIGSEGV (no system translation daemon) | register only |
| Coverage gate | Merge when line coverage (excl. LoginHelper) is below 90% | `coverage` job / `make coverage` / `make coverage-gate` | register only |
| Sparkle appcast publish | Clients seeing a resolvable signed enclosure | `release` type `released`; missing/extra universal DMG; tag/version mismatch | register only |
| Missing signing secrets on a tag | Release job failure before any artifact is uploaded | Import step prints `APPLE_SIGN_P12_BASE64 is not set; run 'make update-secrets' first` | register only |
| Gatekeeper blocks a DMG | Locating which channel produced the artifact | Tag build whose `verify-release` did not run, or a pre-notarization download | register only |

A register-only row is not an on-call playbook. Re-run the blocking CI jobs, inspect xcresult artifacts, run the skipped tests on a logged-in Mac, and keep drafts unpublished until the universal DMG and appcast checks pass.

> **Related:** [Architecture](architecture.md) (blocks and Sparkle in context), [Documentation](README.md) (section map).
