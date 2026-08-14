---
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
          git_blob: "77d1fd7a19d15e9729a45f1a91db94e4107ae426"
          git_blob_normalized: "77d1fd7a19d15e9729a45f1a91db94e4107ae426"
          role: "doc"
        - path: "docs/product/migrations/settings.md"
          git_blob: "6b5e3ac1931df9d8127d5b4908a5ed4850053b7f"
          git_blob_normalized: "6b5e3ac1931df9d8127d5b4908a5ed4850053b7f"
          role: "doc"
      unresolved: []
    - id: "at-a-glance"
      sources:
        - path: "docs/product/migrations/settings.md"
          git_blob: "6b5e3ac1931df9d8127d5b4908a5ed4850053b7f"
          git_blob_normalized: "6b5e3ac1931df9d8127d5b4908a5ed4850053b7f"
          role: "doc"
      unresolved: []
    - id: "scope-and-boundaries"
      sources:
        - path: "docs/product/migrations/settings.md"
          git_blob: "6b5e3ac1931df9d8127d5b4908a5ed4850053b7f"
          git_blob_normalized: "6b5e3ac1931df9d8127d5b4908a5ed4850053b7f"
          role: "doc"
        - path: "docs/operations/README.md"
          git_blob: "aad2922a8ab386e2c86773d2e060cdbd3c3afc1e"
          git_blob_normalized: "aad2922a8ab386e2c86773d2e060cdbd3c3afc1e"
          role: "doc"
        - path: "docs/reference/compatibility.md"
          git_blob: "1f5b0bb065e1eab0749db6d7961f3229fbc95fd6"
          git_blob_normalized: "1f5b0bb065e1eab0749db6d7961f3229fbc95fd6"
          role: "doc"
      unresolved: []
    - id: "start-here"
      sources:
        - path: "docs/product/migrations/settings.md"
          git_blob: "6b5e3ac1931df9d8127d5b4908a5ed4850053b7f"
          git_blob_normalized: "6b5e3ac1931df9d8127d5b4908a5ed4850053b7f"
          role: "doc"
      unresolved: []
    - id: "detailed-documentation"
      sources:
        - path: "docs/product/migrations/settings.md"
          git_blob: "6b5e3ac1931df9d8127d5b4908a5ed4850053b7f"
          git_blob_normalized: "6b5e3ac1931df9d8127d5b4908a5ed4850053b7f"
          role: "doc"
      unresolved: []
    - id: "related-sections"
      sources:
        - path: "docs/product/README.md"
          git_blob: "77d1fd7a19d15e9729a45f1a91db94e4107ae426"
          git_blob_normalized: "77d1fd7a19d15e9729a45f1a91db94e4107ae426"
          role: "doc"
        - path: "docs/README.md"
          git_blob: "4e9392f1d88c919a51368d4ed091365f24ecbea8"
          git_blob_normalized: "4e9392f1d88c919a51368d4ed091365f24ecbea8"
          role: "doc"
      unresolved: []
---
# Migrations

_Last reviewed: 2026-08-15_

This section documents what happens to a user's data and preferences when EasyKey moves between versions — which stored shapes change, what is upgraded automatically, what is lost, and how to verify the migration. It exists so engineers shipping a breaking change and users upgrading across versions can both find out what to expect. The reader with a specific concern about stored state should start at the child document below.

## At a glance

EasyKey persists user settings across versions, so every schema change is a migration event. The one migration document written so far covers the settings file: how schemas are versioned, how upgrades behave, and what happens on rollback. It answers the question a user or engineer asks at upgrade time: what happens to my settings when the app updates?

## Scope and boundaries

A document belongs here when it is a migration guide for user-facing stored state — what changes across versions and how to verify it. Related material with a different home stays there:

- the current settings schema and behavior — owned by the [product overview](../overview.md);
- how the released artifact is deployed and distributed across channels — owned by the [operations](../../operations/README.md) section;
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
