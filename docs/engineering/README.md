---
docforge_provenance:
  schema: "2.0"
  doc_id: "engineering_index"
  path: "docs/engineering/README.md"
  generated_at: "2026-08-14T00:00:00Z"
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
          git_blob: "8687b8acd6307c86df97aeaf869a85c5c041e671"
          git_blob_normalized: "8687b8acd6307c86df97aeaf869a85c5c041e671"
          role: "doc"
        - path: "docs/engineering/setup.md"
          git_blob: "963fdcd6db23495eee43ee5de5d9cd168253dcbc"
          git_blob_normalized: "963fdcd6db23495eee43ee5de5d9cd168253dcbc"
          role: "doc"
      unresolved: []
    - id: "at-a-glance"
      sources:
        - path: "docs/engineering/setup.md"
          git_blob: "963fdcd6db23495eee43ee5de5d9cd168253dcbc"
          git_blob_normalized: "963fdcd6db23495eee43ee5de5d9cd168253dcbc"
          role: "doc"
        - path: "docs/engineering/testing.md"
          git_blob: "8bb5cc9a4b9d059453e9f103da683c7956067cf4"
          git_blob_normalized: "8bb5cc9a4b9d059453e9f103da683c7956067cf4"
          role: "doc"
        - path: "docs/engineering/publishing.md"
          git_blob: "8c7a5390ef91f861b5b0fcf3492abc9dc7012f72"
          git_blob_normalized: "8c7a5390ef91f861b5b0fcf3492abc9dc7012f72"
          role: "doc"
      unresolved: []
    - id: "scope-and-boundaries"
      sources:
        - path: "docs/engineering/setup.md"
          git_blob: "963fdcd6db23495eee43ee5de5d9cd168253dcbc"
          git_blob_normalized: "963fdcd6db23495eee43ee5de5d9cd168253dcbc"
          role: "doc"
        - path: "docs/engineering/rulebook.md"
          git_blob: "dba86c139b41f2fe59027bab1f0e9982fd8d0e00"
          git_blob_normalized: "dba86c139b41f2fe59027bab1f0e9982fd8d0e00"
          role: "doc"
      unresolved: []
    - id: "start-here"
      sources:
        - path: "docs/engineering/setup.md"
          git_blob: "963fdcd6db23495eee43ee5de5d9cd168253dcbc"
          git_blob_normalized: "963fdcd6db23495eee43ee5de5d9cd168253dcbc"
          role: "doc"
        - path: "docs/engineering/testing.md"
          git_blob: "8bb5cc9a4b9d059453e9f103da683c7956067cf4"
          git_blob_normalized: "8bb5cc9a4b9d059453e9f103da683c7956067cf4"
          role: "doc"
        - path: "docs/engineering/publishing.md"
          git_blob: "8c7a5390ef91f861b5b0fcf3492abc9dc7012f72"
          git_blob_normalized: "8c7a5390ef91f861b5b0fcf3492abc9dc7012f72"
          role: "doc"
      unresolved: []
    - id: "detailed-documentation"
      sources:
        - path: "docs/engineering/setup.md"
          git_blob: "963fdcd6db23495eee43ee5de5d9cd168253dcbc"
          git_blob_normalized: "963fdcd6db23495eee43ee5de5d9cd168253dcbc"
          role: "doc"
        - path: "docs/engineering/testing.md"
          git_blob: "8bb5cc9a4b9d059453e9f103da683c7956067cf4"
          git_blob_normalized: "8bb5cc9a4b9d059453e9f103da683c7956067cf4"
          role: "doc"
        - path: "docs/engineering/publishing.md"
          git_blob: "8c7a5390ef91f861b5b0fcf3492abc9dc7012f72"
          git_blob_normalized: "8c7a5390ef91f861b5b0fcf3492abc9dc7012f72"
          role: "doc"
      unresolved: []
    - id: "related-sections"
      sources:
        - path: "docs/README.md"
          git_blob: "4e9392f1d88c919a51368d4ed091365f24ecbea8"
          git_blob_normalized: "4e9392f1d88c919a51368d4ed091365f24ecbea8"
          role: "doc"
        - path: "docs/operations/README.md"
          git_blob: "aad2922a8ab386e2c86773d2e060cdbd3c3afc1e"
          git_blob_normalized: "aad2922a8ab386e2c86773d2e060cdbd3c3afc1e"
          role: "doc"
        - path: "docs/reference/README.md"
          git_blob: "0ce215295807dfce3703dff3da14c752a40a3c1f"
          git_blob_normalized: "0ce215295807dfce3703dff3da14c752a40a3c1f"
          role: "doc"
      unresolved: []
---
# Engineering

_Last reviewed: 2026-08-15_

This section is the working guide for anyone building or testing EasyKey: how to set up a development environment, how the test suites are organized, which conventions the rulebook enforces, and what publishing exists — or deliberately does not — for the in-repo frameworks. Engineers new to the project should start here.

## At a glance

The engineering workflow runs from a Makefile-driven toolchain: local setup builds the project with Xcode and runs its test bundles, and CI enforces lint, tests, and a coverage gate. Packaging and distribution of the released artifact are covered by the operations section; three documents own the engineering steps: setup, testing, and publishing. The workflow facts live in those documents — this page only routes to them.

## Scope and boundaries

This section owns the *process* of working on the repository: local setup, test organization, enforced conventions, and what publishing exists for the in-repo frameworks. It does not own why the architecture looks the way it does ([architecture](../architecture/README.md)) or the operational channels that carry the released artifact ([operations](../operations/README.md)). The [rulebook](rulebook.md) is an adopted hand-written document — canonical for conventions, skipped by regeneration, and linked from here rather than restated.

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

- [Documentation home](../README.md) — the parent index of all sections.
- [Operations](../operations/README.md) — the distribution channels that carry the released artifact.
- [Reference](../reference/README.md) — stack, compatibility, and configuration facts the workflows depend on.
