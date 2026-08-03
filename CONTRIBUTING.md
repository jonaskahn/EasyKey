---
docforge_provenance:
  schema: "2.0"
  doc_id: "contributing_root"
  path: "CONTRIBUTING.md"
  generated_at: "2026-08-03T09:24:40Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "router"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "contributing"
      sources:
        - path: "README.md"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
          role: "doc"
      unresolved: []
    - id: "prerequisites"
      sources:
        - path: "Makefile"
          git_blob: "b8fa0059c061eef05cb083ae69e8e7d46336aa64"
          role: "config"
      unresolved: []
    - id: "the-contribution-path"
      sources:
        - path: "docs/_archive/CONVENTIONS.md"
          git_blob: "878c15dcb2e9f1fd811a7432688b8b20c6b72512"
          role: "doc"
      unresolved: []
    - id: "required-checks"
      sources:
        - path: "Makefile"
          git_blob: "b8fa0059c061eef05cb083ae69e8e7d46336aa64"
          role: "config"
        - path: "docs/engineering/testing.md"
          git_blob: "7a094e2c60f68ffca552947082f4330c2806213a"
          role: "doc"
        - path: "Scripts/check-coverage.sh"
          git_blob: "062819eb35129c6a6cd891d330643dee7a45db1a"
          role: "code"
      unresolved: []
    - id: "conventions-and-workflow"
      sources:
        - path: "docs/_archive/CONVENTIONS.md"
          git_blob: "878c15dcb2e9f1fd811a7432688b8b20c6b72512"
          role: "doc"
        - path: "docs/engineering/conventions.md"
          git_blob: "02aad5e1cfff5c78508b1911053d5bf32be31889"
          role: "doc"
      unresolved: []
    - id: "ownership-and-escalation"
      sources:
        - path: "docs/contributing/ownership.md"
          git_blob: "45f25725b0e6b57a8e60ddaa6c8a7101b0d2bbb4"
          role: "doc"
      unresolved: []
---
# Contributing

_Last reviewed: 2026-08-03_

This page is the shortest verified route from a fresh checkout to a merged change. Detailed setup, testing, convention, and ownership rules live in the documents this page links to — they are the owners of the specifics.

## Prerequisites

Xcode 15 or later, macOS 14.0 or later, and Git with command-line tools; SwiftLint and SwiftFormat are optional locally (`make lint` and `make format` skip them when absent). No credentials or special access are needed to build, test, and run locally. The full table — including what signed distribution needs — is in the [setup guide](docs/engineering/setup.md).

## The contribution path

1. **Set up the workspace** — clone, `make build`, then `make run` per the [setup guide](docs/engineering/setup.md). Verify with `make qa`.
2. **Make one focused change** — follow the change discipline and Definition of Done in [CONVENTIONS.md](docs/engineering/conventions.md): keep each change reviewable, separate behavior changes from mechanical refactors, and update tests and documentation with the code they describe.
3. **Run the required checks** — `make build`, `make test`, `make coverage`, and `make qa` (see Required checks below); `make lint` and `make format` for style.
4. **Submit a pull request** — CI runs the same gates; a maintainer reviews and merges. This is the point where an owner or maintainer decision is required — no contributor bypasses review.

## Required checks

| Gate | Command | What it enforces |
|---|---|---|
| Build | `make build` | The debug application compiles. |
| Tests | `make test` | Full unit, integration, and UI suite, serial, with code coverage; see the [testing guide](docs/engineering/testing.md). |
| Coverage | `make coverage` | 90% line-coverage threshold (excluding the login helper), CI-enforced; threshold configurable via `COVERAGE_THRESHOLD`. |
| QA gate | `make qa` | Full test suite plus fixture and artifact verification. |
| Style | `make lint` / `make format` | SwiftLint and SwiftFormat; enforced by CI when installed locally. |

## Conventions and workflow

- The rulebook is [CONVENTIONS.md](docs/engineering/conventions.md): naming, comments, error handling, concurrency, architecture, testing, privacy and security, performance, and Definition of Done.
- The conventions the repository actually enforces — each grounded in a lint rule, a CI check, or a script — are listed in the [engineering conventions](docs/engineering/conventions.md).
- Workflow expectations (change discipline, review order, Definition of Done) are documented in [CONVENTIONS.md](docs/engineering/conventions.md).

## Ownership and escalation

- Area ownership, responsibility boundaries, and escalation paths: [ownership](docs/contributing/ownership.md).
- Security-sensitive or privacy-affecting changes: see the [security policy](SECURITY.md) and the [security section](docs/security/README.md) before submitting.
- Release, versioning, and publication decisions: [release guide](docs/engineering/release.md).
