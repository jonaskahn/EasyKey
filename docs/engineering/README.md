---
id: "engineering_index"
title: "Engineering"
docforge_provenance:
  schema: "2.0"
  doc_id: "engineering_index"
  path: "docs/engineering/README.md"
  generated_at: "2026-08-03T09:30:00Z"
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
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
        - path: "docs/engineering/setup.md"
          role: "doc"
          git_blob: "90feaba9f2abd75bf4358df2a134f606284158b0"
      unresolved: []
    - id: "at-a-glance"
      sources:
        - path: "docs/engineering/setup.md"
          role: "doc"
          git_blob: "90feaba9f2abd75bf4358df2a134f606284158b0"
        - path: "docs/engineering/testing.md"
          role: "doc"
          git_blob: "7a094e2c60f68ffca552947082f4330c2806213a"
        - path: "docs/engineering/conventions.md"
          role: "doc"
          git_blob: "02aad5e1cfff5c78508b1911053d5bf32be31889"
      unresolved: []
    - id: "scope-and-boundaries"
      sources:
        - path: "docs/engineering/setup.md"
          role: "doc"
          git_blob: "90feaba9f2abd75bf4358df2a134f606284158b0"
        - path: "docs/engineering/release.md"
          role: "doc"
          git_blob: "4bc23379b9083661a9ee65bc953e02d9231d6adf"
      unresolved: []
    - id: "start-here"
      sources:
        - path: "docs/engineering/setup.md"
          role: "doc"
          git_blob: "90feaba9f2abd75bf4358df2a134f606284158b0"
        - path: "docs/engineering/testing.md"
          role: "doc"
          git_blob: "7a094e2c60f68ffca552947082f4330c2806213a"
        - path: "docs/engineering/release.md"
          role: "doc"
          git_blob: "4bc23379b9083661a9ee65bc953e02d9231d6adf"
      unresolved: []
    - id: "detailed-documentation"
      sources:
        - path: "docs/engineering/setup.md"
          role: "doc"
          git_blob: "90feaba9f2abd75bf4358df2a134f606284158b0"
        - path: "docs/engineering/testing.md"
          role: "doc"
          git_blob: "7a094e2c60f68ffca552947082f4330c2806213a"
        - path: "docs/engineering/conventions.md"
          role: "doc"
          git_blob: "02aad5e1cfff5c78508b1911053d5bf32be31889"
        - path: "docs/engineering/release.md"
          role: "doc"
          git_blob: "4bc23379b9083661a9ee65bc953e02d9231d6adf"
        - path: "docs/engineering/publishing.md"
          role: "doc"
          git_blob: "a37dae9d66f36e375aa0d40f5013968fa2e2e7fd"
      unresolved: []
    - id: "related-sections"
      sources:
        - path: "docs/contributing/README.md"
          role: "doc"
          git_blob: "da7dd1a8bd73ce72867c8e4aef11ff072a48fab3"
      unresolved: []
---
# Engineering

_Last reviewed: 2026-08-03_

This section is the working guide for anyone building, testing, or shipping EasyKey: how to set up a development environment, how the test suites are organized, which conventions the repository actually enforces, and the exact procedure for cutting a release. Engineers new to the project should start here; the rulebook these guides ground themselves in lives in [CONVENTIONS.md](conventions.md).

## At a glance

The engineering workflow runs from a Makefile-driven toolchain: local setup builds the project with Xcode and runs its test bundles, CI enforces lint, tests, and a coverage gate, and a tagged release produces the signed, packaged DMG plus the Sparkle appcast entry. Five documents own the steps: setup, testing, conventions, release, and publishing. The workflow facts live in those documents — this page only routes to them.

## Scope and boundaries

This section owns the *process* of working on the repository: local setup, test organization, enforced conventions, release procedure, and what publishing exists for the in-repo frameworks. It does not own why the architecture looks the way it does ([architecture](../architecture/README.md)), the operational channels that carry the released artifact ([operations](../operations/README.md)), or the canonical rulebook, which lives in [CONVENTIONS.md](conventions.md) and is the authoritative source for conventions.

## Start here

| You want to | Read |
|---|---|
| Build EasyKey from source and run the suite locally | [setup.md](setup.md) |
| Run unit, integration, or UI tests — locally or in CI shards | [testing.md](testing.md) |
| Know which conventions are enforced and where you will collide with them | [conventions.md](conventions.md) |
| Ship a release from version bump to publication | [release.md](release.md) |
| Understand the framework artifacts and what publishing does and does not exist | [publishing.md](publishing.md) |

## Detailed documentation

<!-- docforge-children:start -->
| Document | Answers |
|---|---|
| [Local setup](setup.md) | How do I build EasyKey from source and run its test suite on my machine? |
| [Testing guide](testing.md) | How are tests organized by layer, and how do I run the unit, integration, and UI suites? |
| [Conventions](conventions.md) | Which conventions does this repository actually enforce, and in what order do contributors collide with them? |
| [Release guide](release.md) | What is the exact procedure for shipping an EasyKey release — versioning, build, verification, publication, and rollback? |
| [Publishing](publishing.md) | What are the in-repo framework artifacts, and what publishing pipeline exists — or deliberately does not exist — for them? |
<!-- docforge-children:end -->

## Related sections

- [Documentation home](../README.md) — the parent index of all sections.
- [Contributing](../contributing/README.md) — ownership and contribution routing for the repository.
- [Operations](../operations/README.md) — deployment, distribution, and observability of the released artifact.
