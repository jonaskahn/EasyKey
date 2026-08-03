---
id: "architecture_index"
title: "Architecture"
docforge_provenance:
  schema: "2.0"
  doc_id: "architecture_index"
  path: "docs/architecture/README.md"
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
    - id: "architecture"
      sources:
        - path: "README.md"
          role: "doc"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
        - path: "docs/architecture/high-level.md"
          role: "doc"
          git_blob: "21b00d82556b34edc6c5cb528d908189c6cf16dc"
      unresolved: []
    - id: "at-a-glance"
      sources:
        - path: "docs/architecture/high-level.md"
          role: "doc"
          git_blob: "21b00d82556b34edc6c5cb528d908189c6cf16dc"
        - path: "docs/architecture/low-level.md"
          role: "doc"
          git_blob: "07e35af42b03a7e7cbfb0d9e201fa7f44a05606b"
        - path: "docs/architecture/constraints.md"
          role: "doc"
          git_blob: "d57bfc3d6113872611941d5248978223c80a3bad"
      unresolved: []
    - id: "scope-and-boundaries"
      sources:
        - path: "docs/architecture/high-level.md"
          role: "doc"
          git_blob: "21b00d82556b34edc6c5cb528d908189c6cf16dc"
        - path: "docs/architecture/low-level.md"
          role: "doc"
          git_blob: "07e35af42b03a7e7cbfb0d9e201fa7f44a05606b"
      unresolved: []
    - id: "start-here"
      sources:
        - path: "docs/architecture/high-level.md"
          role: "doc"
          git_blob: "21b00d82556b34edc6c5cb528d908189c6cf16dc"
        - path: "docs/architecture/low-level.md"
          role: "doc"
          git_blob: "07e35af42b03a7e7cbfb0d9e201fa7f44a05606b"
        - path: "docs/architecture/constraints.md"
          role: "doc"
          git_blob: "d57bfc3d6113872611941d5248978223c80a3bad"
        - path: "docs/architecture/tech-debt.md"
          role: "doc"
          git_blob: "413d6c52fc6560568453ef5b6cb6f5dcbf78e575"
      unresolved: []
    - id: "detailed-documentation"
      sources:
        - path: "docs/architecture/high-level.md"
          role: "doc"
          git_blob: "21b00d82556b34edc6c5cb528d908189c6cf16dc"
        - path: "docs/architecture/low-level.md"
          role: "doc"
          git_blob: "07e35af42b03a7e7cbfb0d9e201fa7f44a05606b"
        - path: "docs/architecture/constraints.md"
          role: "doc"
          git_blob: "d57bfc3d6113872611941d5248978223c80a3bad"
        - path: "docs/architecture/dependencies.md"
          role: "doc"
          git_blob: "57ccd8a6934d1a14011cac08adc2715af63beba4"
        - path: "docs/architecture/tech-debt.md"
          role: "doc"
          git_blob: "413d6c52fc6560568453ef5b6cb6f5dcbf78e575"
        - path: "docs/architecture/application-lifecycle.md"
          role: "doc"
          git_blob: "7f145e5e1b1be924669ef18d6b5e560b00642ed2"
        - path: "docs/architecture/ai-integration.md"
          role: "doc"
          git_blob: "0cedabd59468545a1a58c9cfbe856dc40604e0e5"
        - path: "docs/architecture/ui-and-state.md"
          role: "doc"
          git_blob: "5f9cb72d5660b285af3db21136eb33b2350d28ee"
        - path: "docs/architecture/platform-integration.md"
          role: "doc"
          git_blob: "79fced1ae49f8a341d0420ecc16652bea43ab2aa"
        - path: "docs/architecture/concepts/README.md"
          role: "doc"
          git_blob: "95a8e6b48746a7d8bf2755392e95153b1d839438"
      unresolved: []
    - id: "related-sections"
      sources:
        - path: "docs/engineering/README.md"
          role: "doc"
          git_blob: "7363e3a9e0edd2b57706aa64e4ef319af6728bc6"
      unresolved: []
---
# Architecture

_Last reviewed: 2026-08-03_

EasyKey is a macOS menu-bar utility that converts keystrokes into Vietnamese text (Telex, Simple Telex, VNI), keeps a private clipboard history, and translates selected or typed text on-device or through opt-in cloud providers. This section is where engineers learn how the system is put together: its shape, its components, the constraints that bind it, and the platform services it leans on. Newcomers can start here to build a mental model of the codebase; engineers returning to plan a change can use it to find the one document that owns the detail they need.

## At a glance

The architecture hangs together as one menu-bar app plus an embedded login helper, built from three runtime layers: `EasyKeyApp` (shell, UI, coordination), `EasyKeyKit` (keyboard event tap, input pipeline, Accessibility text replacement), and `EasyEngineCore` (framework-free domain logic). The hard boundaries are enforced ceilings — macOS 14 minimum, Accessibility trust for the whole typing feature, device-only Keychain storage, no telemetry — and the runtime dependency surface is deliberately small (Sparkle for signed updates, Apple SDKs for everything else). The detailed documents below each own one facet: shape, components, limits, dependencies, lifecycle, platform integrations, AI translation, UI state, and known debt.

## Scope and boundaries

This section owns *how the system is built*: structure, constraints, dependencies, lifecycle, platform integration, AI integration, UI state, and technical debt. It does not own the product story (what EasyKey does and who it is for — see [product](../product/README.md)), the engineering workflow (setup, testing, release — see [engineering](../engineering/README.md)), or the security posture (threats, data handling, permissions — see [security](../security/README.md)). Facts about specific settings, terms, or platform minimums are owned by the documents that name them and are never restated here.

## Start here

| You want to | Read |
|---|---|
| Understand the system shape, actors, and main containers first | [high-level.md](high-level.md) |
| See the component-level decomposition and runtime boundaries | [low-level.md](low-level.md) |
| Know the hard limits and deliberate non-goals before proposing something new | [constraints.md](constraints.md) |
| Check what the app depends on and what a dependency failure costs | [dependencies.md](dependencies.md) |
| Understand how typing and translation behave per OS service | [platform-integration.md](platform-integration.md) |
| Review deferred work before planning a change | [tech-debt.md](tech-debt.md) |

## Detailed documentation

<!-- docforge-children:start -->
| Document | Answers |
|---|---|
| [High-level architecture](high-level.md) | What is EasyKey's overall shape — the actors around it, the boundaries between them, and the main containers it is built from? |
| [Low-level architecture](low-level.md) | How are the components inside each container organized, and where do the runtime boundaries fall? |
| [Architectural constraints](constraints.md) | What hard limits does this architecture impose by design, and what does it deliberately not do? |
| [Dependencies and integrations](dependencies.md) | What does the repository depend on — runtime libraries, platform SDKs, development tooling, external services — and what happens if a dependency disappears? |
| [Application lifecycle](application-lifecycle.md) | How does the app launch, run, sleep, and terminate — and who owns each lifecycle state? |
| [Platform integration](platform-integration.md) | Which OS services does EasyKey actually integrate, what does each one require, and what happens when a service is unavailable? |
| [AI integration](ai-integration.md) | What reaches a translation model, through which provider, and what happens to the result? |
| [UI navigation and state](ui-and-state.md) | How do the app's five surfaces navigate between each other, and who owns the state behind them? |
| [Technical debt](tech-debt.md) | Which known shortcuts and deferred work exist, what does each cost, and how will it be paid down? |
| [Architecture concepts](concepts/README.md) | Where does EasyKey's concept material live — the design ideas that explain how something works and what it buys the project — and what is its de-facto home today? |
| [Decision log](decisions/README.md) | Which architecture decisions has EasyKey recorded, what does each one commit the project to, and how do their statuses evolve? |
<!-- docforge-children:end -->

## Related sections

- [Documentation home](../README.md) — the parent index of all sections.
- [Engineering](../engineering/README.md) — setup, testing, conventions, and release for working on this architecture.
- [Security](../security/README.md) — the threat model, data handling, and permissions that constrain the design.
- [Reference](../reference/README.md) — configuration, glossary, and platform compatibility lookups used alongside this section.
