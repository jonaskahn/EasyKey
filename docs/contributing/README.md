---
id: "contributing_index"
title: "Contributing"
description: "Section overview for contributing: how EasyKey is built on, and the reader question each contributing document answers"
docforge_provenance:
  schema: "2.0"
  doc_id: "contributing_index"
  path: "docs/contributing/README.md"
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
    - id: "contributing"
      sources:
        - path: "README.md"
          role: "doc"
          git_blob: "adbd4f30d3c2f11bb855e6645195493a6c6a34f7"
        - path: "CONTRIBUTING.md"
          role: "doc"
          git_blob: "3b545b144069179a806154b7c57e9bdd42205e58"
        - path: "docs/contributing/ownership.md"
          role: "doc"
          git_blob: "bb4f8c662906fad3766f93e76c196dcc34ff2418"
      unresolved: []
    - id: "at-a-glance"
      sources:
        - path: "CONTRIBUTING.md"
          role: "doc"
          git_blob: "3b545b144069179a806154b7c57e9bdd42205e58"
        - path: "docs/contributing/ownership.md"
          role: "doc"
          git_blob: "bb4f8c662906fad3766f93e76c196dcc34ff2418"
      unresolved: []
    - id: "scope-and-boundaries"
      sources:
        - path: "CONTRIBUTING.md"
          role: "doc"
          git_blob: "3b545b144069179a806154b7c57e9bdd42205e58"
        - path: "docs/contributing/ownership.md"
          role: "doc"
          git_blob: "bb4f8c662906fad3766f93e76c196dcc34ff2418"
      unresolved: []
    - id: "start-here"
      sources:
        - path: "CONTRIBUTING.md"
          role: "doc"
          git_blob: "3b545b144069179a806154b7c57e9bdd42205e58"
        - path: "docs/contributing/ownership.md"
          role: "doc"
          git_blob: "bb4f8c662906fad3766f93e76c196dcc34ff2418"
        - path: "docs/engineering/setup.md"
          role: "doc"
          git_blob: "661a622a02eec68ef83e91a441f1dee551b683c5"
        - path: "docs/engineering/testing.md"
          role: "doc"
          git_blob: "f0f5c4028a6135f533c35e63b97ec91fd26127bf"
      unresolved: []
    - id: "detailed-documentation"
      sources:
        - path: "docs/contributing/ownership.md"
          role: "doc"
          git_blob: "bb4f8c662906fad3766f93e76c196dcc34ff2418"
      unresolved: []
    - id: "related-sections"
      sources:
        - path: "docs/README.md"
          role: "doc"
          git_blob: "f46130b93e8bd0bfe43446dd7d42555ae5133400"
        - path: "docs/engineering/README.md"
          role: "doc"
          git_blob: "eb772ae315052f41c6bd2267dbc0886260ba0447"
      unresolved: []
---
# Contributing

_Last reviewed: 2026-08-13_

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
