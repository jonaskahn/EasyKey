---
id: "contributing_root"
title: "Contributing Root"
description: "Verified contribution path, required checks, conventions and ownership links"
docforge_provenance:
  schema: "2.0"
  doc_id: "contributing_root"
  path: "CONTRIBUTING.md"
  generated_at: "2026-08-13T12:18:58Z"
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
          git_blob: "adbd4f30d3c2f11bb855e6645195493a6c6a34f7"
          git_blob_normalized: "adbd4f30d3c2f11bb855e6645195493a6c6a34f7"
          role: "doc"
      unresolved: []
    - id: "prerequisites"
      sources:
        - path: "Makefile"
          git_blob: "06aa63c4ea11d09c149d6fb44b499e07f014f117"
          git_blob_normalized: "06aa63c4ea11d09c149d6fb44b499e07f014f117"
          role: "config"
        - path: "docs/engineering/setup.md"
          git_blob: "661a622a02eec68ef83e91a441f1dee551b683c5"
          git_blob_normalized: "661a622a02eec68ef83e91a441f1dee551b683c5"
          role: "doc"
      unresolved: []
    - id: "the-contribution-path"
      sources:
        - path: "docs/engineering/setup.md"
          git_blob: "661a622a02eec68ef83e91a441f1dee551b683c5"
          git_blob_normalized: "661a622a02eec68ef83e91a441f1dee551b683c5"
          role: "doc"
        - path: "docs/engineering/conventions.md"
          git_blob: "f27ebfe19c8016812230d066d3de0cce2801672d"
          git_blob_normalized: "f27ebfe19c8016812230d066d3de0cce2801672d"
          role: "doc"
        - path: "Makefile"
          git_blob: "06aa63c4ea11d09c149d6fb44b499e07f014f117"
          git_blob_normalized: "06aa63c4ea11d09c149d6fb44b499e07f014f117"
          role: "config"
      unresolved: []
    - id: "required-checks"
      sources:
        - path: "Makefile"
          git_blob: "06aa63c4ea11d09c149d6fb44b499e07f014f117"
          git_blob_normalized: "06aa63c4ea11d09c149d6fb44b499e07f014f117"
          role: "config"
        - path: "Scripts/check-coverage.sh"
          git_blob: "062819eb35129c6a6cd891d330643dee7a45db1a"
          git_blob_normalized: "062819eb35129c6a6cd891d330643dee7a45db1a"
          role: "code"
        - path: "Scripts/qa-gate.sh"
          git_blob: "148320feb241615087d1cda4ef51cac8706e78bf"
          git_blob_normalized: "148320feb241615087d1cda4ef51cac8706e78bf"
          role: "code"
        - path: "docs/engineering/testing.md"
          git_blob: "f0f5c4028a6135f533c35e63b97ec91fd26127bf"
          git_blob_normalized: "f0f5c4028a6135f533c35e63b97ec91fd26127bf"
          role: "doc"
        - path: "docs/engineering/conventions.md"
          git_blob: "f27ebfe19c8016812230d066d3de0cce2801672d"
          git_blob_normalized: "f27ebfe19c8016812230d066d3de0cce2801672d"
          role: "doc"
      unresolved: []
    - id: "conventions-and-workflow"
      sources:
        - path: "docs/engineering/conventions.md"
          git_blob: "f27ebfe19c8016812230d066d3de0cce2801672d"
          git_blob_normalized: "f27ebfe19c8016812230d066d3de0cce2801672d"
          role: "doc"
        - path: "docs/engineering/rulebook.md"
          git_blob: "dba86c139b41f2fe59027bab1f0e9982fd8d0e00"
          git_blob_normalized: "dba86c139b41f2fe59027bab1f0e9982fd8d0e00"
          role: "doc"
      unresolved: []
    - id: "ownership-and-escalation"
      sources:
        - path: "docs/contributing/ownership.md"
          git_blob: "bb4f8c662906fad3766f93e76c196dcc34ff2418"
          git_blob_normalized: "bb4f8c662906fad3766f93e76c196dcc34ff2418"
          role: "doc"
        - path: "docs/security/README.md"
          git_blob: "67d80093c01fb3815d5db89ba9c5c753806426ae"
          git_blob_normalized: "67d80093c01fb3815d5db89ba9c5c753806426ae"
          role: "doc"
        - path: "docs/engineering/release.md"
          git_blob: "91aa96ce7f0812ac8d64a6215138d53e485833a6"
          git_blob_normalized: "91aa96ce7f0812ac8d64a6215138d53e485833a6"
          role: "doc"
      unresolved: []
---
# Contributing

_Last reviewed: 2026-08-13_

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
