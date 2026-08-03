---
id: "docs_index"
title: "Documentation"
docforge_provenance:
  schema: "2.0"
  doc_id: "docs_index"
  path: "docs/README.md"
  generated_at: "2026-08-03T09:24:40Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "orientation"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "documentation"
      sources:
        - path: "README.md"
          role: "doc"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
      unresolved: []
    - id: "at-a-glance"
      sources:
        - path: "docs/product/README.md"
          role: "doc"
          git_blob: "8b0a110385acc2e7c591170207db31394e216007"
        - path: "docs/architecture/README.md"
          role: "doc"
          git_blob: "be324cfd1a847e1b3c9162f9196e9be1fd526347"
      unresolved: []
    - id: "start-here"
      sources:
        - path: "docs/engineering/setup.md"
          role: "doc"
          git_blob: "90feaba9f2abd75bf4358df2a134f606284158b0"
        - path: "docs/engineering/testing.md"
          role: "doc"
          git_blob: "7a094e2c60f68ffca552947082f4330c2806213a"
      unresolved: []
    - id: "sections"
      sources:
        - path: "docs/flows/README.md"
          role: "doc"
          git_blob: "83492bedf226fa49c62e8290fd14fd6fe6b62f89"
        - path: "docs/engineering/README.md"
          role: "doc"
          git_blob: "7363e3a9e0edd2b57706aa64e4ef319af6728bc6"
        - path: "docs/reference/README.md"
          role: "doc"
          git_blob: "9f1b4e19d4bea1b2eaaa8bec65db8b75f160b7be"
        - path: "docs/operations/README.md"
          role: "doc"
          git_blob: "aec2487a702a755dcfd080d0d8921cbe0b3bb2bf"
        - path: "docs/security/README.md"
          role: "doc"
          git_blob: "ab0ce417c4410bdd0685d53be13089243bccb2be"
        - path: "docs/contributing/README.md"
          role: "doc"
          git_blob: "da7dd1a8bd73ce72867c8e4aef11ff072a48fab3"
      unresolved: []
    - id: "related-root-documents"
      sources:
        - path: "README.md"
          role: "doc"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
        - path: "SECURITY.md"
          role: "doc"
          git_blob: "78ad7c334008aae424b719a5a6134e1a0cb96707"
        - path: "CONTRIBUTING.md"
          role: "doc"
          git_blob: "3b545b144069179a806154b7c57e9bdd42205e58"
        - path: "CHANGELOG.md"
          role: "doc"
          git_blob: "2da41e48235762ea13ff11b79fe8553d7df2ff96"
      unresolved: []
    - id: "conventions"
      sources:
        - path: "docs/flows/README.md"
          role: "doc"
          git_blob: "83492bedf226fa49c62e8290fd14fd6fe6b62f89"
        - path: "docs/contributing/README.md"
          role: "doc"
          git_blob: "da7dd1a8bd73ce72867c8e4aef11ff072a48fab3"
      unresolved: []
    - id: "archived-pre-docforge-documents"
      sources:
        - path: "docs/_archive/CONVENTIONS.md"
          role: "doc"
          git_blob: "878c15dcb2e9f1fd811a7432688b8b20c6b72512"
        - path: "docs/_archive/DESIGN.md"
          role: "doc"
          git_blob: "2880ba6314ea9772c70f177af4af181da9177cb3"
        - path: "docs/_archive/PRIVACY.md"
          role: "doc"
          git_blob: "4fab52de09cef3d41e3f25c500a4ab0df475a2b1"
        - path: "docs/_archive/PROBLEMS.md"
          role: "doc"
          git_blob: "acb0eac12772c9857d236b931083ae0de175c6fe"
        - path: "docs/_archive/RELEASE.md"
          role: "doc"
          git_blob: "c749b17a004e3cf47af6af61e82db4aa9d40494d"
        - path: "docs/_archive/TELEX.md"
          role: "doc"
          git_blob: "7a6c47e94add2cf0a95722716c29874a29c7d37b"
        - path: "docs/_archive/THIRD_PARTY_NOTICES.md"
          role: "doc"
          git_blob: "8c0da23df063ee46dc734994bdd9b6e365eb7a72"
      unresolved: []
---
# Documentation

_Last reviewed: 2026-08-03_

EasyKey is a private-by-design Vietnamese typing utility for macOS: a menu-bar app that transforms keystrokes into Vietnamese text, keeps an opt-in local clipboard history, and translates through on-device or opt-in cloud providers. This documentation is for everyone who works with the repository — users, engineers, reviewers, and maintainers — and is organized by the question each reader brings: product, architecture, flows, engineering, reference, operations, security, and contributing.


## Scope and boundaries

This index routes the documentation for the EasyKey repository. It covers everything under `docs/` plus the root-level routers and records
([SECURITY.md](../SECURITY.md), [CONTRIBUTING.md](../CONTRIBUTING.md), [CHANGELOG.md](../CHANGELOG.md)). Hand-written reference documents in `docs/` that predate this index are listed below; they are canonical for their topics and are not restated here.

## At a glance

Each concern lives in its own section with a README that routes to the detailed documents:

- **Product** — what EasyKey does, who it is for, and how to use it.
- **Architecture** — how the app is put together, its constraints and decisions.
- **Flows** — how typing, clipboard, and translation behave end to end.
- **Engineering** — how to build, test, and ship the project.
- **Reference** — the exact facts: configuration, limits, glossary, stack, API, compatibility.
- **Operations** — deployment, distribution, and observability.
- **Security** — threat model, data handling, permissions.
- **Contributing** — ownership and how to contribute.

## Start here

| You are | Read |
|---|---|
| New to the project | [product/overview.md](product/overview.md) |
| A new engineer | [architecture/high-level.md](architecture/high-level.md) → [engineering/setup.md](engineering/setup.md) → [engineering/testing.md](engineering/testing.md) |
| Installing or using EasyKey | [product/quickstart.md](product/quickstart.md) |
| Contributing | [CONTRIBUTING.md](../CONTRIBUTING.md) → [contributing/README.md](contributing/README.md) |
| Reviewing security or privacy | [security/README.md](security/README.md) · [reference/limitations.md](reference/limitations.md) |
| Looking after an install | [operations/README.md](operations/README.md) |

## Sections

<!-- docforge-children:start -->
| Folder | Answers |
|---|---|
| [Architecture](architecture/README.md) | How EasyKey is structured: high- and low-level design, constraints, dependencies, lifecycle, UI state, platform integration, and the decision log |
| [Product](product/README.md) | What EasyKey does, who it is for, and how to get your first result — plus accessibility, localization, and migration guides |
| [Flows](flows/README.md) | How each user-facing flow (keyboard typing, clipboard history, translation) behaves from trigger to outcome |
| [Engineering](engineering/README.md) | How to set up the project, test it, follow its conventions, and ship a release |
| [Reference](reference/README.md) | The exact facts: configuration keys, limitations, glossary, tech stack, public API, and compatibility |
| [Operations](operations/README.md) | How EasyKey is deployed, distributed, and observed, and how incidents are handled |
| [Security](security/README.md) | The threat model, how each data class is handled, and which macOS permissions the app uses and why |
| [Contributing](contributing/README.md) | Who owns what in the repository and how to route your contribution |
<!-- docforge-children:end -->

## Archived pre-Docforge documents

These hand-written documents predate this documentation set. They were
superseded by the generated sections above and archived to `docs/_archive/`;
they are kept for history and reference only, and their topics are now owned
by the documents the sections above route to:

| Document | Answers (historical) | Now owned by |
|---|---|---|
| [CONVENTIONS.md](engineering/conventions.md) | Engineering rules (dependency direction, error handling, testing) | [engineering/conventions.md](engineering/conventions.md) |
| [DESIGN.md](architecture/README.md) | Design notes behind the app's behavior and UI | [architecture/](architecture/README.md) |
| [PRIVACY.md](security/data-handling.md) | Data flows, provider links, and the privacy posture | [security/data-handling.md](security/data-handling.md) |
| [PROBLEMS.md](reference/limitations.md) | Known platform problems and their workarounds | [reference/limitations.md](reference/limitations.md) |
| [RELEASE.md](engineering/release.md) | The complete release process and its credentials | [engineering/release.md](engineering/release.md) |
| [TELEX.md](flows/keyboard-typing.md) | The exact Telex and Simple Telex rule set | [flows/keyboard-typing.md](flows/keyboard-typing.md) |
| `THIRD_PARTY_NOTICES.md` (archived) | Third-party acknowledgements | — |

## Related root documents

- [product/overview.md](product/overview.md) — the project home: what EasyKey is, install, default shortcuts, build from source, quality gates.
- [SECURITY.md](../SECURITY.md) — the security policy: stance, supported scope, and how to report a vulnerability.
- [CONTRIBUTING.md](../CONTRIBUTING.md) — the contributor path in one page.
- [CHANGELOG.md](../CHANGELOG.md) — released versions and what changed in each.

## Conventions

- Volatile documents carry a `_Last reviewed: YYYY-MM-DD_` line.
- Reference material is generated where a machine-readable source exists; generated files say so and name the regeneration command (the flow index in [flows/README.md](flows/README.md) is one example).
- Documentation is host-neutral: forge-specific detail lives only in [contributing/README.md](contributing/README.md).
