# Testing guide

_Last reviewed: 2026-08-03_

Tests are organized by layer and live in two bundles: `EasyKeyTests` (unit and
integration) and `EasyKeyUITests` (end-to-end). The full suite is serial by
default; `make test-parallel` runs the local shard set (`unit`, `ui-1`, `ui-2`,
`ui-3`) serially on one Mac — the Makefile's coarse, deliberately
non-parallel grouping that bounds test time and isolates failures — while CI
runs finer shards on separate runners: four unit shards and five UI shards,
plus a non-blocking known-broken shard.

## Unit

```bash
make test
```

Runs the entire suite, including the unit tests. To run only the unit bundle,
use the filter the Makefile applies to its `unit` shard:

```bash
xcodebuild -project EasyKey.xcodeproj -scheme EasyKeyApp \
  -destination "platform=macOS" -enableCodeCoverage YES \
  -only-testing:EasyKeyTests test
```

**Covers:** typing rules (Telex, VNI, Simple Telex), tone placement, encodings,
converter, settings stores, macros, smart switch, clipboard model, translation
providers, app coordination, and architecture fitness. **Does not cover:** real
system keyboard events and real app windows. **Isolation:** in-process; no
network, no event tap; provider HTTP is faked.

**Fixtures:** black-box conformance data in `Fixtures/sample-telex.json`
consumed by `ConformanceFixtureTests`, plus in-bundle test support types
(`TestSupport.swift`, `VietnameseEngineTestSupport.swift`, `*TestSupport.swift`
per translation provider). **Reset:** per test case; shared `UserDefaults` data
is wiped with `make clean-local`. **Data:** synthetic.

## Integration

```bash
make test
```

Integration tests share the `EasyKeyTests` bundle, so they run with the same
command and `-only-testing:EasyKeyTests` filter as unit tests. The dedicated
integration host is `EasyKeyTests/KeyboardServiceIntegrationTests.swift`; the
QA artifact check requires it to exist.

**Covers:** `KeyboardService` boundaries — input pipeline switching, language
toggle, settings updates, pause isolation, latency and state behavior — plus
app coordinator wiring and clipboard monitoring. **Does not cover:** real
window activation and menu interaction. **Isolation:** real service objects
constructed in-process with injected observers; no real `CGEvent` tap.

**Fixtures:** in-bundle test support types. **Reset:** per test case; no
persistent state. **Data:** synthetic. **Shared dependency owner:** none —
integration tests do not share state across processes.

## End-to-end

```bash
make test
```

UI tests launch the real app with `XCUIApplication` on the host desktop.
`make test-parallel` runs the shard set (`unit`, `ui-1`, `ui-2`, `ui-3`)
serially with per-test timeouts (600 s) so a hung test fails its shard
instead of stalling the run; CI's finer matrix (four unit shards and five UI
shards, plus a non-blocking known-broken shard) runs each shard on its own
runner.

**Covers:** settings interaction, navigation, workflow (onboarding through
settings), accessibility, and clipboard-panel behavior via the
`EasyKeyUITests` classes (`SettingsWorkflowTests`,
`SettingsCoverageTests`, `OnboardingCoverageTests`, and friends). **Does not
cover:** cross-device behavior. **Isolation:** real app process and real
windows; every UI shard launches the same `EasyKey.app` bundle.

**Fixtures:** `XCUITestHelpers.swift` for launch and interaction
(`clickWhenHittable`, `ensureKeyWindow`, scroll-into-view `reveal`); no
seeded data. **Reset:** `make clean-local` clears the app and UI-test
containers between runs. **Data:** synthetic. **Shared dependency owner:** the
single Mac's app bundle — `EasyKeyTests` is app-hosted (`TEST_HOST =
EasyKey.app`), and one shard's `app.launch()`/`terminate()` kills another
shard's app instances mid-test ("Lost connection to the application"
failures, infinite hangs), so the Makefile runs local shards serially; use
`make test` for the reliable serial run.

## Coverage gate

```bash
make coverage
```

Runs the suite, then enforces the line-coverage threshold on the newest
result bundle. `make coverage-parallel` does the same over merged shard
bundles. The threshold defaults to 90 and is configurable with
`COVERAGE_THRESHOLD`; CI sets the same value.

Expected output:

```text
Line coverage (excl. LoginHelper): 91.23%   (example value — varies per run)
Coverage gate passed (>= 90%).
```

`Scripts/check-coverage.sh` computes coverage from `xcrun xccov view` and
excludes the `EasyKeyLoginHelper.app` target. A failed gate exits non-zero
with `Coverage gate failed: <value>% < 90%`.

## Diagnosing failures

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
