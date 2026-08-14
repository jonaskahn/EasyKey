---
id: "contributing_root"
title: "Contributing Root"
description: "Verified contribution path, required checks, conventions and ownership links"
docforge_provenance:
  schema: "2.0"
  doc_id: "contributing_root"
  path: "CONTRIBUTING.md"
  generated_at: "2026-08-14T00:00:00Z"
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
          role: "doc"
          git_blob: "0de1699403dbb6d0d24b58a2963cde1ac952a70e"
          git_blob_normalized: "0de1699403dbb6d0d24b58a2963cde1ac952a70e"
      unresolved: []
    - id: "prerequisites"
      sources:
        - path: "Makefile"
          role: "config"
          git_blob: "b0926ee99352f08ba3eb3475b4ef45bfc143fe65"
        - path: "docs/engineering/setup.md"
          role: "doc"
          git_blob: "0292bf3ada3ba790182d01b5ed80abf58df7fd3d"
          git_blob_normalized: "0292bf3ada3ba790182d01b5ed80abf58df7fd3d"
      unresolved: []
    - id: "the-contribution-path"
      sources:
        - path: "docs/engineering/setup.md"
          role: "doc"
          git_blob: "0292bf3ada3ba790182d01b5ed80abf58df7fd3d"
          git_blob_normalized: "0292bf3ada3ba790182d01b5ed80abf58df7fd3d"
        - path: "docs/engineering/conventions.md"
          role: "doc"
          git_blob: "3aefa68f5f4f8144c46f57517d76e1a26b304ea6"
          git_blob_normalized: "3aefa68f5f4f8144c46f57517d76e1a26b304ea6"
        - path: "Makefile"
          role: "config"
          git_blob: "b0926ee99352f08ba3eb3475b4ef45bfc143fe65"
      unresolved: []
    - id: "required-checks"
      sources:
        - path: "Makefile"
          role: "config"
          git_blob: "b0926ee99352f08ba3eb3475b4ef45bfc143fe65"
        - path: "Scripts/check-coverage.sh"
          role: "code"
          git_blob: "062819eb35129c6a6cd891d330643dee7a45db1a"
        - path: "Scripts/qa-gate.sh"
          role: "code"
          git_blob: "148320feb241615087d1cda4ef51cac8706e78bf"
        - path: "docs/engineering/testing.md"
          role: "doc"
          git_blob: "8bb5cc9a4b9d059453e9f103da683c7956067cf4"
        - path: "docs/engineering/conventions.md"
          role: "doc"
          git_blob: "3aefa68f5f4f8144c46f57517d76e1a26b304ea6"
          git_blob_normalized: "3aefa68f5f4f8144c46f57517d76e1a26b304ea6"
      unresolved: []
    - id: "conventions-and-workflow"
      sources:
        - path: "docs/engineering/conventions.md"
          role: "doc"
          git_blob: "3aefa68f5f4f8144c46f57517d76e1a26b304ea6"
          git_blob_normalized: "3aefa68f5f4f8144c46f57517d76e1a26b304ea6"
        - path: "docs/engineering/rulebook.md"
          role: "doc"
          git_blob: "dba86c139b41f2fe59027bab1f0e9982fd8d0e00"
      unresolved: []
    - id: "ownership-and-escalation"
      sources:
        - path: "docs/contributing/ownership.md"
          role: "doc"
          git_blob: "b1a7fed674d124c795a640c43ec29987fde62c5a"
          git_blob_normalized: "b1a7fed674d124c795a640c43ec29987fde62c5a"
        - path: "docs/security/README.md"
          role: "doc"
          git_blob: "00d2d03c162cf5a3c46fed97b8b9c9cf79e43b7e"
          git_blob_normalized: "00d2d03c162cf5a3c46fed97b8b9c9cf79e43b7e"
        - path: "docs/engineering/release.md"
          role: "doc"
          git_blob: "08e857f3de258116f1a988f7b9f6b0ed96dd189e"
          git_blob_normalized: "08e857f3de258116f1a988f7b9f6b0ed96dd189e"
      unresolved: []
---
# Contributing

_Last reviewed: 2026-08-14_

This page is the shortest verified route from a fresh checkout to a merged change. Detailed setup, testing, convention, and ownership rules live in the documents this page links to — they are the owners of the specifics.

## Prerequisites

Xcode 15 or later, macOS 14.0 or later, and Git with command-line tools; SwiftLint and SwiftFormat are optional locally (`make lint` and `make format` skip them when absent). No credentials or special access are needed to build, test, and run locally. The full table — including what signed distribution needs — is in the [setup guide](docs/engineering/setup.md).

## The contribution path

1. **Set up the workspace** — clone, `make build`, then `make run` per the [setup guide](docs/engineering/setup.md). Verify with `make qa`.
2. **Make one focused change** — follow the change discipline and Definition of Done in the [engineering conventions](docs/engineering/conventions.md): keep each change reviewable, separate behavior changes from mechanical refactors, and update tests and documentation with the code they describe.
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

- The conventions the repository actually enforces — each grounded in a lint rule, a CI check, a script, or a named rule — are in the [engineering conventions](docs/engineering/conventions.md): naming, comments, error handling, concurrency, architecture, testing, privacy and security, performance, and Definition of Done.
- The authoritative rulebook is [rulebook.md](docs/engineering/rulebook.md); its change discipline (section 12) and Definition of Done (section 13) define what a reviewable change is and what done means.
- Review workflow: CI gates every change on `main` (formatting, lint, test registration, all test shards, and the coverage gate); the release QA gate is owned by the maintainer ([conventions](docs/engineering/conventions.md)).

## Ownership and escalation

- Area ownership, responsibility boundaries, and escalation paths: [ownership](docs/contributing/ownership.md).
- Security-sensitive or privacy-affecting changes: see the [security policy](SECURITY.md) and the [security section](docs/security/README.md) before submitting.
- Release, versioning, and publication decisions: [release guide](docs/engineering/release.md).
