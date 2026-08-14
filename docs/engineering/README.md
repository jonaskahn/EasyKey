---
id: "engineering_index"
title: "Engineering"
description: "Engineering documentation overview: what this section covers and the reader question each engineering document answers"
docforge_provenance:
  schema: "2.0"
  doc_id: "engineering_index"
  path: "docs/engineering/README.md"
  generated_at: "2026-08-14T00:00:00Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "spine"
  target_depth: "orientation"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "engineering"
      sources:
        - path: "README.md"
          git_blob: "8fc7891befa21173acaaaf1b19c8c30ad6bb3f97"
          git_blob_normalized: "8fc7891befa21173acaaaf1b19c8c30ad6bb3f97"
          role: "doc"
        - path: "docs/engineering/setup.md"
          git_blob: "31e235c41a5764c7e56e98f62e7df4ba9e120b9e"
          git_blob_normalized: "31e235c41a5764c7e56e98f62e7df4ba9e120b9e"
          role: "doc"
      unresolved: []
    - id: "at-a-glance"
      sources:
        - path: "docs/engineering/setup.md"
          git_blob: "31e235c41a5764c7e56e98f62e7df4ba9e120b9e"
          git_blob_normalized: "31e235c41a5764c7e56e98f62e7df4ba9e120b9e"
          role: "doc"
        - path: "docs/engineering/testing.md"
          git_blob: "61f561d90f43c4e7fbe17de6c472e88b8f3b40ac"
          git_blob_normalized: "61f561d90f43c4e7fbe17de6c472e88b8f3b40ac"
          role: "doc"
        - path: "docs/engineering/publishing.md"
          git_blob: "702391fc81afa9ab19acd746fe10a3dcd78c2e4f"
          git_blob_normalized: "702391fc81afa9ab19acd746fe10a3dcd78c2e4f"
          role: "doc"
      unresolved: []
    - id: "scope-and-boundaries"
      sources:
        - path: "docs/engineering/setup.md"
          git_blob: "31e235c41a5764c7e56e98f62e7df4ba9e120b9e"
          git_blob_normalized: "31e235c41a5764c7e56e98f62e7df4ba9e120b9e"
          role: "doc"
        - path: "docs/_archive/rulebook.md"
          git_blob: "adbd3fec4e0f76f10542989e894a89e46dda4afd"
          git_blob_normalized: "adbd3fec4e0f76f10542989e894a89e46dda4afd"
          role: "doc"
      unresolved: []
    - id: "start-here"
      sources:
        - path: "docs/engineering/setup.md"
          git_blob: "31e235c41a5764c7e56e98f62e7df4ba9e120b9e"
          git_blob_normalized: "31e235c41a5764c7e56e98f62e7df4ba9e120b9e"
          role: "doc"
        - path: "docs/engineering/testing.md"
          git_blob: "61f561d90f43c4e7fbe17de6c472e88b8f3b40ac"
          git_blob_normalized: "61f561d90f43c4e7fbe17de6c472e88b8f3b40ac"
          role: "doc"
        - path: "docs/engineering/publishing.md"
          git_blob: "702391fc81afa9ab19acd746fe10a3dcd78c2e4f"
          git_blob_normalized: "702391fc81afa9ab19acd746fe10a3dcd78c2e4f"
          role: "doc"
      unresolved: []
    - id: "detailed-documentation"
      sources:
        - path: "docs/engineering/setup.md"
          git_blob: "31e235c41a5764c7e56e98f62e7df4ba9e120b9e"
          git_blob_normalized: "31e235c41a5764c7e56e98f62e7df4ba9e120b9e"
          role: "doc"
        - path: "docs/engineering/testing.md"
          git_blob: "61f561d90f43c4e7fbe17de6c472e88b8f3b40ac"
          git_blob_normalized: "61f561d90f43c4e7fbe17de6c472e88b8f3b40ac"
          role: "doc"
        - path: "docs/engineering/publishing.md"
          git_blob: "702391fc81afa9ab19acd746fe10a3dcd78c2e4f"
          git_blob_normalized: "702391fc81afa9ab19acd746fe10a3dcd78c2e4f"
          role: "doc"
      unresolved: []
    - id: "related-sections"
      sources: []
      unresolved: []
---
# Engineering

_Last reviewed: 2026-08-15_

This section is the working guide for anyone building or testing EasyKey: how to set up a development environment, how the test suites are organized, which conventions the rulebook enforces, and what publishing exists — or deliberately does not — for the in-repo frameworks. Engineers new to the project should start here.

## At a glance

The engineering workflow runs from a Makefile-driven toolchain: local setup builds the project with Xcode and runs its test bundles, and CI enforces lint, tests, and a coverage gate. Packaging and distribution of the released artifact are covered by the operations section; three documents own the engineering steps: setup, testing, and publishing. The workflow facts live in those documents — this page only routes to them.

## Scope and boundaries

This section owns the *process* of working on the repository: local setup, test organization, enforced conventions, and what publishing exists for the in-repo frameworks. It does not own why the architecture looks the way it does ([architecture](../architecture/README.md)) or the operational channels that carry the released artifact ([operations](../operations/README.md)). The the archived engineering rulebook is an adopted hand-written document — canonical for conventions, skipped by regeneration, and linked from here rather than restated.

## Start here

| You want to | Read |
|---|---|
| Build EasyKey from source and run the suite locally | [setup.md](setup.md) |
| Run unit, integration, or UI tests — locally or in CI shards | [testing.md](testing.md) |
| Understand the framework artifacts and what publishing does and does not exist | [publishing.md](publishing.md) |

## Detailed documentation

<!-- docforge-children:start -->
| Document | Answers |
|---|---|
| [Local setup](setup.md) | How do I build EasyKey from source and run its test suite on my machine? |
| [Testing guide](testing.md) | How are tests organized by layer, and how do I run the unit, integration, and UI suites? |
| [Publishing](publishing.md) | What are the in-repo framework artifacts, and what publishing pipeline exists — or deliberately does not exist — for them? |
<!-- docforge-children:end -->

## Related sections

- README — the parent index of all sections.
- [Operations](../operations/README.md) — the distribution channels that carry the released artifact.
- [Reference](../reference/README.md) — stack, compatibility, and configuration facts the workflows depend on.
