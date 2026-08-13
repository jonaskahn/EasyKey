---
id: "contributing_index"
title: "Contributing"
docforge_provenance:
  schema: "2.0"
  doc_id: "contributing_index"
  path: "docs/contributing/README.md"
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
    - id: "contributing"
      sources:
        - path: "docs/_archive/CONVENTIONS.md"
          role: "doc"
          git_blob: "878c15dcb2e9f1fd811a7432688b8b20c6b72512"
      unresolved: []
    - id: "at-a-glance"
      sources:
        - path: "docs/_archive/CONVENTIONS.md"
          role: "doc"
          git_blob: "878c15dcb2e9f1fd811a7432688b8b20c6b72512"
      unresolved: []
    - id: "scope-and-boundaries"
      sources:
        - path: "docs/_archive/CONVENTIONS.md"
          role: "doc"
          git_blob: "878c15dcb2e9f1fd811a7432688b8b20c6b72512"
      unresolved: []
    - id: "start-here"
      sources:
        - path: "docs/_archive/CONVENTIONS.md"
          role: "doc"
          git_blob: "878c15dcb2e9f1fd811a7432688b8b20c6b72512"
        - path: "docs/engineering/testing.md"
          role: "doc"
          git_blob: "7a094e2c60f68ffca552947082f4330c2806213a"
        - path: "docs/engineering/conventions.md"
          role: "doc"
          git_blob: "02aad5e1cfff5c78508b1911053d5bf32be31889"
      unresolved: []
    - id: "detailed-documentation"
      sources:
        - path: "docs/contributing/ownership.md"
          role: "doc"
          git_blob: "45f25725b0e6b57a8e60ddaa6c8a7101b0d2bbb4"
      unresolved: []
    - id: "related-sections"
      sources:
        - path: "docs/_archive/CONVENTIONS.md"
          role: "doc"
          git_blob: "878c15dcb2e9f1fd811a7432688b8b20c6b72512"
      unresolved: []
---
# Contributing

_Last reviewed: 2026-08-03_

This section routes contributors to how EasyKey is built on: the repository-level contribution contract, the enforced conventions, and the engineering workflows for setup, testing, and shipping. Anyone planning to change the codebase should start with the root [Contributing guide](../../CONTRIBUTING.md), which owns the overall contribution process; this page is its section-level router.

## At a glance

Contributing to EasyKey means following one repository-level process (owned by [CONTRIBUTING.md](../../CONTRIBUTING.md)), one rulebook (owned by [rulebook.md](../engineering/rulebook.md)), and the concrete engineering workflows for building, testing, and releasing (owned by the [engineering](../engineering/README.md) section). Detailed documentation materialized inside this section will be listed below as it is written; today the routing is to the owning documents themselves.

## Scope and boundaries

This section owns *contribution routing*: who works on what and which process applies. It does not own the engineering workflow itself (setup, testing, conventions, release — see [engineering](../engineering/README.md)) or the rulebook ([rulebook.md](../engineering/rulebook.md)); both are linked from here rather than restated. The repository-level contribution process lives in [CONTRIBUTING.md](../../CONTRIBUTING.md), the root router for this section.

## Start here

| You want to | Read |
|---|---|
| Understand the overall contribution process before opening a change | [Contributing guide](../../CONTRIBUTING.md) |
| Set up your machine and build the project | [setup](../engineering/setup.md) |
| Run the tests your change will be gated on | [testing](../engineering/testing.md) |
| Follow the enforced style and design conventions | [conventions](../engineering/conventions.md) |
| Read the authoritative rulebook | [rulebook.md](../engineering/rulebook.md) |

## Detailed documentation

<!-- docforge-children:start -->
| Document | Answers |
|---|---|
| [Ownership](ownership.md) | Who owns each area of the repository tree, what owning it means, and where does authority escalate in a single-maintainer project? |
<!-- docforge-children:end -->

## Related sections

- [Documentation home](../README.md) — the parent index of all sections.
- [Contributing guide](../../CONTRIBUTING.md) — the root router for the contribution process (related, not a child).
- [rulebook.md](../engineering/rulebook.md) — the authoritative engineering rulebook (related, not a child).
- [Engineering](../engineering/README.md) — setup, testing, conventions, and release for contributors.
