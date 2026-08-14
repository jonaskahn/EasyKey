---
id: "architecture_index"
title: "Architecture"
description: "What the system is and how it is built: section overview and one-line purpose of every selected architecture document"
docforge_provenance:
  schema: "2.0"
  doc_id: "architecture_index"
  path: "docs/architecture/README.md"
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
    - id: "architecture"
      sources:
        - path: "README.md"
          git_blob: "8fc7891befa21173acaaaf1b19c8c30ad6bb3f97"
          git_blob_normalized: "8fc7891befa21173acaaaf1b19c8c30ad6bb3f97"
          role: "doc"
        - path: "docs/architecture/system-overview.md"
          git_blob: "a0bb86e2523d4bbd0fe2c74fe4ff1433c935d882"
          git_blob_normalized: "a0bb86e2523d4bbd0fe2c74fe4ff1433c935d882"
          role: "doc"
      unresolved: []
    - id: "at-a-glance"
      sources:
        - path: "docs/architecture/system-overview.md"
          git_blob: "a0bb86e2523d4bbd0fe2c74fe4ff1433c935d882"
          git_blob_normalized: "a0bb86e2523d4bbd0fe2c74fe4ff1433c935d882"
          role: "doc"
        - path: "docs/architecture/high-level.md"
          git_blob: "512ee6424ad536435918e38036388604946f544e"
          git_blob_normalized: "512ee6424ad536435918e38036388604946f544e"
          role: "doc"
        - path: "docs/architecture/persistence.md"
          git_blob: "e46213444d15c76b35f86de2ef7db2b9d8268608"
          git_blob_normalized: "e46213444d15c76b35f86de2ef7db2b9d8268608"
          role: "doc"
      unresolved: []
    - id: "scope-and-boundaries"
      sources:
        - path: "docs/architecture/high-level.md"
          git_blob: "512ee6424ad536435918e38036388604946f544e"
          git_blob_normalized: "512ee6424ad536435918e38036388604946f544e"
          role: "doc"
      unresolved: []
    - id: "start-here"
      sources:
        - path: "docs/architecture/system-overview.md"
          git_blob: "a0bb86e2523d4bbd0fe2c74fe4ff1433c935d882"
          git_blob_normalized: "a0bb86e2523d4bbd0fe2c74fe4ff1433c935d882"
          role: "doc"
        - path: "docs/architecture/high-level.md"
          git_blob: "512ee6424ad536435918e38036388604946f544e"
          git_blob_normalized: "512ee6424ad536435918e38036388604946f544e"
          role: "doc"
        - path: "docs/architecture/platform-integration.md"
          git_blob: "cc8480d794d39a27c9e7ca1aecfad307ee80a8d2"
          git_blob_normalized: "cc8480d794d39a27c9e7ca1aecfad307ee80a8d2"
          role: "doc"
        - path: "docs/architecture/persistence.md"
          git_blob: "e46213444d15c76b35f86de2ef7db2b9d8268608"
          git_blob_normalized: "e46213444d15c76b35f86de2ef7db2b9d8268608"
          role: "doc"
      unresolved: []
    - id: "detailed-documentation"
      sources:
        - path: "docs/architecture/system-overview.md"
          git_blob: "a0bb86e2523d4bbd0fe2c74fe4ff1433c935d882"
          git_blob_normalized: "a0bb86e2523d4bbd0fe2c74fe4ff1433c935d882"
          role: "doc"
        - path: "docs/architecture/high-level.md"
          git_blob: "512ee6424ad536435918e38036388604946f544e"
          git_blob_normalized: "512ee6424ad536435918e38036388604946f544e"
          role: "doc"
        - path: "docs/architecture/application-lifecycle.md"
          git_blob: "98017e73689d8fb87c6fc2d89419a4ca0cb17b18"
          git_blob_normalized: "98017e73689d8fb87c6fc2d89419a4ca0cb17b18"
          role: "doc"
        - path: "docs/architecture/platform-integration.md"
          git_blob: "cc8480d794d39a27c9e7ca1aecfad307ee80a8d2"
          git_blob_normalized: "cc8480d794d39a27c9e7ca1aecfad307ee80a8d2"
          role: "doc"
        - path: "docs/architecture/ai-integration.md"
          git_blob: "fe8054f2655c3bf9463f340b08713666924eaca8"
          git_blob_normalized: "fe8054f2655c3bf9463f340b08713666924eaca8"
          role: "doc"
        - path: "docs/architecture/ui-and-state.md"
          git_blob: "b37da77e8ea9b625ac6b5bea3686cf745c2ad40c"
          git_blob_normalized: "b37da77e8ea9b625ac6b5bea3686cf745c2ad40c"
          role: "doc"
        - path: "docs/architecture/persistence.md"
          git_blob: "e46213444d15c76b35f86de2ef7db2b9d8268608"
          git_blob_normalized: "e46213444d15c76b35f86de2ef7db2b9d8268608"
          role: "doc"
      unresolved: []
    - id: "related-sections"
      sources:
        - path: "docs/engineering/README.md"
          git_blob: "0982c0df662c1aa9f7a27cf676c9e3b5463e2772"
          git_blob_normalized: "0982c0df662c1aa9f7a27cf676c9e3b5463e2772"
          role: "doc"
        - path: "docs/security/README.md"
          git_blob: "0a7eef592c415a83e7206e07e13fb409f5962aad"
          git_blob_normalized: "0a7eef592c415a83e7206e07e13fb409f5962aad"
          role: "doc"
      unresolved: []
---
# Architecture

_Last reviewed: 2026-08-15_

EasyKey is a macOS menu-bar utility that converts keystrokes into Vietnamese text (Telex, Simple Telex, VNI), keeps a private clipboard history, and translates selected or typed text on-device or through opt-in cloud providers. This section is where engineers learn how the system is put together — its shape, its components, and the platform services it leans on. Newcomers start here to build a mental model of the codebase; engineers returning to plan a change use it to find the one document that owns the detail they need.

## At a glance

The architecture hangs together as one menu-bar app plus an embedded login helper, built from three runtime layers: `EasyKeyApp` (shell, UI, coordination), `EasyKeyKit` (keyboard event tap, input pipeline, Accessibility text synthesis), and `EasyEngineCore` (framework-free domain logic). A system overview ties the major capabilities to the components and the primary end-to-end path; the high-level document then decomposes the shape, and one facet document each covers lifecycle, platform integration, AI translation, UI state, and persistence.

## Scope and boundaries

This section owns *how the system is built*: structure, lifecycle, platform integration, AI integration, UI state, and persistence. It does not own the product story (what EasyKey does and who it is for — see [product](../product/README.md)), the engineering workflow (setup, testing, release — see [engineering](../engineering/README.md)), or the security posture (threats, data handling, permissions — see [security](../security/README.md)). Facts that a child document owns — a specific platform requirement or lifecycle detail — are stated in that document, never restated here.

## Start here

| You want to | Read |
|---|---|
| Build the end-to-end mental model of the system first | [system-overview.md](system-overview.md) |
| Understand the system shape, actors, and main containers | [high-level.md](high-level.md) |
| Understand how typing and translation behave per OS service | [platform-integration.md](platform-integration.md) |
| Understand how the app's state is stored, written, and recovered | [persistence.md](persistence.md) |

## Detailed documentation

<!-- docforge-children:start -->
| Document | Answers |
|---|---|
| [System overview](system-overview.md) | What are EasyKey's major capabilities, which components does each touch, and what is the primary end-to-end path through the system? |
| [High-level architecture](high-level.md) | What is EasyKey's overall shape — the actors around it, the boundaries between them, and the main containers it is built from? |
| [Application lifecycle](application-lifecycle.md) | How does the app launch, run, sleep, and terminate — and who owns each lifecycle state? |
| [Platform integration](platform-integration.md) | Which macOS services does EasyKey integrate, what does each one require, and how does behavior degrade when a service is unavailable? |
| [AI integration](ai-integration.md) | What reaches a translation model, through which provider, and how are prompts, outputs, and failures handled? |
| [UI navigation and state](ui-and-state.md) | What are the app's UI surfaces, how do they navigate between each other, and who owns the state behind them? |
| [Persistence](persistence.md) | How is EasyKey's state persisted — which stores exist, how each is written, and how are failures recovered? |
<!-- docforge-children:end -->

## Related sections

- README — the parent index of all sections.
- [Product](../product/README.md) — what EasyKey does and who it is for.
- [Engineering](../engineering/README.md) — setup, testing, conventions, and release for working on this architecture.
- [Reference](../reference/README.md) — configuration, glossary, and compatibility facts the design depends on.
- [Security](../security/README.md) — the threat model, data handling, and permissions that constrain the design.
