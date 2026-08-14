---
id: "library_migrations_index"
title: "Migrations"
description: "Migration documentation overview: what migrations are, scope, and the reader question each migration document answers"
docforge_provenance:
  schema: "2.0"
  doc_id: "library_migrations_index"
  path: "docs/product/migrations/README.md"
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
    - id: "migrations"
      sources:
        - path: "docs/product/README.md"
          role: "doc"
          git_blob: "cda07357aed525e0e411b6d9abd6fa1467f731c2"
          git_blob_normalized: "cda07357aed525e0e411b6d9abd6fa1467f731c2"
        - path: "docs/product/migrations/settings.md"
          role: "doc"
          git_blob: "6b5e3ac1931df9d8127d5b4908a5ed4850053b7f"
      unresolved: []
    - id: "at-a-glance"
      sources:
        - path: "docs/product/migrations/settings.md"
          role: "doc"
          git_blob: "6b5e3ac1931df9d8127d5b4908a5ed4850053b7f"
      unresolved: []
    - id: "scope-and-boundaries"
      sources:
        - path: "docs/product/migrations/settings.md"
          role: "doc"
          git_blob: "6b5e3ac1931df9d8127d5b4908a5ed4850053b7f"
        - path: "docs/architecture/decisions/README.md"
          role: "doc"
          git_blob: "f405104e88ddde03d6806f697e242c59dd9800d6"
          git_blob_normalized: "f405104e88ddde03d6806f697e242c59dd9800d6"
        - path: "docs/operations/README.md"
          role: "doc"
          git_blob: "eda19de1f8eccea8d470c042fda1b1e1b8f3004e"
          git_blob_normalized: "eda19de1f8eccea8d470c042fda1b1e1b8f3004e"
        - path: "docs/reference/compatibility.md"
          role: "doc"
          git_blob: "457132b1d0e239eeae5dcc195a864debf6f7ac76"
          git_blob_normalized: "457132b1d0e239eeae5dcc195a864debf6f7ac76"
      unresolved: []
    - id: "start-here"
      sources:
        - path: "docs/product/migrations/settings.md"
          role: "doc"
          git_blob: "6b5e3ac1931df9d8127d5b4908a5ed4850053b7f"
      unresolved: []
    - id: "detailed-documentation"
      sources:
        - path: "docs/product/migrations/settings.md"
          role: "doc"
          git_blob: "6b5e3ac1931df9d8127d5b4908a5ed4850053b7f"
      unresolved: []
    - id: "related-sections"
      sources:
        - path: "docs/product/README.md"
          role: "doc"
          git_blob: "cda07357aed525e0e411b6d9abd6fa1467f731c2"
          git_blob_normalized: "cda07357aed525e0e411b6d9abd6fa1467f731c2"
        - path: "docs/README.md"
          role: "doc"
          git_blob: "c26bf46583357c8db29f627fbc0deb41cd7df290"
          git_blob_normalized: "c26bf46583357c8db29f627fbc0deb41cd7df290"
      unresolved: []
---
# Migrations

_Last reviewed: 2026-08-14_

This section documents what happens to a user's data and preferences when EasyKey moves between versions — which stored shapes change, what is upgraded automatically, what is lost, and how to verify the migration. It exists so engineers shipping a breaking change and users upgrading across versions can both find out what to expect. The reader with a specific concern about stored state should start at the child document below.

## At a glance

EasyKey persists user settings across versions, so every schema change is a migration event. The one migration document written so far covers the settings file: how schemas are versioned, how upgrades behave, and what happens on rollback. It answers the question a user or engineer asks at upgrade time: what happens to my settings when the app updates?

## Scope and boundaries

A document belongs here when it is a migration guide for user-facing stored state — what changes across versions and how to verify it. Related material with a different home stays there:

- how settings changes gate runtime behavior, rather than storage — that is a decision, in the [decision log](../../architecture/decisions/README.md);
- the current settings schema and behavior — owned by the [product overview](../overview.md);
- how the app is released and rolled back — owned by the [operations](../../operations/README.md) section;
- the supported version matrix — owned by the [compatibility reference](../../reference/compatibility.md).

## Start here

| You want to | Read |
|---|---|
| Know what happens to user settings across versions | [Migration settings](settings.md) |

## Detailed documentation

<!-- docforge-children:start -->
| Document | Answers |
|---|---|
| [Migration settings](settings.md) | What happens to user settings across versions — which schemas are migrated, what changes, and how to verify? |
<!-- docforge-children:end -->

## Related sections

- Parent index: [Product](../README.md)
- Repository docs index: [docs](../../README.md)
