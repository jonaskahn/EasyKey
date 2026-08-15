# Documentation

_Last reviewed: 2026-08-15_

EasyKey is a private-by-design Vietnamese typing utility for macOS: a menu-bar app that transforms keystrokes into Vietnamese text, keeps an opt-in local clipboard history, and translates through on-device or opt-in cloud providers. This documentation serves everyone who works with the repository — users, engineers, reviewers, and maintainers — and is organized by the question each reader brings: product, architecture, flows, engineering, reference, operations, and security.

## At a glance

Each concern lives in its own section, and every section has a README that routes to its detailed documents: product understanding, architecture, flows, engineering practice, reference facts, operations, and security. Root-level records — the security policy, contribution guide, and changelog — sit alongside this index, which routes to the section READMEs.

## Scope and boundaries

This documentation set owns how to understand, build, test, ship, and operate EasyKey — the product story, architecture, flows, engineering practice, reference facts, operations, and security posture. It does not replace reading the source code, and it does not restate the repository's contribution rules (CONTRIBUTING.md) or vulnerability reporting (SECURITY.md), which stay at the repository root. The documentation's own rules live in the Conventions section below.

## Start here

| You are | Read |
|---|---|
| New to the project | [product/overview.md](product/overview.md) |
| A new engineer | [architecture/high-level.md](architecture/high-level.md) → [engineering/setup.md](engineering/setup.md) |
| Installing or using EasyKey | [product/quickstart.md](product/quickstart.md) |
| Reviewing security or privacy | [security/README.md](security/README.md) · [reference/limitations.md](reference/limitations.md) |
| Looking after an install | [operations/README.md](operations/README.md) |
| Contributing | CONTRIBUTING.md |

## Sections

<!-- docforge-children:start -->
| Folder | Answers |
|---|---|
| [Architecture](architecture/README.md) | How EasyKey is structured: system overview, high-level design, lifecycle, platform and AI integration, UI state, and persistence |
| [Product](product/README.md) | What EasyKey does, who it is for, and how to get your first result — plus accessibility, localization, and migration guides |
| [Flows](flows/README.md) | How each user-facing flow — keyboard typing, clipboard history, translation — behaves from trigger to outcome |
| [Engineering](engineering/README.md) | How to set up the project, test it, follow its conventions, and ship a release |
| [Reference](reference/README.md) | The exact facts: configuration keys, limitations, tech stack, public API, and compatibility |
| [Operations](operations/README.md) | How EasyKey is deployed, distributed, and observed, and where incident runbooks will live |
| [Security](security/README.md) | The threat model, how each data class is handled, and which macOS permissions the app uses |
<!-- docforge-children:end -->

## Hand-written documents

A few hand-written documents predate this documentation set and remain canonical for their topics; they live at the locations below rather than in a section:

| Document | Answers | Location |
|---|---|---|
| Telex rule set | Exact full Telex and Simple Telex rules: modifiers, tone keys, tone placement, undo, spell validation, defaults | notes/telex.md |
| Engineering rulebook | The authoritative engineering conventions (naming, structure, error handling, testing, review) | notes/rulebook.md |
| Design notes | Design scale, materials policy, typography, components, iconography, motion, accessibility | notes/design.md |
| Third-party notices | Acknowledgments for bundled components and connected translation providers | THIRD_PARTY_NOTICES.md |

## Related root documents

- README — the repository home: what EasyKey is, install, build from source.
- SECURITY.md — the security policy: stance, supported scope, and how to report a vulnerability.
- CONTRIBUTING.md — the contributor path in one page.
- [CHANGELOG.md](../CHANGELOG.md) — released versions and what changed in each.

## Conventions

- Volatile documents carry a `_Last reviewed: YYYY-MM-DD_` line.
- Reference material is generated where a machine-readable source exists; generated files say so and name the regeneration command (the flow index in [flows/README.md](flows/README.md) is one example).
- Documentation is host-neutral: forge-specific detail lives only in CONTRIBUTING.md.
