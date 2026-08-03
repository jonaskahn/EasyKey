---
id: "concepts_index"
title: "Architecture concepts"
docforge_provenance:
  schema: "2.0"
  doc_id: "concepts_index"
  path: "docs/architecture/concepts/README.md"
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
        - path: "docs/_archive/TELEX.md"
          role: "doc"
          git_blob: "7a6c47e94add2cf0a95722716c29874a29c7d37b"
      unresolved: []
    - id: "scope-and-boundaries"
      sources:
        - path: "docs/architecture/decisions/README.md"
          role: "doc"
          git_blob: "6f0b80df275ccf5bd2bdf030d5f86daa7d9d18cf"
      unresolved: []
    - id: "start-here"
      sources:
        - path: "docs/_archive/TELEX.md"
          role: "doc"
          git_blob: "7a6c47e94add2cf0a95722716c29874a29c7d37b"
        - path: "docs/architecture/platform-integration.md"
          role: "doc"
          git_blob: "79fced1ae49f8a341d0420ecc16652bea43ab2aa"
      unresolved: []
    - id: "detailed-documentation"
      sources:
        - path: "docs/_archive/TELEX.md"
          role: "doc"
          git_blob: "7a6c47e94add2cf0a95722716c29874a29c7d37b"
      unresolved: []
    - id: "related-sections"
      sources:
        - path: "docs/_archive/TELEX.md"
          role: "doc"
          git_blob: "7a6c47e94add2cf0a95722716c29874a29c7d37b"
      unresolved: []
---
# Architecture concepts

_Last reviewed: 2026-08-03_

This section is where EasyKey's architecture concepts belong: documents that explain a design idea — how something works, why it works that way, and what it buys the project — without diving into a specific decision or implementation detail. It exists so engineers new to the repository can build a mental model of EasyKey before they read structure or rationale documents. No concept documents are written yet; the conceptual material the repository owns today lives in the documents this README routes to.

## At a glance

EasyKey's explanatory material currently has no home in this folder. The de-facto concept home is the [Telex rule set](../../flows/keyboard-typing.md), which defines the core behavioral concept of the app, and the architecture documents in the parent directory, which explain how the pieces fit together and how the app touches the operating system.

## Scope and boundaries

A document belongs here when it is a concept: a mental model or design idea that spans code (for example, how input transformation composes with the clipboard feature, or what "typed locally" means). It does not belong here when it is:

- a specific decision with rationale and tradeoffs — that lives in the [decision log](../decisions/README.md);
- a structural map of modules and their responsibilities — that lives in [high-level](../high-level.md) and [low-level](../low-level.md) architecture;
- a platform integration contract — that lives in [platform integration](../platform-integration.md).

Readers who landed here looking for those should follow the links above.

## Start here

| You want to | Read |
|---|---|
| Understand EasyKey's core typing behavior (Telex) | [Telex rule set](../../flows/keyboard-typing.md) |
| Build a mental model of how the app fits together | [High-level architecture](../high-level.md) |
| Know how EasyKey integrates with macOS services and permissions | [Platform integration](../platform-integration.md) |

## Detailed documentation

<!-- docforge-children:start -->
No concept documents are written yet, and none are selected in this run — an empty section is the honest state, not a missing deliverable. Until a concept document is materialized here, the [Telex rule set](../../flows/keyboard-typing.md) and the [architecture overview](../README.md) are the current homes for conceptual material.
<!-- docforge-children:end -->

## Related sections

- Parent index: [Architecture](../README.md)
- Sibling: [Decision log](../decisions/README.md)
- Repository docs index: [docs](../../README.md)
