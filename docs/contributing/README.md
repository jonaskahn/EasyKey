---
id: "contributing_index"
title: "Contributing"
description: "Section overview for contributing: how EasyKey is built on, and the reader question each contributing document answers"
docforge_provenance:
  schema: "2.0"
  doc_id: "contributing_index"
  path: "docs/contributing/README.md"
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
    - id: "contributing"
      sources:
        - path: "README.md"
          role: "doc"
          git_blob: "0de1699403dbb6d0d24b58a2963cde1ac952a70e"
          git_blob_normalized: "0de1699403dbb6d0d24b58a2963cde1ac952a70e"
        - path: "CONTRIBUTING.md"
          role: "doc"
          git_blob: "9b255093b7f45cf03da8f16a65bc216ac4a2c044"
          git_blob_normalized: "9b255093b7f45cf03da8f16a65bc216ac4a2c044"
        - path: "docs/contributing/ownership.md"
          role: "doc"
          git_blob: "b1a7fed674d124c795a640c43ec29987fde62c5a"
          git_blob_normalized: "b1a7fed674d124c795a640c43ec29987fde62c5a"
      unresolved: []
    - id: "at-a-glance"
      sources:
        - path: "CONTRIBUTING.md"
          role: "doc"
          git_blob: "9b255093b7f45cf03da8f16a65bc216ac4a2c044"
          git_blob_normalized: "9b255093b7f45cf03da8f16a65bc216ac4a2c044"
        - path: "docs/contributing/ownership.md"
          role: "doc"
          git_blob: "b1a7fed674d124c795a640c43ec29987fde62c5a"
          git_blob_normalized: "b1a7fed674d124c795a640c43ec29987fde62c5a"
      unresolved: []
    - id: "scope-and-boundaries"
      sources:
        - path: "CONTRIBUTING.md"
          role: "doc"
          git_blob: "9b255093b7f45cf03da8f16a65bc216ac4a2c044"
          git_blob_normalized: "9b255093b7f45cf03da8f16a65bc216ac4a2c044"
        - path: "docs/contributing/ownership.md"
          role: "doc"
          git_blob: "b1a7fed674d124c795a640c43ec29987fde62c5a"
          git_blob_normalized: "b1a7fed674d124c795a640c43ec29987fde62c5a"
      unresolved: []
    - id: "start-here"
      sources:
        - path: "CONTRIBUTING.md"
          role: "doc"
          git_blob: "9b255093b7f45cf03da8f16a65bc216ac4a2c044"
          git_blob_normalized: "9b255093b7f45cf03da8f16a65bc216ac4a2c044"
        - path: "docs/contributing/ownership.md"
          role: "doc"
          git_blob: "b1a7fed674d124c795a640c43ec29987fde62c5a"
          git_blob_normalized: "b1a7fed674d124c795a640c43ec29987fde62c5a"
        - path: "docs/engineering/setup.md"
          role: "doc"
          git_blob: "0292bf3ada3ba790182d01b5ed80abf58df7fd3d"
          git_blob_normalized: "0292bf3ada3ba790182d01b5ed80abf58df7fd3d"
        - path: "docs/engineering/testing.md"
          role: "doc"
          git_blob: "8bb5cc9a4b9d059453e9f103da683c7956067cf4"
      unresolved: []
    - id: "detailed-documentation"
      sources:
        - path: "docs/contributing/ownership.md"
          role: "doc"
          git_blob: "b1a7fed674d124c795a640c43ec29987fde62c5a"
          git_blob_normalized: "b1a7fed674d124c795a640c43ec29987fde62c5a"
      unresolved: []
    - id: "related-sections"
      sources:
        - path: "docs/README.md"
          role: "doc"
          git_blob: "c26bf46583357c8db29f627fbc0deb41cd7df290"
          git_blob_normalized: "c26bf46583357c8db29f627fbc0deb41cd7df290"
        - path: "docs/engineering/README.md"
          role: "doc"
          git_blob: "c03c59e32926a00ee9ef8344d5df235dd690a4e0"
          git_blob_normalized: "c03c59e32926a00ee9ef8344d5df235dd690a4e0"
      unresolved: []
---
# Contributing

_Last reviewed: 2026-08-14_

This section routes contributors to how EasyKey is built on: who owns what in the repository, and the engineering workflows for setup, testing, and shipping. Anyone planning to change the codebase should start with the root [Contributing guide](../../CONTRIBUTING.md), which owns the overall contribution process; this page is its section-level router.

## At a glance

Contributing to EasyKey means following one repository-level process (owned by [CONTRIBUTING.md](../../CONTRIBUTING.md)) and the concrete engineering workflows for building, testing, and releasing (owned by the [engineering](../engineering/README.md) section). The one detailed document materialized inside this section is the ownership map; the rulebook that conventions ground themselves in lives in [rulebook.md](../engineering/rulebook.md).

## Scope and boundaries

This section owns *contribution routing*: who works on what and which process applies. It does not own the engineering workflow itself (setup, testing, conventions, release — see [engineering](../engineering/README.md)) or the rulebook ([rulebook.md](../engineering/rulebook.md)); both are linked from here rather than restated. The repository-level contribution process lives in [CONTRIBUTING.md](../../CONTRIBUTING.md), the root router for this section.

## Start here

| You want to | Read |
|---|---|
| Understand the overall contribution process before opening a change | [Contributing guide](../../CONTRIBUTING.md) |
| Know who owns each area of the repository tree | [ownership.md](ownership.md) |
| Set up your machine and build the project | [setup](../engineering/setup.md) |
| Run the tests your change will be gated on | [testing](../engineering/testing.md) |

## Detailed documentation

<!-- docforge-children:start -->
| Document | Answers |
|---|---|
| [Ownership](ownership.md) | Who owns each area of the repository tree, what owning it means, and where does authority escalate in a single-maintainer project? |
<!-- docforge-children:end -->

## Related sections

- [Documentation home](../README.md) — the parent index of all sections.
- [Contributing guide](../../CONTRIBUTING.md) — the root router for the contribution process (related, not a child).
- [Engineering](../engineering/README.md) — setup, testing, conventions, and release for contributors.
