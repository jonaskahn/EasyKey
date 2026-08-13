---
id: "architecture_index"
title: "Architecture"
description: "Section overview for architecture: how EasyKey is built, what the reader question each architecture document answers"
docforge_provenance:
  schema: "2.0"
  doc_id: "architecture_index"
  path: "docs/architecture/README.md"
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
    - id: "architecture"
      sources:
        - path: "README.md"
          role: "doc"
          git_blob: "adbd4f30d3c2f11bb855e6645195493a6c6a34f7"
        - path: "docs/architecture/system-overview.md"
          role: "doc"
          git_blob: "bd0032be15a6f3d8478c52e8d5e9a23bd424df48"
      unresolved: []
    - id: "at-a-glance"
      sources:
        - path: "docs/architecture/system-overview.md"
          role: "doc"
          git_blob: "bd0032be15a6f3d8478c52e8d5e9a23bd424df48"
        - path: "docs/architecture/high-level.md"
          role: "doc"
          git_blob: "de19fd5b1baf054a270285ff0a7e30fc35d6fec7"
        - path: "docs/architecture/low-level.md"
          role: "doc"
          git_blob: "614e146d13aa77985d6140b3ad9530861982eac0"
      unresolved: []
    - id: "scope-and-boundaries"
      sources:
        - path: "docs/architecture/high-level.md"
          role: "doc"
          git_blob: "de19fd5b1baf054a270285ff0a7e30fc35d6fec7"
        - path: "docs/architecture/constraints.md"
          role: "doc"
          git_blob: "35b54a3188d12f5479f1409ea5f1da7b7ca87656"
      unresolved: []
    - id: "start-here"
      sources:
        - path: "docs/architecture/system-overview.md"
          role: "doc"
          git_blob: "bd0032be15a6f3d8478c52e8d5e9a23bd424df48"
        - path: "docs/architecture/high-level.md"
          role: "doc"
          git_blob: "de19fd5b1baf054a270285ff0a7e30fc35d6fec7"
        - path: "docs/architecture/constraints.md"
          role: "doc"
          git_blob: "35b54a3188d12f5479f1409ea5f1da7b7ca87656"
        - path: "docs/architecture/dependencies.md"
          role: "doc"
          git_blob: "9d8c0a29953ce9bf4a32c7586709abfd9656561c"
        - path: "docs/architecture/platform-integration.md"
          role: "doc"
          git_blob: "e813aa3dd2fc4c8a50c6f95d132971b8dfd04592"
        - path: "docs/architecture/tech-debt.md"
          role: "doc"
          git_blob: "fd7aaf133fa703b39e1daeed3405c7687f56d5eb"
      unresolved: []
    - id: "detailed-documentation"
      sources:
        - path: "docs/architecture/system-overview.md"
          role: "doc"
          git_blob: "bd0032be15a6f3d8478c52e8d5e9a23bd424df48"
        - path: "docs/architecture/high-level.md"
          role: "doc"
          git_blob: "de19fd5b1baf054a270285ff0a7e30fc35d6fec7"
        - path: "docs/architecture/low-level.md"
          role: "doc"
          git_blob: "614e146d13aa77985d6140b3ad9530861982eac0"
        - path: "docs/architecture/constraints.md"
          role: "doc"
          git_blob: "35b54a3188d12f5479f1409ea5f1da7b7ca87656"
        - path: "docs/architecture/dependencies.md"
          role: "doc"
          git_blob: "9d8c0a29953ce9bf4a32c7586709abfd9656561c"
        - path: "docs/architecture/application-lifecycle.md"
          role: "doc"
          git_blob: "9024d2bd455d5a8ae1b95038ce53a907df973cf9"
        - path: "docs/architecture/platform-integration.md"
          role: "doc"
          git_blob: "e813aa3dd2fc4c8a50c6f95d132971b8dfd04592"
        - path: "docs/architecture/ai-integration.md"
          role: "doc"
          git_blob: "feb58f0fe5f5316737048614eee12cc48a200c95"
        - path: "docs/architecture/ui-and-state.md"
          role: "doc"
          git_blob: "cfda40ef28c9cd09af3bc8839d0539058c554353"
        - path: "docs/architecture/tech-debt.md"
          role: "doc"
          git_blob: "fd7aaf133fa703b39e1daeed3405c7687f56d5eb"
        - path: "docs/architecture/concepts/README.md"
          role: "doc"
          git_blob: "7f4c435022ed209357ce5b9a50ca9e2899668396"
        - path: "docs/architecture/decisions/README.md"
          role: "doc"
          git_blob: "ad8debde7e8cd020a9daf7e45a19dbf49cc933d9"
      unresolved: []
    - id: "related-sections"
      sources:
        - path: "docs/README.md"
          role: "doc"
          git_blob: "f46130b93e8bd0bfe43446dd7d42555ae5133400"
        - path: "docs/product/README.md"
          role: "doc"
          git_blob: "8b0a110385acc2e7c591170207db31394e216007"
        - path: "docs/engineering/README.md"
          role: "doc"
          git_blob: "eb772ae315052f41c6bd2267dbc0886260ba0447"
        - path: "docs/reference/README.md"
          role: "doc"
          git_blob: "9f1b4e19d4bea1b2eaaa8bec65db8b75f160b7be"
        - path: "docs/security/README.md"
          role: "doc"
          git_blob: "ab0ce417c4410bdd0685d53be13089243bccb2be"
      unresolved: []
---
# Architecture

_Last reviewed: 2026-08-13_

EasyKey is a macOS menu-bar utility that converts keystrokes into Vietnamese text (Telex, Simple Telex, VNI), keeps a private clipboard history, and translates selected or typed text on-device or through opt-in cloud providers. This section is where engineers learn how the system is put together — its shape, its components, the constraints that bind it, and the platform services it leans on. Newcomers start here to build a mental model of the codebase; engineers returning to plan a change use it to find the one document that owns the detail they need.

## At a glance

The architecture hangs together as one menu-bar app plus an embedded login helper, built from three runtime layers: `EasyKeyApp` (shell, UI, coordination), `EasyKeyKit` (keyboard event tap, input pipeline, Accessibility text synthesis), and `EasyEngineCore` (framework-free domain logic). A system overview ties the major capabilities to the components and the primary end-to-end path; high- and low-level documents then decompose the shape, and one facet document each covers constraints, dependencies, lifecycle, platform integration, AI translation, UI state, and known debt. Cross-cutting material — design concepts and recorded decisions — lives in the two nested indexes below.

## Scope and boundaries

This section owns *how the system is built*: structure, constraints, dependencies, lifecycle, platform integration, AI integration, UI state, and technical debt. It does not own the product story (what EasyKey does and who it is for — see [product](../product/README.md)), the engineering workflow (setup, testing, release — see [engineering](../engineering/README.md)), or the security posture (threats, data handling, permissions — see [security](../security/README.md)). Facts that a child document owns — a specific constraint, dependency, or platform requirement — are stated in that document, never restated here.

## Start here

| You want to | Read |
|---|---|
| Build the end-to-end mental model of the system first | [system-overview.md](system-overview.md) |
| Understand the system shape, actors, and main containers | [high-level.md](high-level.md) |
| See the component-level decomposition and runtime boundaries | [low-level.md](low-level.md) |
| Know the hard limits and deliberate non-goals before proposing something new | [constraints.md](constraints.md) |
| Check what the app depends on and what a dependency failure costs | [dependencies.md](dependencies.md) |
| Understand how typing and translation behave per OS service | [platform-integration.md](platform-integration.md) |
| Review deferred work before planning a change | [tech-debt.md](tech-debt.md) |

## Detailed documentation

<!-- docforge-children:start -->
| Document | Answers |
|---|---|
| [System overview](system-overview.md) | What are EasyKey's major capabilities, which components does each touch, and what is the primary end-to-end path through the system? |
| [High-level architecture](high-level.md) | What is EasyKey's overall shape — the actors around it, the boundaries between them, and the main containers it is built from? |
| [Low-level architecture](low-level.md) | How are the components inside each container organized, and where do the runtime boundaries fall? |
| [Architectural constraints](constraints.md) | What hard limits does this architecture impose by design, and what does it deliberately not do? |
| [Dependencies and integrations](dependencies.md) | What does the repository depend on — runtime libraries, platform SDKs, development tooling — and what happens if a dependency disappears? |
| [Application lifecycle](application-lifecycle.md) | How does the app launch, run, sleep, and terminate — and who owns each lifecycle state? |
| [Platform integration](platform-integration.md) | Which macOS services does EasyKey integrate, what does each one require, and how does behavior degrade when a service is unavailable? |
| [AI integration](ai-integration.md) | What reaches a translation model, through which provider, and how are prompts, outputs, and failures handled? |
| [UI navigation and state](ui-and-state.md) | What are the app's UI surfaces, how do they navigate between each other, and who owns the state behind them? |
| [Technical debt](tech-debt.md) | Which known shortcuts and deferred work exist, what does each cost, and how will it be paid down? |
| [Architecture concepts](concepts/README.md) | Where do EasyKey's design concepts live — and which documents own that material while the folder is empty? |
| [Decision log](decisions/README.md) | Which architecture decisions has EasyKey recorded, what does each one commit the project to, and how do their statuses evolve? |
<!-- docforge-children:end -->

## Related sections

- [Documentation home](../README.md) — the parent index of all sections.
- [Product](../product/README.md) — what EasyKey does and who it is for.
- [Engineering](../engineering/README.md) — setup, testing, conventions, and release for working on this architecture.
- [Reference](../reference/README.md) — configuration, glossary, and compatibility facts the design depends on.
- [Security](../security/README.md) — the threat model, data handling, and permissions that constrain the design.
