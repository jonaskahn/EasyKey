---
docforge_provenance:
  schema: "2.0"
  doc_id: "operations_index"
  path: "docs/operations/README.md"
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
    - id: "operations"
      sources:
        - path: "README.md"
          git_blob: "8687b8acd6307c86df97aeaf869a85c5c041e671"
          git_blob_normalized: "8687b8acd6307c86df97aeaf869a85c5c041e671"
          role: "doc"
        - path: "docs/operations/distribution.md"
          git_blob: "8d83cebf8fd01048b8f098b01c20ee30294eeb36"
          git_blob_normalized: "8d83cebf8fd01048b8f098b01c20ee30294eeb36"
          role: "doc"
      unresolved: []
    - id: "at-a-glance"
      sources:
        - path: "docs/operations/distribution.md"
          git_blob: "8d83cebf8fd01048b8f098b01c20ee30294eeb36"
          git_blob_normalized: "8d83cebf8fd01048b8f098b01c20ee30294eeb36"
          role: "doc"
      unresolved: []
    - id: "scope-and-boundaries"
      sources:
        - path: "docs/operations/distribution.md"
          git_blob: "8d83cebf8fd01048b8f098b01c20ee30294eeb36"
          git_blob_normalized: "8d83cebf8fd01048b8f098b01c20ee30294eeb36"
          role: "doc"
      unresolved: []
    - id: "start-here"
      sources:
        - path: "docs/operations/distribution.md"
          git_blob: "8d83cebf8fd01048b8f098b01c20ee30294eeb36"
          git_blob_normalized: "8d83cebf8fd01048b8f098b01c20ee30294eeb36"
          role: "doc"
      unresolved: []
    - id: "detailed-documentation"
      sources:
        - path: "docs/operations/distribution.md"
          git_blob: "8d83cebf8fd01048b8f098b01c20ee30294eeb36"
          git_blob_normalized: "8d83cebf8fd01048b8f098b01c20ee30294eeb36"
          role: "doc"
      unresolved: []
    - id: "related-sections"
      sources:
        - path: "docs/README.md"
          git_blob: "4e9392f1d88c919a51368d4ed091365f24ecbea8"
          git_blob_normalized: "4e9392f1d88c919a51368d4ed091365f24ecbea8"
          role: "doc"
        - path: "docs/engineering/README.md"
          git_blob: "9f56b7b0b2f542a48eb231204de4460a3487fd40"
          git_blob_normalized: "9f56b7b0b2f542a48eb231204de4460a3487fd40"
          role: "doc"
        - path: "docs/reference/README.md"
          git_blob: "79c7d84c6fe2fb09dc0f1e864b9e3800bfa5ae6e"
          git_blob_normalized: "79c7d84c6fe2fb09dc0f1e864b9e3800bfa5ae6e"
          role: "doc"
        - path: "docs/security/README.md"
          git_blob: "0f92070d04541c48d619502c8343841118453941"
          git_blob_normalized: "0f92070d04541c48d619502c8343841118453941"
          role: "doc"
      unresolved: []
---
# Operations

_Last reviewed: 2026-08-15_

This section covers how a running EasyKey is delivered: the single deployable artifact, the distribution channels that carry it, and how each channel authenticates the artifact. Operators and engineers answering "how does this app get built, shipped, and distributed?" start here.

## At a glance

EasyKey has exactly one deployable artifact — a universal DMG — and one delivery environment: the public release channel, fed by a tag-triggered CI workflow whose release is draft-gated by the maintainer. Two distribution channels consume the same artifact: direct DMG download and Sparkle in-app updates. Because the app runs entirely on the user's Mac with no server components, every channel is manual, maintainer-operated, and authenticated with the evidence the child document records. The child document owns the exact steps and facts.

## Scope and boundaries

This section owns *delivery and distribution*: the artifact, the channels that carry it, and how each authenticates it. It does not own how the artifact is built and tested, which is an engineering workflow ([engineering](../engineering/README.md)), nor the security posture around the app ([security](../security/README.md)). Nothing here restates the steps a child document owns.

## Start here

| You want to | Read |
|---|---|
| See how users receive updates and how each channel authenticates the artifact | [distribution.md](distribution.md) |

## Detailed documentation

<!-- docforge-children:start -->
| Document | Answers |
|---|---|
| [Distribution](distribution.md) | What channels ship the app, and how is the artifact discovered and authenticated in each? |
<!-- docforge-children:end -->

## Related sections

- [Documentation home](../README.md) — the parent index of all sections.
- [Engineering](../engineering/README.md) — the build and test workflow the artifact comes from.
- [Reference](../reference/README.md) — platform compatibility and configuration facts the operations steps depend on.
- [Security](../security/README.md) — the security policy and permission footprint that govern the app.
