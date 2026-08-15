# Contributing

_Last reviewed: 2026-08-14_

This page is the shortest verified route from a fresh checkout to a merged change. Detailed setup, testing, convention, and ownership rules live in the documents this page links to — they are the owners of the specifics.

## Prerequisites

Xcode 15 or later, macOS 14.0 or later, and Git with command-line tools; SwiftLint and SwiftFormat are optional locally (`make lint` and `make format` skip them when absent). No credentials or special access are needed to build, test, and run locally. The full table — including what signed distribution needs — is in the [setup guide](docs/engineering/setup.md).

## The contribution path

1. **Set up the workspace** — clone, `make build`, then `make run` per the [setup guide](docs/engineering/setup.md). Verify with `make qa`.
2. **Make one focused change** — follow the change discipline and Definition of Done in the [engineering rulebook](notes/rulebook.md) (sections 12 and 13): keep each change reviewable, separate behavior changes from mechanical refactors, and update tests and documentation with the code they describe.
3. **Run the required checks** — `make build`, `make test`, `make coverage`, and `make qa` (see Required checks below); `make lint` and `make format` for style.
4. **Submit a pull request** — CI runs the same gates; a maintainer reviews and merges. This is the point where an owner or maintainer decision is required — no contributor bypasses review.

## Required checks

| Gate | Command | What it enforces |
|---|---|---|
| Build | `make build` | The debug application compiles. |
| Tests | `make test` | Full unit, integration, and UI suite, serial, with code coverage; see the [testing guide](docs/engineering/testing.md). |
| Coverage | `make coverage` | 90% line-coverage threshold (excluding the login helper), CI-enforced; threshold configurable via `COVERAGE_THRESHOLD`. |
| QA gate | `make qa` | Full test suite plus fixture and artifact verification. |
| Style | `make lint` / `make format` | SwiftLint and SwiftFormat; required by CI, skipped locally when not installed. |

## Conventions and workflow

- The conventions the repository actually enforces — each grounded in a lint rule, a CI check, a script, or a named rule — are in the [engineering rulebook](notes/rulebook.md): naming, comments, error handling, concurrency, architecture, testing, privacy and security, performance, and Definition of Done.
- The rulebook's change discipline (section 12) and Definition of Done (section 13) define what a reviewable change is and what done means.
- Review workflow: CI gates every change on `main` (formatting, lint, test registration, all test shards, and the coverage gate); the release QA gate is owned by the maintainer ([rulebook](notes/rulebook.md), section 12).

## Ownership and escalation

- Area ownership and responsibility boundaries: the [documentation index](docs/README.md) routes each area to its owning section.
- Security-sensitive or privacy-affecting changes: see the [security policy](SECURITY.md) and the [security section](docs/security/README.md) before submitting.
- Release, versioning, and publication decisions: [publishing guide](docs/engineering/publishing.md) and [distribution](docs/operations/distribution.md).
