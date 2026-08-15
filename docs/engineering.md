# Engineering

_Last reviewed: 2026-08-15_

This file is the working guide for anyone building or testing EasyKey: how to set up a development environment and how the test suites are organized. Engineers new to the project should start here. The repository's enforced conventions live in the hand-written engineering rulebook (notes/rulebook.md), referenced rather than restated here.

## At a glance

The engineering workflow runs from a Makefile-driven toolchain: local setup builds the project with Xcode and runs its test bundles, and CI enforces lint, tests, and a coverage gate. Packaging and distribution of the released artifact are covered by the operations section. Two documents own the engineering steps — setup and testing; publishing of the in-repo framework artifacts is documented in [publishing.md](engineering/publishing.md).

## Scope and boundaries

This section owns the *process* of working on the repository: local setup, test organization, and what publishing exists for the in-repo frameworks. It does not own why the architecture looks the way it does ([architecture](architecture.md)) or the operational channels that carry the released artifact ([operations](operations/README.md)). The engineering rulebook (notes/rulebook.md) is a hand-written document — canonical for conventions, not generated, and referenced from here rather than restated.

## Setup

This path builds EasyKey from source and runs its test suite. A first build compiles the entire project and takes longer than later incremental builds.

### Prerequisites

| Requirement | Version | Notes |
|---|---|---|
| macOS | 14.0 (Sonoma) or later | stated in the README Requirements section |
| Xcode | 15 or later | includes the Swift toolchain; the project compiles in Swift 5 language mode |
| Git and command-line tools | any recent | needed for cloning and helper commands |
| SwiftLint, SwiftFormat | optional | `brew install swiftlint swiftformat`; `make lint` and `make format` skip them when absent |
| Accessibility permission | runtime only | granted at first launch; System Settings → Privacy & Security → Accessibility |

Access you will need, and who grants it: none for building, testing, and running locally. A local DMG (`make local-dmg`) additionally requires four non-secret environment variables — `SPARKLE_FEED_URL`, `SPARKLE_PUBLIC_ED_KEY`, `EASYKEY_SUPPORT_URL`, `EASYKEY_PRIVACY_POLICY_URL` — because the release configuration is baked into the build (`Scripts/archive.sh` enforces HTTPS). Signed distribution adds Apple Developer credentials (Developer ID Application certificate, team identifier, notarization profile) — Apple Developer Program, held by the repository owner; see the signing status in [distribution](operations/distribution.md).

### Steps

1. Clone the repository and enter it. The repository is public; the release badge at the top of the root README links to the public release page.

   ```bash
   git clone <REPOSITORY_URL>
   cd EasyKey
   ```

   Verify: the `EasyKey` directory contains `EasyKey.xcodeproj`, `Makefile`, and the `EasyEngineCore/`, `EasyKeyKit/`, `EasyKeyApp/` source directories.

2. Build the debug app:

   ```bash
   make build
   ```

   Verify: Xcode prints `** BUILD SUCCEEDED **`, and `build/Build/Products/Debug/EasyKey.app` exists.

3. Optional: install the style tools so the lint and format targets enforce the repository's style instead of skipping:

   ```bash
   brew install swiftlint swiftformat
   ```

4. Run the full test suite (unit and UI, serial, with code coverage):

   ```bash
   make test
   ```

   Verify: Xcode prints `** TEST SUCCEEDED **`.

5. Launch EasyKey:

   ```bash
   make run
   ```

   Verify: a menu-bar icon appears. Grant Accessibility when prompted — typing transformation stays unavailable until the permission is granted (System Settings → Privacy & Security → Accessibility).

6. Smoke-test the engine: type `vieejt nam` in any text field. Verify: it transforms to `việt nam`.

7. Optional: package a local universal DMG when you have the four release configuration variables from the prerequisites:

   ```bash
   export SPARKLE_FEED_URL=<feed-url>
   export SPARKLE_PUBLIC_ED_KEY=<ed25519-public-key>
   export EASYKEY_SUPPORT_URL=<support-url>
   export EASYKEY_PRIVACY_POLICY_URL=<privacy-url>
   make local-dmg
   ```

   Verify: `DMG created: build/EasyKey-<version>-universal.dmg`. This is an ad-hoc signed build without notarization.

### Verify

```bash
make qa
```

Expected output:

```text
Phase 8 automated QA gate passed.
```

`make qa` runs the full test suite, then `Scripts/verify-qa-artifacts.sh` checks that the fixture-driven engine conformance test, the keyboard-service integration test host, the settings workflow UI tests, and the fixture data under `Fixtures/` are all present, and `Scripts/check-test-registration.sh` fails when a tracked test file is missing from its Xcode target.

### Common problems

**xcodebuild reports it cannot find a destination** — the Xcode toolchain is not selected or command-line tools are missing. Open Xcode once to finish its first-run setup, then rerun `make build`.

**Typing transformation does nothing after launch** — Accessibility permission is missing or was revoked. Grant it in System Settings → Privacy & Security → Accessibility and relaunch EasyKey.

**`make lint` prints "SwiftLint not installed. Install with: brew install swiftlint"** — this is the skip behavior, not an error; the target still exits successfully. Run `brew install swiftlint` to enable the check.

**UI tests fail under `make test-parallel` ("Lost connection to the application")** — every UI shard launches the same `EasyKey.app` bundle, so one shard's `app.launch()`/`terminate()` can kill another shard's app mid-test; the unit shard is app-hosted and dies the same way. The Makefile runs local shards serially by design, so fall back to `make test` for the reliable serial run.

**`make local-dmg` fails with "SPARKLE_PUBLIC_ED_KEY environment variable is not set"** — the Makefile's release-config check catches a missing `SPARKLE_PUBLIC_ED_KEY` first, and `Scripts/archive.sh` then requires all four variables (with HTTPS enforcement); export them as in step 7.

**Odd behavior persists across runs (stale preferences, leftovers)** — wipe build artifacts, Xcode DerivedData, and local app and test data with `make clean-all` (`clean` + `clean-local` + `clean-derived`). The local cleanup quits EasyKey and removes preferences, containers, caches, and saved state.

## Testing

Tests are organized by layer and live in two bundles: `EasyKeyTests` (unit and integration) and `EasyKeyUITests` (end-to-end). The full suite is serial by default; `make test-parallel` runs the local shard set (`unit`, `ui-1`, `ui-2`, `ui-3`) serially on one Mac — the Makefile's coarse, deliberately non-parallel grouping that bounds test time and isolates failures — while CI runs finer shards on separate runners: four unit shards and five UI shards, plus a non-blocking known-broken shard.

### Unit

```bash
make test
```

Runs the entire suite, including the unit tests. To run only the unit bundle, use the filter the Makefile applies to its `unit` shard:

```bash
xcodebuild -project EasyKey.xcodeproj -scheme EasyKeyApp \
  -destination "platform=macOS" -enableCodeCoverage YES \
  -only-testing:EasyKeyTests test
```

**Covers:** typing rules (Telex, VNI, Simple Telex), tone placement, encodings, converter, settings stores, macros, smart switch, clipboard model, translation providers, app coordination, and architecture fitness. **Does not cover:** real system keyboard events and real app windows. **Isolation:** in-process; no network, no event tap; provider HTTP is faked.

**Fixtures:** black-box conformance data in `Fixtures/sample-telex.json` consumed by `ConformanceFixtureTests`, plus in-bundle test support types (`TestSupport.swift`, `VietnameseEngineTestSupport.swift`, `*TestSupport.swift` per translation provider). **Reset:** per test case; shared `UserDefaults` data is wiped with `make clean-local`. **Data:** synthetic.

### Integration

```bash
make test
```

Integration tests share the `EasyKeyTests` bundle, so they run with the same command and `-only-testing:EasyKeyTests` filter as unit tests. The dedicated integration host is `EasyKeyTests/KeyboardServiceIntegrationTests.swift`; the QA artifact check requires it to exist.

**Covers:** `KeyboardService` boundaries — input pipeline switching, language toggle, settings updates, pause isolation, latency and state behavior — plus app coordinator wiring and clipboard monitoring. **Does not cover:** real window activation and menu interaction. **Isolation:** real service objects constructed in-process with injected observers; no real `CGEvent` tap.

**Fixtures:** in-bundle test support types. **Reset:** per test case; no persistent state. **Data:** synthetic. **Shared dependency owner:** none — integration tests do not share state across processes.

### End-to-end

```bash
make test
```

UI tests launch the real app with `XCUIApplication` on the host desktop. `make test-parallel` runs the shard set (`unit`, `ui-1`, `ui-2`, `ui-3`) serially with per-test timeouts (600 s) so a hung test fails its shard instead of stalling the run; CI's finer matrix (four unit shards and five UI shards, plus a non-blocking known-broken shard) runs each shard on its own runner.

**Covers:** settings interaction, navigation, workflow (onboarding through settings), accessibility, and clipboard-panel behavior via the `EasyKeyUITests` classes (`SettingsWorkflowTests`, `SettingsCoverageTests`, `OnboardingCoverageTests`, and friends). **Does not cover:** cross-device behavior. **Isolation:** real app process and real windows; every UI shard launches the same `EasyKey.app` bundle.

**Fixtures:** `XCUITestHelpers.swift` for launch and interaction (`clickWhenHittable`, `ensureKeyWindow`, scroll-into-view `reveal`); no seeded data. **Reset:** `make clean-local` clears the app and UI-test containers between runs. **Data:** synthetic. **Shared dependency owner:** the single Mac's app bundle — `EasyKeyTests` is app-hosted (`TEST_HOST = EasyKey.app`), and one shard's `app.launch()`/`terminate()` kills another shard's app instances mid-test ("Lost connection to the application" failures, infinite hangs), so the Makefile runs local shards serially; use `make test` for the reliable serial run.

### Coverage gate

```bash
make coverage
```

Runs the suite, then enforces the line-coverage threshold on the newest result bundle. `make coverage-parallel` does the same over merged shard bundles. The threshold defaults to 90 and is configurable with `COVERAGE_THRESHOLD`; CI sets the same value.

Expected output:

```text
Line coverage (excl. LoginHelper): 91.23%   (example value — varies per run)
Coverage gate passed (>= 90%).
```

`Scripts/check-coverage.sh` computes coverage from `xcrun xccov view` and excludes the `EasyKeyLoginHelper.app` target. A failed gate exits non-zero with `Coverage gate failed: <value>% < 90%`.

### Diagnosing failures

| Symptom | Usually means | First check |
|---|---|---|
| A unit test fails after an engine change | The change altered expected behavior, or a conformance fixture encodes the old behavior | Run the single test with `-only-testing:EasyKeyTests/<TestClass>` and inspect the matching entry in `Fixtures/sample-telex.json` |
| "Lost connection to the application" under `make test-parallel` | Every UI shard launches the same `EasyKey.app` bundle and `EasyKeyTests` is app-hosted, so one shard's `app.launch()`/`terminate()` kills another shard's app instances; the Makefile runs local shards serially to avoid this | Run `make test` for the reliable serial run |
| A shard hangs instead of failing | A test blocked on a system dialog or other indefinite wait | Local and CI runs set per-test execution timeouts (600 s default, 600 s max) so a hung test fails the shard instead of stalling until the job timeout |
| UI test fails only in CI, passes locally | Hosted runners cannot reliably make an AppKit window key, and constructing a real `TranslationSession` crashes the test process (SIGSEGV) because the hosted runner has no system translation daemon; affected tests live in the `ui-known-broken-on-hosted-runner` shard, which never blocks the pipeline (continue-on-error, and exempt from the zero-executed-tests check), and are skipped via `-skip-testing` in the blocking shards | Treat the local pass as authoritative; move those tests to a runner with a real logged-in GUI session if they must gate |
| A CI shard is green but executed zero tests | The shard's `-only-testing` filter matched nothing, usually because a suite was dropped from the Xcode target | `Scripts/check-shard-tests.sh` fails any shard whose result bundle shows zero executed tests; `Scripts/check-test-registration.sh` catches the underlying target-registration gap before it ships |
| `Coverage gate failed` | Changed code lacks tests | Open the merged `.xcresult` in Xcode and inspect uncovered lines |
| `Result bundle not found` from the coverage gate | No `.xcresult` was produced by a previous run | Run `make test` once before `make coverage` |
| Test bundle fails to build locally | SPM dependency resolution issue | `make clean` then `make test`; CI resolves packages with `-resolvePackageDependencies` first |

## Related sections

- [Architecture](architecture.md) — the system design the engineering workflows build and test.
- [Operations](operations/README.md) — the distribution channels that carry the released artifact.
- [Reference](reference.md) — stack, compatibility, and configuration facts the workflows depend on.
