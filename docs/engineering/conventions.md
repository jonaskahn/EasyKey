---
id: "conventions"
title: "Conventions"
description: "Evidenced style, structure, error, testing, and review conventions"
docforge_provenance:
  schema: "2.0"
  doc_id: "conventions"
  path: "docs/engineering/conventions.md"
  generated_at: "2026-08-13T11:07:59Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "deep-dive"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "style"
      sources:
        - path: "docs/engineering/rulebook.md"
          git_blob: "dba86c139b41f2fe59027bab1f0e9982fd8d0e00"
          role: "doc"
        - path: ".swiftlint.yml"
          git_blob: "90631d6319ce50e321f2e8f6936145b08d98d92f"
          role: "config"
        - path: ".swiftformat"
          git_blob: "ac27429273e1daa282d4a73177cebd2dae238705"
          role: "config"
      unresolved: []
    - id: "formatting-is-machine-enforced"
      sources:
        - path: ".swiftlint.yml"
          git_blob: "90631d6319ce50e321f2e8f6936145b08d98d92f"
          role: "config"
        - path: ".swiftformat"
          git_blob: "ac27429273e1daa282d4a73177cebd2dae238705"
          role: "config"
        - path: "Makefile"
          git_blob: "06aa63c4ea11d09c149d6fb44b499e07f014f117"
          role: "config"
      unresolved: []
    - id: "swift-5-language-mode"
      sources:
        - path: "docs/engineering/rulebook.md"
          git_blob: "dba86c139b41f2fe59027bab1f0e9982fd8d0e00"
          role: "doc"
        - path: ".swiftformat"
          git_blob: "ac27429273e1daa282d4a73177cebd2dae238705"
          role: "config"
      unresolved: []
    - id: "names-reveal-intent"
      sources:
        - path: "docs/engineering/rulebook.md"
          git_blob: "dba86c139b41f2fe59027bab1f0e9982fd8d0e00"
          role: "doc"
      unresolved: []
    - id: "comments-at-public-boundaries"
      sources:
        - path: "docs/engineering/rulebook.md"
          git_blob: "dba86c139b41f2fe59027bab1f0e9982fd8d0e00"
          role: "doc"
      unresolved: []
    - id: "structure"
      sources:
        - path: "docs/engineering/rulebook.md"
          git_blob: "dba86c139b41f2fe59027bab1f0e9982fd8d0e00"
          role: "doc"
        - path: "EasyKeyTests/ArchitectureFitnessTests.swift"
          git_blob: "90458622e4b810ad49b024feeaaabf5a42b777c2"
          role: "test"
      unresolved: []
    - id: "dependency-direction"
      sources:
        - path: "EasyKeyTests/ArchitectureFitnessTests.swift"
          git_blob: "90458622e4b810ad49b024feeaaabf5a42b777c2"
          role: "test"
        - path: "docs/engineering/rulebook.md"
          git_blob: "dba86c139b41f2fe59027bab1f0e9982fd8d0e00"
          role: "doc"
      unresolved: []
    - id: "types-stay-cohesive"
      sources:
        - path: "docs/engineering/rulebook.md"
          git_blob: "dba86c139b41f2fe59027bab1f0e9982fd8d0e00"
          role: "doc"
      unresolved: []
    - id: "explicit-dependency-injection"
      sources:
        - path: "docs/engineering/rulebook.md"
          git_blob: "dba86c139b41f2fe59027bab1f0e9982fd8d0e00"
          role: "doc"
      unresolved: []
    - id: "error-handling"
      sources:
        - path: "docs/engineering/rulebook.md"
          git_blob: "dba86c139b41f2fe59027bab1f0e9982fd8d0e00"
          role: "doc"
      unresolved: []
    - id: "no-force-unwraps-in-production"
      sources:
        - path: "docs/engineering/rulebook.md"
          git_blob: "dba86c139b41f2fe59027bab1f0e9982fd8d0e00"
          role: "doc"
        - path: ".swiftlint.yml"
          git_blob: "90631d6319ce50e321f2e8f6936145b08d98d92f"
          role: "config"
      unresolved: []
    - id: "model-expected-outcomes-in-return-types"
      sources:
        - path: "docs/engineering/rulebook.md"
          git_blob: "dba86c139b41f2fe59027bab1f0e9982fd8d0e00"
          role: "doc"
      unresolved: []
    - id: "sensitive-data-never-logged"
      sources:
        - path: "docs/engineering/rulebook.md"
          git_blob: "dba86c139b41f2fe59027bab1f0e9982fd8d0e00"
          role: "doc"
        - path: "EasyKeyTests/ArchitectureFitnessTests.swift"
          git_blob: "90458622e4b810ad49b024feeaaabf5a42b777c2"
          role: "test"
      unresolved: []
    - id: "testing"
      sources:
        - path: "docs/engineering/rulebook.md"
          git_blob: "dba86c139b41f2fe59027bab1f0e9982fd8d0e00"
          role: "doc"
        - path: "Makefile"
          git_blob: "06aa63c4ea11d09c149d6fb44b499e07f014f117"
          role: "config"
      unresolved: []
    - id: "90-coverage-gate"
      sources:
        - path: "Scripts/check-coverage.sh"
          git_blob: "062819eb35129c6a6cd891d330643dee7a45db1a"
          role: "code"
        - path: "Makefile"
          git_blob: "06aa63c4ea11d09c149d6fb44b499e07f014f117"
          role: "config"
      unresolved: []
    - id: "fixture-driven-engine-conformance"
      sources:
        - path: "Fixtures/sample-telex.json"
          git_blob: "a904b2094b8299dee38b8667525a24a75e759017"
          role: "test"
        - path: "EasyKeyTests/ConformanceFixtureTests.swift"
          git_blob: "86b87fdcec1e9b90c339592597c8565e9b36b63e"
          role: "test"
        - path: "Scripts/verify-qa-artifacts.sh"
          git_blob: "11ce62a91f372b4527c134c17645b8c7b655f51b"
          role: "code"
      unresolved: []
    - id: "architecture-rules-as-tests"
      sources:
        - path: "EasyKeyTests/ArchitectureFitnessTests.swift"
          git_blob: "90458622e4b810ad49b024feeaaabf5a42b777c2"
          role: "test"
        - path: "docs/engineering/rulebook.md"
          git_blob: "dba86c139b41f2fe59027bab1f0e9982fd8d0e00"
          role: "doc"
      unresolved: []
    - id: "flaky-tests-are-defects"
      sources:
        - path: "docs/engineering/rulebook.md"
          git_blob: "dba86c139b41f2fe59027bab1f0e9982fd8d0e00"
          role: "doc"
        - path: "Makefile"
          git_blob: "06aa63c4ea11d09c149d6fb44b499e07f014f117"
          role: "config"
      unresolved: []
    - id: "review"
      sources:
        - path: "docs/engineering/rulebook.md"
          git_blob: "dba86c139b41f2fe59027bab1f0e9982fd8d0e00"
          role: "doc"
        - path: "docs/engineering/release.md"
          git_blob: "91aa96ce7f0812ac8d64a6215138d53e485833a6"
          role: "doc"
      unresolved: []
    - id: "ci-gates-every-change"
      sources:
        - path: "Makefile"
          git_blob: "06aa63c4ea11d09c149d6fb44b499e07f014f117"
          role: "config"
      unresolved: []
    - id: "qa-gate-before-release-candidates"
      sources:
        - path: "docs/engineering/release.md"
          git_blob: "91aa96ce7f0812ac8d64a6215138d53e485833a6"
          role: "doc"
        - path: "Scripts/qa-gate.sh"
          git_blob: "148320feb241615087d1cda4ef51cac8706e78bf"
          role: "code"
      unresolved: []
---
# Conventions

_Last reviewed: 2026-08-03_

These conventions are the ones the repository actually enforces or documents;
each is grounded in a lint rule, a CI check, a script, or a named rule in
[rulebook.md](rulebook.md). The rulebook there is authoritative;
this page orders conventions by how often a contributor collides with them.

## Style

Mechanical style is automated first; naming and comment rules are reviewed.

### Formatting is machine-enforced

**Convention:** SwiftLint and SwiftFormat are authoritative for mechanical
style: four-space indentation, trailing commas, line length limits, and the
rest. Do not hand-format against them.

**Evidence:** `.swiftlint.yml` and `.swiftformat` configure both tools
(`--indent 4`, `--trailingcommas always`, `trailing_comma:
mandatory_comma`), the CI lint job runs `swiftformat --lint .` and
`swiftlint lint`, and `make lint` / `make format` wrap them locally.

```swift
let configuration = EngineConfiguration(
    inputMethod: .telex,
    outputEncoding: .unicode,
)
```

**If not followed:** the CI lint job fails; locally, `make lint` reports
violations and `make format` rewrites the file.

### Swift 5 language mode

**Convention:** the project compiles in Swift 5 language mode. Do not
introduce Swift 6-only syntax or semantics without an explicit migration.

**Evidence:** the rulebook states the language-mode requirement, and
`.swiftformat` pins `--swift-version 5.0` so all tooling parses the same mode.

**If not followed:** formatter and linter may parse the source differently
from the compiler; the change is rejected at review.

### Names reveal intent

**Convention:** verb phrases for mutating or effectful operations, noun
phrases for values, and Boolean names phrased as assertions (`isEnabled`,
`hasPermission`, `shouldRestoreInput`). Avoid technical placeholders such as
`manager`, `helper`, `data`, or `handler`.

**Evidence:** rulebook.md section 1.1 documents the naming rules with
before-and-after examples.

```swift
func startMonitoring()
var isMonitoring: Bool
```

**If not followed:** review rejection; names are a stated review criterion
(rulebook.md section 12). There is no automated check.

### Comments at public boundaries

**Convention:** write comments only at public boundaries — file summaries,
type documentation, and public or internal API docs. No comments inside
private implementations, no `MARK` sections, TODOs, commented-out code, or
redundant restatements.

**Evidence:** rulebook.md section 2 enumerates permitted and forbidden
comments and directs rationale to documentation or tests.

**If not followed:** review rejection; no automated check.

## Structure

Architecture rules are enforced by fitness tests where the compiler cannot
express them; cohesion and injection rules are review gates.

### Dependency direction

**Convention:** source dependencies point inward —
`EasyKeyApp → EasyKeyKit → EasyEngineCore`. EasyEngineCore must not import
AppKit, SwiftUI, Combine, or UIKit, and lower levels must not reference
application types. Dependency cycles are architecture defects.

**Evidence:** enforced by source-scanning fitness tests
(`EasyKeyTests/ArchitectureFitnessTests.swift`) that fail on forbidden
`import` lines, and documented in rulebook.md section 5.1.

**If not followed:** the unit test shard fails in CI, and `make test` fails
locally.

### Types stay cohesive

**Convention:** one primary reason to change per type; prefer structs and
enums for values and state machines; default classes to `final`; use
composition over inheritance; start with `private` access and widen only for
a concrete caller.

**Evidence:** rulebook.md section 1.3.

**If not followed:** review rejection; no automated check.

### Explicit dependency injection

**Convention:** prefer direct construction and initializer injection. Add a
protocol only at a genuine boundary (multiple implementations, test
substitution, platform isolation) and do not add dependency-injection
frameworks — ordinary Swift initialization is the norm.

**Evidence:** rulebook.md section 5.3 states both rules explicitly.

**If not followed:** review rejection; no automated check.

## Error handling

One rule is enforced by a fitness test; the rest are review gates.

### No force unwraps in production

**Convention:** never force unwrap or use `try!` in production code unless an
invariant makes failure impossible and nearby text explains that invariant.

**Evidence:** rulebook.md section 1.4 states the rule; `.swiftlint.yml` does
not enable the `force_unwrapping` rule, so enforcement is review-based.

**If not followed:** review rejection; the documented exception is an
explained invariant adjacent to the unwrap.

### Model expected outcomes in return types

**Convention:** use optionals for ordinary absence and typed errors for
recoverable failure; throw when callers can recover, retry, or add context.
Never swallow failures with empty `catch` blocks or indiscriminate `try?`.

**Evidence:** rulebook.md section 3.

**If not followed:** review rejection; no automated check.

### Sensitive data never logged

**Convention:** never log keystrokes, clipboard contents, secrets, tokens, or
private user data. Log only the metadata needed to diagnose failure.

**Evidence:** rulebook.md sections 3 and 10, plus a fitness test that
scans translation log calls for content, credential, and request-body
references (`testTranslationLogsDoNotReferenceContentCredentialsOrRequestBodies`
in `EasyKeyTests/ArchitectureFitnessTests.swift`).

**If not followed:** the fitness test fails in the unit shard.

## Testing

The coverage gate, fixture conformance, and fitness tests are automated;
flaky-test discipline is a review gate.

### 90% coverage gate

**Convention:** merged line coverage must stay at or above 90%, excluding the
login helper target.

**Evidence:** `Scripts/check-coverage.sh` computes coverage from the merged
result bundle and excludes `EasyKeyLoginHelper.app`; the Makefile defaults
`COVERAGE_THRESHOLD ?= 90` and CI sets the same value.

**If not followed:** `make coverage` and the CI coverage job fail.

### Fixture-driven engine conformance

**Convention:** engine behavior against black-box data lives in
`Fixtures/sample-telex.json` and is exercised by the conformance test —
synthetic fixtures are the engine's contract, not ad-hoc test inputs.

**Evidence:** `Fixtures/sample-telex.json` (keystroke-to-buffer cases),
`EasyKeyTests/ConformanceFixtureTests.swift` (runs every fixture through the
engine), and `Scripts/verify-qa-artifacts.sh`, which fails `make qa` when the
fixtures or the conformance test are missing.

**If not followed:** `make qa` fails.

### Architecture rules as tests

**Convention:** rules the compiler cannot express — forbidden imports,
dependency cycles, sensitive data reaching logs — are encoded as automated
fitness tests.

**Evidence:** `EasyKeyTests/ArchitectureFitnessTests.swift` and the matching
rule in rulebook.md section 9.

**If not followed:** the unit shard fails.

### Flaky tests are defects

**Convention:** flaky tests are fixed or quarantined with a tracked reason;
never normalize reruns as the solution. Retrying transient failures is
acceptable only as a CI mechanism, not as a resolution.

**Evidence:** rulebook.md section 9 states the rule; the Makefile documents
the shared-`UserDefaults` flake risk for parallel UI shards and prescribes
the serial `make test` fallback; CI keeps the known-broken hosted-runner UI
tests in a dedicated shard with an explicit reason and continue-on-error.

**If not followed:** review rejection; the quarantine route is the documented
known-broken shard pattern.

## Review

CI gates every change; the release QA gate is owned by the maintainer.

### CI gates every change

**Requirement:** every push and pull request against `main` must pass the CI
workflow: formatting and lint, the structure job (test-target registration
plus standalone `EasyEngineCore` and `EasyKeyKit` builds), all test shards,
and the 90% coverage gate.

**Enforced by:** the CI workflow (`ci.yml`); the lint job runs
`swiftformat --lint .` and `swiftlint lint`, the structure job runs
`Scripts/check-test-registration.sh` and builds each framework standalone,
the test job runs the sharded matrix and fails shards that executed zero
tests, and the coverage job merges result bundles and enforces the
threshold.

**Applies to:** every push and pull request to `main`.

**Exception route:** none documented for lint or coverage; the
`ui-known-broken-on-hosted-runner` shard is the only exemption, by design and
with a tracked reason — it never blocks merge.

### QA gate before release candidates

**Requirement:** run `make qa` — full tests plus artifact and provenance
checks — before packaging any release candidate.

**Enforced by:** the maintainer performing the release; the release guide
requires it before archive and distribution.

**Applies to:** every archive, export, and DMG step of a release.

**Exception route:** none documented.
