---
id: "library_migrations_index"
title: "Migrations"
docforge_provenance:
  schema: "2.0"
  doc_id: "library_migrations_index"
  path: "docs/product/migrations/README.md"
  generated_at: "2026-08-03T09:24:12Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "orientation"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "at-a-glance"
      sources:
        - path: "docs/product/migrations/settings.md"
          role: "doc"
          git_blob: "e408fbece88b11d33b5de5b2c7aef076ffb20cfb"
      unresolved: []
    - id: "scope-and-boundaries"
      sources:
        - path: "docs/product/migrations/settings.md"
          role: "doc"
          git_blob: "e408fbece88b11d33b5de5b2c7aef076ffb20cfb"
      unresolved: []
    - id: "start-here"
      sources:
        - path: "docs/product/migrations/settings.md"
          role: "doc"
          git_blob: "e408fbece88b11d33b5de5b2c7aef076ffb20cfb"
      unresolved: []
    - id: "detailed-documentation"
      sources:
        - path: "docs/product/migrations/settings.md"
          role: "doc"
          git_blob: "e408fbece88b11d33b5de5b2c7aef076ffb20cfb"
      unresolved: []
    - id: "related-sections"
      sources:
        - path: "docs/product/migrations/settings.md"
          role: "doc"
          git_blob: "e408fbece88b11d33b5de5b2c7aef076ffb20cfb"
      unresolved: []
---
# Migrations

_Last reviewed: 2026-08-03_

This section documents what happens to a user's data and preferences when EasyKey moves between versions — which stored shapes change, what is upgraded automatically, what is lost, and how to verify the migration. It exists so engineers shipping a breaking change and users upgrading across versions can both find out what to expect. The reader with a specific concern about stored state should start at the child document below.

## At a glance

EasyKey persists user settings across versions, so every schema change is a migration event. The one migration document written so far covers the settings file: how schemas are versioned, how upgrades behave, and what happens on rollback. The document answers the question a user or engineer asks at upgrade time: what happens to my settings when the app updates?

## Scope and boundaries

A document belongs here when it is a migration guide for user-facing stored state — what changes across versions and how to verify it. Related material with a different home stays there:

- how settings changes gate runtime behavior, rather than storage — that is a decision, in the [decision log](../../architecture/decisions/README.md);
- the current settings schema and behavior — owned by the [product overview](../README.md) section;
- how the app is released and rolled back — owned by the [operations](../../operations/README.md) section.

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
