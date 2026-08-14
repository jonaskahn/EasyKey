---
id: "concepts_index"
title: "Architecture concepts"
description: "Section overview for architecture concepts: what concepts are, scope, and the reader question each concept answers"
docforge_provenance:
  schema: "2.0"
  doc_id: "concepts_index"
  path: "docs/architecture/concepts/README.md"
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
    - id: "architecture-concepts"
      sources:
        - path: "docs/architecture/README.md"
          role: "doc"
          git_blob: "620a661337c9a4371fd2c8869d87d7c2a9565886"
          git_blob_normalized: "620a661337c9a4371fd2c8869d87d7c2a9565886"
      unresolved: []
    - id: "at-a-glance"
      sources:
        - path: "docs/architecture/README.md"
          role: "doc"
          git_blob: "620a661337c9a4371fd2c8869d87d7c2a9565886"
          git_blob_normalized: "620a661337c9a4371fd2c8869d87d7c2a9565886"
      unresolved: []
    - id: "scope-and-boundaries"
      sources:
        - path: "docs/architecture/README.md"
          role: "doc"
          git_blob: "620a661337c9a4371fd2c8869d87d7c2a9565886"
          git_blob_normalized: "620a661337c9a4371fd2c8869d87d7c2a9565886"
        - path: "docs/architecture/decisions/README.md"
          role: "doc"
          git_blob: "c3262ff98548a8a04c6955900fe355025ab649d5"
          git_blob_normalized: "c3262ff98548a8a04c6955900fe355025ab649d5"
        - path: "docs/flows/README.md"
          role: "doc"
          git_blob: "83492bedf226fa49c62e8290fd14fd6fe6b62f89"
      unresolved: []
    - id: "start-here"
      sources:
        - path: "docs/flows/keyboard-typing.md"
          role: "doc"
          git_blob: "7f6cbe5904aba625eefd8c3b826e64c9614ee76f"
        - path: "docs/architecture/system-overview.md"
          role: "doc"
          git_blob: "cbe348cefa7414187e483c42bfd778ed95b47aa4"
          git_blob_normalized: "cbe348cefa7414187e483c42bfd778ed95b47aa4"
        - path: "docs/architecture/high-level.md"
          role: "doc"
          git_blob: "ac229c696ba34750987a45df2e80762926d77a01"
          git_blob_normalized: "ac229c696ba34750987a45df2e80762926d77a01"
        - path: "docs/architecture/platform-integration.md"
          role: "doc"
          git_blob: "d7ee4e97a03ce5b07090b876f65ef790fa4b4eb7"
          git_blob_normalized: "d7ee4e97a03ce5b07090b876f65ef790fa4b4eb7"
      unresolved: []
    - id: "detailed-documentation"
      sources:
        - path: "docs/flows/keyboard-typing.md"
          role: "doc"
          git_blob: "7f6cbe5904aba625eefd8c3b826e64c9614ee76f"
        - path: "docs/architecture/platform-integration.md"
          role: "doc"
          git_blob: "d7ee4e97a03ce5b07090b876f65ef790fa4b4eb7"
          git_blob_normalized: "d7ee4e97a03ce5b07090b876f65ef790fa4b4eb7"
      unresolved: []
    - id: "related-sections"
      sources:
        - path: "docs/README.md"
          role: "doc"
          git_blob: "c26bf46583357c8db29f627fbc0deb41cd7df290"
          git_blob_normalized: "c26bf46583357c8db29f627fbc0deb41cd7df290"
      unresolved: []
---
# Architecture concepts

_Last reviewed: 2026-08-14_

This section is where EasyKey's architecture concepts belong: documents that explain a design idea — how something works, why it works that way, and what it buys the project — without the step-level detail of a flow or the rationale of a decision record. It exists so engineers can build a mental model of EasyKey's design before reading the structural or behavioral documents. No concept documents exist in this folder yet; until one materializes, this README routes readers to the sections that currently own that material.

## At a glance

The folder is currently empty: no concept document is written, selected, or materialized here. The design ideas that would live in this section are distributed across the repository — the typing behavior is documented as a flow, the system shape as architecture documents, and the OS integration as a platform contract — so this README routes to those homes rather than restating them.

## Scope and boundaries

A document belongs here when it is a concept: a mental model or design idea that spans code, for example how input transformation composes with the clipboard feature, or what "typed locally" means. It does not belong here when it is:

- a specific decision with rationale and tradeoffs — that lives in the [decision log](../decisions/README.md);
- a structural map of modules and their responsibilities — that lives in [high-level](../high-level.md) and [low-level](../low-level.md) architecture;
- a platform integration contract — that lives in [platform integration](../platform-integration.md);
- a behavioral rule set with ordered steps — that lives in the [flows](../../flows/README.md) section.

Readers who landed here looking for those should follow the links above.

## Start here

| You want to | Read |
|---|---|
| Understand EasyKey's core typing behavior (Telex, Simple Telex, VNI) | [Keyboard typing flow](../../flows/keyboard-typing.md) |
| Build a mental model of how the app fits together | [System overview](../system-overview.md) and [High-level architecture](../high-level.md) |
| Know how EasyKey integrates with macOS services and permissions | [Platform integration](../platform-integration.md) |

## Detailed documentation

<!-- docforge-children:start -->
No concept documents are written yet, and none are selected in this run — an empty section is the honest state, not a missing deliverable. When a concept document is materialized in this folder, it will be listed here. Until then, the conceptual material the repository owns lives in the [keyboard typing flow](../../flows/keyboard-typing.md) and the [platform integration](../platform-integration.md) documents above.
<!-- docforge-children:end -->

## Related sections

- Parent index: [Architecture](../README.md)
- Sibling: [Decision log](../decisions/README.md)
- Repository docs index: [docs](../../README.md)
