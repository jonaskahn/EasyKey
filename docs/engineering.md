# Engineering

_Last reviewed: 2026-08-27_

This file is the compact engineering section for people who clone EasyKey, change it, and ship a DMG. It answers how you get a running checkout, how you run tests, how you cut a version, and how the the release archive plus Sparkle appcast actually get published. Product behavior lives in [product.md](product.md); deployable structure lives in [architecture.md](architecture.md); CI versus operator notarization environments live in [operations.md](operations.md).

## At a glance

Clone the repo, Debug-build EasyKey.app with Xcode via Make, then run the serial test suite before you change anything. CI on `main` and pull requests lint, build Core and Kit alone, shard tests on `macos-15`, and enforce 90% line coverage excluding the login helper. Shipping a user-visible version is SemVer in the Xcode marketing version, a `v*` tag that must match that version, CI `make local-dmg` (unsigned), a draft the release archive, then Sparkle 2.9.4 appcast publish when the release goes public. Notarized Developer ID output is a separate operator path: `make dmg`.

Reading paths: [Setup](#setup) for a working app; [Testing](#testing) when checks are red; [Release](#release) to cut a version; [Publishing](#publishing) for DMG identity, Sparkle signing, and rollback of a bad artifact. [contributing.md](contributing.md) owns who reviews; [operations.md](operations.md) owns where CI runners and operator machines differ.

## Scope and boundaries

This file owns the verified contributor path: prerequisites to a launched Debug app, test layers and failure diagnosis, the release procedure, and publish mechanics for EasyKey DMGs and the Sparkle feed. Adjacent sections own the rest: [architecture.md](architecture.md) (blocks and import direction), [operations.md](operations.md) (environments and rollout), [security.md](security.md) (TCC, Keychain, update trust), [reference.md](reference.md) (settings and stack lookup), [product.md](product.md) (who it is for), [flows.md](flows.md) (runtime sequences), [contributing.md](contributing.md) (ownership). The compact tree has no extra files under an engineering folder.

| Section | Answers |
|---|---|
| [Setup](#setup) | How do I get a working local checkout running, step by step? |
| [Testing](#testing) | How do I run tests, and what does a flaky-looking failure usually mean? |
| [Release](#release) | How do I cut a release, and what do I do if it needs to be rolled back? |
| [Publishing](#publishing) | How does a DMG get published, and how do I roll it back if it is bad? |

## Setup

**Prerequisites:** macOS 14.0 or later (Apple silicon or Intel), Xcode 15 or later with command-line tools (CI uses `macos-15` and `latest-stable` Xcode), Git. SwiftLint and SwiftFormat are optional on your Mac; CI installs them with Homebrew. You do not need Sparkle keys, Developer ID, or notarization secrets to Debug-build and run.

1. Clone this repository and `cd` to the checkout root — verify: `EasyKey.xcodeproj` is present next to `Makefile`.
2. Run `make build` — verify: xcodebuild exits 0 and `build/Build/Products/Debug/EasyKey.app` exists (`PROJECT=EasyKey.xcodeproj`, `SCHEME=EasyKeyApp`, `DESTINATION=platform=macOS`, Debug).
3. Run `make run` — verify: macOS opens that Debug app (menu-bar accessory). Grant Accessibility when the app asks; typing in other apps will not work until that is on.

**Configuration:** none for a Debug run. Sparkle feed URL, EdDSA public key, support URL, and privacy-policy URL are required only for `make local-dmg` / `make dmg` (HTTPS). Do not put secret values in the project; name the environment variables only (`SPARKLE_FEED_URL`, `SPARKLE_PUBLIC_ED_KEY`, `EASYKEY_SUPPORT_URL`, `EASYKEY_PRIVACY_POLICY_URL`).

**Symptom → recovery**

- `xcodebuild` cannot find the scheme or SDK — confirm you are at the repo root and Xcode’s active developer directory is set; the Make variables above are the only project/scheme/destination the Makefile passes.
- `make lint` prints `SwiftLint not installed. Install with: brew install swiftlint` (same pattern for SwiftFormat) — install those tools, or skip locally; the CI `lint` job still runs `swiftformat --lint .` and `swiftlint lint` and will fail the PR.
- Stale GUI DerivedData vs Make’s `build/` — run `make clean` (xcodebuild clean + remove `build/`). If Xcode GUI leftovers remain, run `make clean-derived`. To also quit EasyKey and wipe local prefs/test data, run `make clean-local` or `make clean-all`.

**Closing verification:** run `make help` — grouped targets print, including Development, Clean, Quality, and both Release groups. **What next:** run the suite in [Testing](#testing). Settings and stack semantics are owned by [reference.md](reference.md), not this path.

## Testing

Fastest layer first. Local default is serial `make test` (unit + UI, code coverage on). Do not run UI shards concurrently on one Mac: every shard launches the same EasyKey.app, so a second `app.launch()` kills the first (`Lost connection to the application`). CI splits EasyKeyTests across four runners and UI across five plus a known-broken shard; locally `make test-parallel` still runs shards **serially** (`-j1`) after `make build-for-testing`.

**Unsupported environments:** Linux/Windows; treating hosted macOS CI as a real logged-in GUI (window-keying and live `TranslationSession` tests are `continue-on-error` on shard `ui-known-broken-on-hosted-runner` and never block merge). Those cases need a self-hosted GUI runner to count.

| Layer | Run | Covers | Deliberately does not | Isolation |
|---|---|---|---|---|
| Unit / integration (`EasyKeyTests`) | `make test` (full) or after `make build-for-testing` the `unit` shard via Make’s `FILTER_unit=-only-testing:EasyKeyTests` | Engine, settings, providers, host wiring, `ArchitectureFitnessTests` (App → Kit → Core; Core stays Foundation-only) | Real Settings window keying; login-helper lines in the coverage numerator | App-hosted (`TEST_HOST` is EasyKey.app); in-process XCTest; no container database |
| UI (`EasyKeyUITests`) | included in `make test`; local shards `ui-1`…`ui-3` use only the `-only-testing:` filters in the Makefile | Settings coverage/interaction/navigation/workflow, onboarding, accessibility, `EasyKeyUITests` | Hosted-runner click-then-verify cases moved to the known-broken shard in CI | Launches EasyKey.app; one app instance per Mac |
| Coverage gate | `make coverage` (serial test, then gate) or `make coverage-parallel` / `make test-parallel` (merge shards) | Line coverage ≥ `COVERAGE_THRESHOLD` (default 90) | `EasyKeyLoginHelper.app` target lines (excluded in the coverage script) | Reads `.xcresult`; merge uses `xcrun xcresulttool merge` when `MERGE=1` |
| QA gate | `make qa` | `xcodebuild test` plus QA artifact and test-target registration checks | Notarization / Developer ID | Same derived-data `build/` as Make |

**Per-shard timeouts (local shards and CI `xcodebuild test`):** `-test-timeouts-enabled YES`, `-default-test-execution-time-allowance 600`, `-maximum-test-execution-time-allowance 600`. CI does not pass `-retry-tests-on-failure`. CI also fails a blocking shard that executed zero tests.

**Observable pass:** `make test` — xcodebuild test succeeds. `make coverage` — prints `Line coverage (excl. LoginHelper): …` then `Coverage gate passed (>= 90%).` `make qa` — prints `Phase 8 automated QA gate passed.` CI `structure` job — standalone `xcodebuild` Debug builds of targets `EasyEngineCore` and `EasyKeyKit` succeed; test files missing from an Xcode target fail registration.

**Symptom → first check**

- `Lost connection to the application` or hangs during `test-parallel` — you overlapped UI/unit shards on one Mac; run `make test` or keep shards serial.
- `Coverage gate failed: …% < 90%` — inspect the merged or latest `.xcresult`; helper coverage is excluded on purpose.
- Architecture fitness red — Core imported AppKit/SwiftUI/Combine/UIKit or App/Kit, or Kit imported the app module; fix imports, do not skip the test.
- CI UI / Apple Translation SIGSEGV or sheet tests that never key a window — confirm the case is on `ui-known-broken-on-hosted-runner` (non-blocking) rather than a blocking shard.
- Format/lint red on CI only — run `swiftformat --lint .` and `swiftlint lint` as CI does, or `make format` / `make lint` locally after installing the tools.

Release gates (tag, DMG, coverage job `needs: test`) are owned by [Release](#release).

## Release

**Version scheme:** Semantic Versioning as stated in the changelog (Keep a Changelog). User-facing version is `MARKETING_VERSION` / `CFBundleShortVersionString` (current **0.0.14**). Sparkle also records `CFBundleVersion` (`CURRENT_PROJECT_VERSION`; currently **13** — bump it when you ship a new binary even if marketing stays). **Major:** incompatible change to the public contract (the repo does not list extra major triggers). **Minor:** backward-compatible additions (changelog `Added`). **Patch:** backward-compatible fixes (changelog `Fixed`). Tags must be `v` plus the built short version (`v0.0.14`).

1. **Prerequisites:** change is on a branch CI will accept; `main` CI is green (lint, structure, test shards except known-broken, coverage 90%). Set HTTPS Sparkle public feed and public EdDSA key plus support/privacy URLs in the environment before any DMG target (`make dmg` and `make local-dmg` both run `release-config-check` and fail if `SPARKLE_PUBLIC_ED_KEY` is empty). Operator notarization additionally needs Developer ID identity and team (unsigned CI does not).
2. **Version bump:** set `MARKETING_VERSION` (and `CURRENT_PROJECT_VERSION` when the build number should move) in the Xcode project so every target’s Info.plist still uses `$(MARKETING_VERSION)` — verify: `PlistBuddy` on a built app prints the intended short version.
3. **Build (unsigned universal, no secrets):** `make release` — verify: Release configuration, `ONLY_ACTIVE_ARCH=NO`, `ARCHS="arm64 x86_64"`, xcodebuild succeeds. This is not the the release archive.
4. **Verification (contributor / CI):** `make coverage` and `make qa` — verify: coverage gate passed; QA gate passed. Maintainer owns merge to `main`. CI coverage job is the merge gate (`COVERAGE_THRESHOLD: "90"`).
5. **Publication (CI path, current workflows):** tag `v*` and push — verify: Release workflow runs `make local-dmg` with `SPARKLE_FEED_URL`, `SPARKLE_PUBLIC_ED_KEY`, `EASYKEY_SUPPORT_URL`, `EASYKEY_PRIVACY_POLICY_URL`, optional `ARCHS` / `REQUIRED_ARCHS` / `TARGET_NAME`; built short version equals the tag without the `v`; `gh release create` uploads `build/EasyKey-*.dmg` as a **draft** with generated notes. Publish the the release archive when the DMG is the one you want users to see — verify: release type `released` starts Publish Appcast.
6. **Publication (operator notarized path):** `make dmg` — verify: archive + export, `verify-arch`, `codesign --verify --deep --strict --verbose=2`, notarize and staple app, `create-dmg`, notarize and staple DMG, `verify-release` on app and DMG. CI does **not** run `make dmg` today (workflow TODO: re-enable Developer ID once the Apple cert is available).
7. **Rollback:** triggered by a bad draft or a bad published build (wrong version, failed arch, Gatekeeper failure, broken Sparkle enclosure). **Draft:** do not publish; delete or supersede the draft release — verify: no public tag assets, appcast unchanged. **Published:** do not yank by an evidenced registry command; ship the next SemVer (`patch` or `minor`) with a new tag so Sparkle sees a newer item — verify: new tag’s short version matches, new draft, then published appcast item. Changelog content stays in the changelog file, not here.

## Publishing

EasyEngineCore and EasyKeyKit are Xcode frameworks **embedded in EasyKey.app**. There is no package-registry publish for those frameworks. The distributed artifacts are disk images and the Sparkle appcast.

| Artifact | Format | Produced by |
|---|---|---|
| EasyKey.app (Debug) | app bundle | `make build` |
| EasyKey.app (Release archive/export) | app bundle | `make archive` then `make export`, or `RELEASE_LOCAL=1` via `make local-dmg` |
| `EasyKey-<version>-universal.dmg` | UDZO DMG (`hdiutil create -format UDZO`) | `Scripts/create-dmg.sh` (`make local-dmg` / `make dmg`) |
| Arch-specific DMG name on CI | same file renamed | Release workflow when `TARGET_NAME` is `arm64` or `amd64` |
| `appcast.xml` on `gh-pages` | Sparkle appcast | Publish Appcast after a public the release archive |

**Version source:** `CFBundleShortVersionString` inside the exported app’s Info.plist (from `MARKETING_VERSION`). DMG path is `build/EasyKey-${version}-universal.dmg` unless `DMG_PATH` is set. Tag `the tag name from the CI event` must equal `v` + that string.

**Build, sign, publish**

1. Build — `make local-dmg` (CI/unsigned) or `make dmg` (Developer ID + notarize) — verify: `build/export/EasyKey.app` exists; local path prints that it skips Developer ID `codesign`/`spctl`; notarized path runs deep codesign verify.
2. Sign (Sparkle EdDSA, not Apple notarization) — Publish Appcast runs Sparkle **2.9.4** `sign_update` with the private EdDSA key from the secret mechanism `SPARKLE_PRIVATE_ED_KEY` (never put the key in git) — verify: `sign_update` prints signatures for each `EasyKey-*.dmg`; tarball checksum is pinned in that workflow.
3. Publish channel — `gh release create` (draft) then human publish; appcast enclosure URL is `the project repository URL — verify: exactly one `EasyKey-*-universal.dmg` downloaded for appcast; tag still matches mounted app short version; `git push` on `gh-pages` commits `appcast.xml`.

**Required gate before users should install:** CI test + coverage on `main`; tag/version match; for notarized bits, `make verify-release` (arch, macOS 14 compatibility, codesign/spctl/stapler when not `RELEASE_LOCAL=1`, bundled LICENSE/NOTICE/THIRD_PARTY_NOTICES.md). `make verify-arch` and `make verify-compatibility` are the named Make wrappers (`verify-release` is `Scripts/verify-release.sh`). There is no `make verify` target.

**Consumer verify:** mount the universal DMG, read short version and `LSMinimumSystemVersion` with PlistBuddy as Publish Appcast does; on a notarized build, `xcrun stapler validate` on the DMG.

**Rollback / deprecate**

- **Unpublish:** not supported as a registry yank. Keep a bad build draft, or leave a published the release archive in place and ship a newer version. Appcast updates only on `release` event type `released`.
- **Deprecate:** no evidenced Sparkle “deprecated” flag in-repo; ship a newer enclosure so the feed points at a good DMG.
- **Patch forward:** bump marketing (and build) version, retag, repeat `make local-dmg` or `make dmg`, publish.

Released user-facing notes are owned by the changelog, not this section.
