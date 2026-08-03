---
id: "testing_guide"
title: "Testing Guide"
docforge_provenance:
  schema: "2.0"
  doc_id: "testing_guide"
  path: "docs/engineering/testing.md"
  generated_at: "2026-08-03T08:44:07Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "deep-dive"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "unit"
      sources:
        - path: "Makefile"
          git_blob: "b8fa0059c061eef05cb083ae69e8e7d46336aa64"
          role: "config"
        - path: "EasyKeyTests/ConformanceFixtureTests.swift"
          git_blob: "86b87fdcec1e9b90c339592597c8565e9b36b63e"
          role: "test"
        - path: "Fixtures/sample-telex.json"
          git_blob: "a904b2094b8299dee38b8667525a24a75e759017"
          role: "test"
      unresolved: []
    - id: "integration"
      sources:
        - path: "EasyKeyTests/KeyboardServiceIntegrationTests.swift"
          git_blob: "f9fc2b7a29d5360099851ebc6454f799486620c6"
          role: "test"
        - path: "EasyKeyTests/TestSupport.swift"
          git_blob: "150530232d14abbfb2ab947a16ff99de0c321bf7"
          role: "test"
        - path: "Scripts/verify-qa-artifacts.sh"
          git_blob: "11ce62a91f372b4527c134c17645b8c7b655f51b"
          role: "code"
      unresolved: []
    - id: "end-to-end"
      sources:
        - path: "EasyKeyUITests/SettingsWorkflowTests.swift"
          git_blob: "b166dfbec3b9cd289fab739de3d01855c1d4db42"
          role: "test"
        - path: "EasyKeyUITests/XCUITestHelpers.swift"
          git_blob: "927d11506575a7f1c678d6128e1335ec3ad6dd27"
          role: "test"
        - path: "Makefile"
          git_blob: "b8fa0059c061eef05cb083ae69e8e7d46336aa64"
          role: "config"
      unresolved: []
    - id: "coverage-gate"
      sources:
        - path: "Scripts/check-coverage.sh"
          git_blob: "062819eb35129c6a6cd891d330643dee7a45db1a"
          role: "code"
        - path: "Makefile"
          git_blob: "b8fa0059c061eef05cb083ae69e8e7d46336aa64"
          role: "config"
      unresolved: []
    - id: "diagnosing-failures"
      sources:
        - path: "Makefile"
          git_blob: "b8fa0059c061eef05cb083ae69e8e7d46336aa64"
          role: "config"
        - path: "Scripts/check-coverage.sh"
          git_blob: "062819eb35129c6a6cd891d330643dee7a45db1a"
          role: "code"
        - path: "Scripts/clean-local.sh"
          git_blob: "51ee51c9ae3eb4397ea4ad56bf3a10565a3c0674"
          role: "code"
      unresolved: []
---
# Testing guide

_Last reviewed: 2026-08-03_

Tests are organized by layer and live in two bundles: `EasyKeyTests` (unit and
integration) and `EasyKeyUITests` (end-to-end). The full suite is serial by
default; the same shards CI uses are available locally.

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
Faster sharded variants are `make test-parallel` (unit plus `ui-1`, `ui-2`,
`ui-3` shards) and the CI matrix with additional UI shards.

**Covers:** settings interaction, navigation, workflow (onboarding through
settings), accessibility, and clipboard-panel behavior via the
`EasyKeyUITests` classes (`SettingsWorkflowTests`,
`SettingsCoverageTests`, `OnboardingCoverageTests`, and friends). **Does not
cover:** cross-device behavior. **Isolation:** real app process and real
windows; the app and UI tests share one `UserDefaults` domain.

**Fixtures:** `XCUITestHelpers.swift` for launch and interaction; no seeded
data. **Reset:** `make clean-local` clears the app and UI-test containers
between runs. **Data:** synthetic. **Shared dependency owner:** the single
Mac's `UserDefaults` domain — the Makefile documents that parallel UI shards
can therefore flake; use `make test` for a reliable serial run.

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
Line coverage (excl. LoginHelper): 91.23%
Coverage gate passed (>= 90%).
```

`Scripts/check-coverage.sh` computes coverage from `xcrun xccov view` and
excludes the `EasyKeyLoginHelper.app` target. A failed gate exits non-zero
with `Coverage gate failed: <value>% < 90%`.

## Diagnosing failures

| Symptom | Usually means | First check |
|---|---|---|
| A unit test fails after an engine change | The change altered expected behavior, or a conformance fixture encodes the old behavior | Run the single test with `-only-testing:EasyKeyTests/<TestClass>` and inspect the matching entry in `Fixtures/sample-telex.json` |
| UI tests flake under `make test-parallel` | Shared `UserDefaults` domain contention between shards on one Mac | Rerun serially with `make test` |
| UI test fails only in CI, passes locally | Hosted runners cannot reliably make an AppKit window key; the `ui-known-broken-on-hosted-runner` shard is exempted from merge (continue-on-error) | Treat the local pass as authoritative; move those tests to a runner with a real logged-in GUI session if they must gate |
| `Coverage gate failed` | Changed code lacks tests | Open the merged `.xcresult` in Xcode and inspect uncovered lines |
| `Result bundle not found` from the coverage gate | No `.xcresult` was produced by a previous run | Run `make test` once before `make coverage` |
| Test bundle fails to build locally | SPM dependency resolution issue | `make clean` then `make test`; CI resolves packages with `-resolvePackageDependencies` first |
