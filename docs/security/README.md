---
docforge_provenance:
  schema: "2.0"
  doc_id: "security_index"
  path: "docs/security/README.md"
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
    - id: "security"
      sources:
        - path: "README.md"
          git_blob: "8687b8acd6307c86df97aeaf869a85c5c041e671"
          git_blob_normalized: "8687b8acd6307c86df97aeaf869a85c5c041e671"
          role: "doc"
        - path: "SECURITY.md"
          git_blob: "37c5780021fb069b67e0f659f1db26272c56142e"
          git_blob_normalized: "37c5780021fb069b67e0f659f1db26272c56142e"
          role: "doc"
      unresolved: []
    - id: "at-a-glance"
      sources:
        - path: "docs/security/permissions.md"
          git_blob: "61ce3b9fb16abc5c4b4ca74dbad9e2e4be39c9e4"
          git_blob_normalized: "61ce3b9fb16abc5c4b4ca74dbad9e2e4be39c9e4"
          role: "doc"
      unresolved: []
    - id: "scope-and-boundaries"
      sources:
        - path: "docs/security/permissions.md"
          git_blob: "61ce3b9fb16abc5c4b4ca74dbad9e2e4be39c9e4"
          git_blob_normalized: "61ce3b9fb16abc5c4b4ca74dbad9e2e4be39c9e4"
          role: "doc"
        - path: "SECURITY.md"
          git_blob: "37c5780021fb069b67e0f659f1db26272c56142e"
          git_blob_normalized: "37c5780021fb069b67e0f659f1db26272c56142e"
          role: "doc"
      unresolved: []
    - id: "start-here"
      sources:
        - path: "docs/security/permissions.md"
          git_blob: "61ce3b9fb16abc5c4b4ca74dbad9e2e4be39c9e4"
          git_blob_normalized: "61ce3b9fb16abc5c4b4ca74dbad9e2e4be39c9e4"
          role: "doc"
      unresolved: []
    - id: "detailed-documentation"
      sources:
        - path: "docs/security/permissions.md"
          git_blob: "61ce3b9fb16abc5c4b4ca74dbad9e2e4be39c9e4"
          git_blob_normalized: "61ce3b9fb16abc5c4b4ca74dbad9e2e4be39c9e4"
          role: "doc"
      unresolved: []
    - id: "related-sections"
      sources:
        - path: "docs/README.md"
          git_blob: "4e9392f1d88c919a51368d4ed091365f24ecbea8"
          git_blob_normalized: "4e9392f1d88c919a51368d4ed091365f24ecbea8"
          role: "doc"
        - path: "docs/architecture/README.md"
          git_blob: "c48e9370bf10cf63448435727cc3372b7a8b5f65"
          git_blob_normalized: "c48e9370bf10cf63448435727cc3372b7a8b5f65"
          role: "doc"
        - path: "docs/operations/README.md"
          git_blob: "cfe500956de51461f8e66a21bc0212bdbfeb5bbd"
          git_blob_normalized: "cfe500956de51461f8e66a21bc0212bdbfeb5bbd"
          role: "doc"
      unresolved: []
---
# Security

_Last reviewed: 2026-08-15_

This section documents the security posture of EasyKey: the exact platform permission footprint the app uses, with the manifest evidence for each capability. Engineers reviewing the app, auditors, and anyone making a trust decision about a keystroke-transforming utility should read it. Disclosure practice and the handling of reports are governed by the root [Security policy](../../SECURITY.md), which this section routes to rather than restates.

## At a glance

The permission footprint is a single bounded question: exactly one TCC-gated capability — Accessibility — plus one login item, everything else ungated with manifest evidence. The child document owns it in depth, and the root [Security policy](../../SECURITY.md) owns disclosure and reporting.

## Scope and boundaries

This section owns the *permission footprint*: which TCC-gated capabilities and ungated resources the app uses, with its manifest evidence. It does not own the implementation of the architecture being secured ([architecture](../architecture/README.md)) or the operational channels the artifact ships through ([operations](../operations/README.md)). The root [Security policy](../../SECURITY.md) owns disclosure and reporting process; this section never restates a fact a child document or the policy owns.

## Start here

| You want to | Read |
|---|---|
| Verify the exact permission footprint and its manifest evidence | [permissions.md](permissions.md) |
| Understand disclosure and report handling | [Security policy](../../SECURITY.md) |

## Detailed documentation

<!-- docforge-children:start -->
| Document | Answers |
|---|---|
| [Permissions](permissions.md) | Which TCC-gated capabilities and ungated resources does the app use, with what evidence? |
<!-- docforge-children:end -->

## Related sections

- [Documentation home](../README.md) — the parent index of all sections.
- [Security policy](../../SECURITY.md) — the root policy for disclosure, reporting, and handling (related, not a child).
- [Architecture](../architecture/README.md) — the system design the permission footprint applies to.
- [Operations](../operations/README.md) — the distribution channels the artifact ships through.
