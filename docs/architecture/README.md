# Architecture

_Last reviewed: 2026-08-15_

EasyKey is a macOS menu-bar utility that converts keystrokes into Vietnamese text (Telex, Simple Telex, VNI), keeps a private clipboard history, and translates selected or typed text on-device or through opt-in cloud providers. This section is where engineers learn how the system is put together — its shape, its components, and the platform services it leans on. Newcomers start here to build a mental model of the codebase; engineers returning to plan a change use it to find the one document that owns the detail they need.

## At a glance

EasyKey is built from five deployable pieces — three in-process Swift targets (`EasyKeyApp` for shell, UI, and coordination; `EasyKeyKit` for the keyboard event tap, input pipeline, and Accessibility text synthesis; `EasyEngineCore` for framework-free domain logic), an embedded login helper, and the bundled Sparkle updater framework. A system overview ties the major capabilities to the components and the primary end-to-end path; the high-level document then decomposes the shape; and one facet document each covers lifecycle, platform integration, AI translation, UI state, and persistence.

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
- [Reference](../reference/README.md) — configuration, compatibility, and limitation facts the design depends on.
- [Security](../security/README.md) — the threat model, data handling, and permissions that constrain the design.
