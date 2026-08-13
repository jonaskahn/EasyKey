---
id: "engineering_index"
title: "Engineering"
description: "Section overview for engineering: how EasyKey is built, tested, and shipped, and the reader question each engineering document answers"
docforge_provenance:
  schema: "2.0"
  doc_id: "engineering_index"
  path: "docs/engineering/README.md"
  generated_at: "2026-08-13T12:08:16Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "orientation"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "engineering"
      sources:
        - path: "README.md"
          role: "doc"
          git_blob: "adbd4f30d3c2f11bb855e6645195493a6c6a34f7"
        - path: "docs/engineering/setup.md"
          role: "doc"
          git_blob: "661a622a02eec68ef83e91a441f1dee551b683c5"
        - path: "docs/engineering/rulebook.md"
          role: "doc"
          git_blob: "dba86c139b41f2fe59027bab1f0e9982fd8d0e00"
      unresolved: []
    - id: "at-a-glance"
      sources:
        - path: "docs/engineering/setup.md"
          role: "doc"
          git_blob: "661a622a02eec68ef83e91a441f1dee551b683c5"
        - path: "docs/engineering/testing.md"
          role: "doc"
          git_blob: "f0f5c4028a6135f533c35e63b97ec91fd26127bf"
        - path: "docs/engineering/conventions.md"
          role: "doc"
          git_blob: "f27ebfe19c8016812230d066d3de0cce2801672d"
        - path: "docs/engineering/release.md"
          role: "doc"
          git_blob: "91aa96ce7f0812ac8d64a6215138d53e485833a6"
        - path: "docs/engineering/publishing.md"
          role: "doc"
          git_blob: "d9f2dc302d9dc04f567decbef6bc8b8b155d81eb"
      unresolved: []
    - id: "scope-and-boundaries"
      sources:
        - path: "docs/engineering/setup.md"
          role: "doc"
          git_blob: "661a622a02eec68ef83e91a441f1dee551b683c5"
        - path: "docs/engineering/release.md"
          role: "doc"
          git_blob: "91aa96ce7f0812ac8d64a6215138d53e485833a6"
        - path: "docs/engineering/rulebook.md"
          role: "doc"
          git_blob: "dba86c139b41f2fe59027bab1f0e9982fd8d0e00"
      unresolved: []
    - id: "start-here"
      sources:
        - path: "docs/engineering/setup.md"
          role: "doc"
          git_blob: "661a622a02eec68ef83e91a441f1dee551b683c5"
        - path: "docs/engineering/testing.md"
          role: "doc"
          git_blob: "f0f5c4028a6135f533c35e63b97ec91fd26127bf"
        - path: "docs/engineering/conventions.md"
          role: "doc"
          git_blob: "f27ebfe19c8016812230d066d3de0cce2801672d"
        - path: "docs/engineering/release.md"
          role: "doc"
          git_blob: "91aa96ce7f0812ac8d64a6215138d53e485833a6"
        - path: "docs/engineering/publishing.md"
          role: "doc"
          git_blob: "d9f2dc302d9dc04f567decbef6bc8b8b155d81eb"
      unresolved: []
    - id: "detailed-documentation"
      sources:
        - path: "docs/engineering/setup.md"
          role: "doc"
          git_blob: "661a622a02eec68ef83e91a441f1dee551b683c5"
        - path: "docs/engineering/testing.md"
          role: "doc"
          git_blob: "f0f5c4028a6135f533c35e63b97ec91fd26127bf"
        - path: "docs/engineering/conventions.md"
          role: "doc"
          git_blob: "f27ebfe19c8016812230d066d3de0cce2801672d"
        - path: "docs/engineering/release.md"
          role: "doc"
          git_blob: "91aa96ce7f0812ac8d64a6215138d53e485833a6"
        - path: "docs/engineering/publishing.md"
          role: "doc"
          git_blob: "d9f2dc302d9dc04f567decbef6bc8b8b155d81eb"
        - path: "docs/engineering/rulebook.md"
          role: "doc"
          git_blob: "dba86c139b41f2fe59027bab1f0e9982fd8d0e00"
      unresolved: []
    - id: "related-sections"
      sources:
        - path: "docs/README.md"
          role: "doc"
          git_blob: "f46130b93e8bd0bfe43446dd7d42555ae5133400"
        - path: "docs/contributing/README.md"
          role: "doc"
          git_blob: "450ddcdfe20c8b1f9d26f2e23e054027ae0d8ca9"
        - path: "docs/operations/README.md"
          role: "doc"
          git_blob: "aec2487a702a755dcfd080d0d8921cbe0b3bb2bf"
      unresolved: []
---
# Engineering

_Last reviewed: 2026-08-13_

This section is the working guide for anyone building, testing, or shipping EasyKey: how to set up a development environment, how the test suites are organized, which conventions the repository actually enforces, and the exact procedure for cutting a release. Engineers new to the project should start here; the rulebook these guides ground themselves in lives in this section too.

## At a glance

The engineering workflow runs from a Makefile-driven toolchain: local setup builds the project with Xcode and runs its test bundles, CI enforces lint, tests, and a coverage gate, and a tagged release produces the signed, packaged DMG plus the Sparkle appcast entry. Six documents own the steps: setup, testing, conventions, release, publishing, and the adopted rulebook. The workflow facts live in those documents — this page only routes to them.

## Scope and boundaries

This section owns the *process* of working on the repository: local setup, test organization, enforced conventions, release procedure, and what publishing exists for the in-repo frameworks. It does not own why the architecture looks the way it does ([architecture](../architecture/README.md)), the operational channels that carry the released artifact ([operations](../operations/README.md)), or the contribution routing that brings a change in ([contributing](../contributing/README.md)). The [rulebook](rulebook.md) is an adopted hand-written document — canonical for conventions, skipped by regeneration, and linked from here rather than restated.

## Start here

| You want to | Read |
|---|---|
| Build EasyKey from source and run the suite locally | [setup.md](setup.md) |
| Run unit, integration, or UI tests — locally or in CI shards | [testing.md](testing.md) |
| Know which conventions are enforced and where you will collide with them | [conventions.md](conventions.md) |
| Read the authoritative conventions before relying on the summary guides | [rulebook.md](rulebook.md) |
| Ship a release from version bump to publication | [release.md](release.md) |
| Understand the framework artifacts and what publishing does and does not exist | [publishing.md](publishing.md) |

## Detailed documentation

<!-- docforge-children:start -->
| Document | Answers |
|---|---|
| [Local setup](setup.md) | How do I build EasyKey from source and run its test suite on my machine? |
| [Testing guide](testing.md) | How are tests organized by layer, and how do I run the unit, integration, and UI suites? |
| [Conventions](conventions.md) | Which conventions does this repository actually enforce, and in what order do contributors collide with them? |
| [Rulebook](rulebook.md) | What are the authoritative engineering conventions — naming, structure, error handling, testing, review — that the guides above ground themselves in? |
| [Release guide](release.md) | What is the exact procedure for shipping an EasyKey release — versioning, build, verification, publication, and rollback? |
| [Publishing](publishing.md) | What are the in-repo framework artifacts, and what publishing pipeline exists — or deliberately does not exist — for them? |
<!-- docforge-children:end -->

## Related sections

- [Documentation home](../README.md) — the parent index of all sections.
- [Contributing](../contributing/README.md) — ownership and contribution routing for the repository.
- [Operations](../operations/README.md) — deployment, distribution, and observability of the released artifact.
- [Reference](../reference/README.md) — stack, compatibility, and configuration facts the workflows depend on.
