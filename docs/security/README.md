---
id: "security_index"
title: "Security"
docforge_provenance:
  schema: "2.0"
  doc_id: "security_index"
  path: "docs/security/README.md"
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
    - id: "security"
      sources:
        - path: "README.md"
          role: "doc"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
        - path: "docs/security/threat-model.md"
          role: "doc"
          git_blob: "11052cc08965a7b20651d827ee29645154b0578c"
        - path: "docs/security/data-handling.md"
          role: "doc"
          git_blob: "c7369f8633033883243a6f14efce1b33c70da9ea"
      unresolved: []
    - id: "at-a-glance"
      sources:
        - path: "docs/security/threat-model.md"
          role: "doc"
          git_blob: "11052cc08965a7b20651d827ee29645154b0578c"
        - path: "docs/security/data-handling.md"
          role: "doc"
          git_blob: "c7369f8633033883243a6f14efce1b33c70da9ea"
        - path: "docs/security/permissions.md"
          role: "doc"
          git_blob: "f122bd95b643d320cd8a5feeaafd3661fe1c604d"
      unresolved: []
    - id: "scope-and-boundaries"
      sources:
        - path: "docs/security/threat-model.md"
          role: "doc"
          git_blob: "11052cc08965a7b20651d827ee29645154b0578c"
      unresolved: []
    - id: "start-here"
      sources:
        - path: "docs/security/threat-model.md"
          role: "doc"
          git_blob: "11052cc08965a7b20651d827ee29645154b0578c"
        - path: "docs/security/data-handling.md"
          role: "doc"
          git_blob: "c7369f8633033883243a6f14efce1b33c70da9ea"
        - path: "docs/security/permissions.md"
          role: "doc"
          git_blob: "f122bd95b643d320cd8a5feeaafd3661fe1c604d"
      unresolved: []
    - id: "detailed-documentation"
      sources:
        - path: "docs/security/threat-model.md"
          role: "doc"
          git_blob: "11052cc08965a7b20651d827ee29645154b0578c"
        - path: "docs/security/data-handling.md"
          role: "doc"
          git_blob: "c7369f8633033883243a6f14efce1b33c70da9ea"
        - path: "docs/security/permissions.md"
          role: "doc"
          git_blob: "f122bd95b643d320cd8a5feeaafd3661fe1c604d"
      unresolved: []
    - id: "related-sections"
      sources:
        - path: "docs/_archive/PRIVACY.md"
          role: "doc"
          git_blob: "4fab52de09cef3d41e3f25c500a4ab0df475a2b1"
      unresolved: []
---
# Security

_Last reviewed: 2026-08-03_

This section documents the security posture of EasyKey: what the threats to its data plane are, how each data class is handled through its lifecycle, and which platform permissions the app actually uses. Engineers reviewing the app, auditors, and anyone making a trust decision about a keystroke-transforming utility should read it. Disclosure practice and the handling of reports are governed by the root [Security policy](../../SECURITY.md); the user-facing data story lives in [PRIVACY.md](data-handling.md).

## At a glance

The posture rests on three bounded questions: *threats* (what can go wrong with the event tap, clipboard pipeline, cloud translation, Keychain secrets, logs, the update channel, and the login helper), *data* (what classes the repository distinguishes and the lifecycle the code implements for each), and *permissions* (exactly one TCC-gated capability — Accessibility — plus one login item, everything else ungated with manifest evidence). Each child document owns its question in depth.

## Scope and boundaries

This section owns the *threat and data model*: threats, trust boundaries, data classification and lifecycle, and the permission footprint with its evidence. It does not own the implementation of the architecture being secured ([architecture](../architecture/README.md)) or the operational channels the update channel depends on ([operations](../operations/README.md)). The root [Security policy](../../SECURITY.md) owns disclosure and reporting process; [PRIVACY.md](data-handling.md) owns the user-facing privacy story.

## Start here

| You want to | Read |
|---|---|
| Review the threats and trust boundaries around the app's data plane | [threat-model.md](threat-model.md) |
| See how each data class is collected, stored, retained, and deleted | [data-handling.md](data-handling.md) |
| Verify the exact permission footprint and its manifest evidence | [permissions.md](permissions.md) |
| Understand disclosure and report handling | [Security policy](../../SECURITY.md) |
| Read the user-facing privacy commitments | [PRIVACY.md](data-handling.md) |

## Detailed documentation

<!-- docforge-children:start -->
| Document | Answers |
|---|---|
| [Threat model](threat-model.md) | What are the threats to the bounded data plane — event tap, clipboard, translation, secrets, logs, updates, login helper — and where do the trust boundaries fall? |
| [Data handling](data-handling.md) | Which data classes does the repository distinguish, and what lifecycle does the code implement for each? |
| [Permissions](permissions.md) | Which TCC-gated capabilities and ungated resources does the app use, with what evidence? |
<!-- docforge-children:end -->

## Related sections

- [Documentation home](../README.md) — the parent index of all sections.
- [Security policy](../../SECURITY.md) — the root policy for disclosure, reporting, and handling (related, not a child).
- [PRIVACY.md](data-handling.md) — the user-facing privacy document this section grounds itself in (related, not a child).
- [Architecture](../architecture/README.md) — the design the threat model protects.
- [Operations](../operations/README.md) — the distribution and update channels the threat model covers.
