---
id: "security_index"
title: "Security"
description: "Section overview for security: EasyKey's threat model, data handling, and permissions, and the reader question each security document answers"
docforge_provenance:
  schema: "2.0"
  doc_id: "security_index"
  path: "docs/security/README.md"
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
    - id: "security"
      sources:
        - path: "README.md"
          role: "doc"
          git_blob: "adbd4f30d3c2f11bb855e6645195493a6c6a34f7"
        - path: "SECURITY.md"
          role: "doc"
          git_blob: "7e7454b313e3fe7acf3ec8e17cbc0d9ab7aad3ab"
        - path: "docs/security/threat-model.md"
          role: "doc"
          git_blob: "56c7498a173ff87203b6373c09c1e8b6b5f0855d"
      unresolved: []
    - id: "at-a-glance"
      sources:
        - path: "docs/security/threat-model.md"
          role: "doc"
          git_blob: "56c7498a173ff87203b6373c09c1e8b6b5f0855d"
        - path: "docs/security/data-handling.md"
          role: "doc"
          git_blob: "5403a91f4763dbb6e4d1c679f4ec4ff265ac3545"
        - path: "docs/security/permissions.md"
          role: "doc"
          git_blob: "666cd46ca4dc3fb56e0c9dcae77e6b261dec8107"
      unresolved: []
    - id: "scope-and-boundaries"
      sources:
        - path: "docs/security/threat-model.md"
          role: "doc"
          git_blob: "56c7498a173ff87203b6373c09c1e8b6b5f0855d"
        - path: "docs/security/permissions.md"
          role: "doc"
          git_blob: "666cd46ca4dc3fb56e0c9dcae77e6b261dec8107"
        - path: "SECURITY.md"
          role: "doc"
          git_blob: "7e7454b313e3fe7acf3ec8e17cbc0d9ab7aad3ab"
      unresolved: []
    - id: "start-here"
      sources:
        - path: "docs/security/threat-model.md"
          role: "doc"
          git_blob: "56c7498a173ff87203b6373c09c1e8b6b5f0855d"
        - path: "docs/security/data-handling.md"
          role: "doc"
          git_blob: "5403a91f4763dbb6e4d1c679f4ec4ff265ac3545"
        - path: "docs/security/permissions.md"
          role: "doc"
          git_blob: "666cd46ca4dc3fb56e0c9dcae77e6b261dec8107"
      unresolved: []
    - id: "detailed-documentation"
      sources:
        - path: "docs/security/threat-model.md"
          role: "doc"
          git_blob: "56c7498a173ff87203b6373c09c1e8b6b5f0855d"
        - path: "docs/security/data-handling.md"
          role: "doc"
          git_blob: "5403a91f4763dbb6e4d1c679f4ec4ff265ac3545"
        - path: "docs/security/permissions.md"
          role: "doc"
          git_blob: "666cd46ca4dc3fb56e0c9dcae77e6b261dec8107"
      unresolved: []
    - id: "related-sections"
      sources:
        - path: "docs/README.md"
          role: "doc"
          git_blob: "f46130b93e8bd0bfe43446dd7d42555ae5133400"
        - path: "docs/architecture/README.md"
          role: "doc"
          git_blob: "95d57cee5559b85c1ece0674766ce33232b71358"
        - path: "docs/operations/README.md"
          role: "doc"
          git_blob: "aec2487a702a755dcfd080d0d8921cbe0b3bb2bf"
      unresolved: []
---
# Security

_Last reviewed: 2026-08-13_

This section documents the security posture of EasyKey: what the threats to its data plane are, how each data class is handled through its lifecycle, and which platform permissions the app actually uses. Engineers reviewing the app, auditors, and anyone making a trust decision about a keystroke-transforming utility should read it. Disclosure practice and the handling of reports are governed by the root [Security policy](../../SECURITY.md), which this section routes to rather than restates.

## At a glance

The posture rests on three bounded questions: *threats* (what can go wrong with the event tap, clipboard pipeline, cloud translation, Keychain secrets, logs, the update channel, and the login helper), *data* (what classes the repository distinguishes and the lifecycle the code implements for each), and *permissions* (exactly one TCC-gated capability — Accessibility — plus one login item, everything else ungated with manifest evidence). Each child document owns its question in depth.

## Scope and boundaries

This section owns the *threat and data model*: threats, trust boundaries, data classification and lifecycle, and the permission footprint with its evidence. It does not own the implementation of the architecture being secured ([architecture](../architecture/README.md)) or the operational channels the update channel depends on ([operations](../operations/README.md)). The root [Security policy](../../SECURITY.md) owns disclosure and reporting process; this section never restates a fact a child document or the policy owns.

## Start here

| You want to | Read |
|---|---|
| Review the threats and trust boundaries around the app's data plane | [threat-model.md](threat-model.md) |
| See how each data class is collected, stored, retained, and deleted | [data-handling.md](data-handling.md) |
| Verify the exact permission footprint and its manifest evidence | [permissions.md](permissions.md) |
| Understand disclosure and report handling | [Security policy](../../SECURITY.md) |

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
- [Architecture](../architecture/README.md) — the design the threat model protects.
- [Operations](../operations/README.md) — the distribution and update channels the threat model covers.
