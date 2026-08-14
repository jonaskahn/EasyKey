---
id: "operations_index"
title: "Operations"
description: "Section overview for operations: how EasyKey is delivered and observed, and the reader question each operations document answers"
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
          role: "doc"
          git_blob: "0de1699403dbb6d0d24b58a2963cde1ac952a70e"
          git_blob_normalized: "0de1699403dbb6d0d24b58a2963cde1ac952a70e"
        - path: "docs/operations/deployment.md"
          role: "doc"
          git_blob: "c509b0e4ed53082420edb4fd56a9de5158573962"
          git_blob_normalized: "c509b0e4ed53082420edb4fd56a9de5158573962"
        - path: "docs/operations/distribution.md"
          role: "doc"
          git_blob: "fb66df90810b034a6d8a9fc160736547d1e0bc99"
          git_blob_normalized: "fb66df90810b034a6d8a9fc160736547d1e0bc99"
      unresolved: []
    - id: "at-a-glance"
      sources:
        - path: "docs/operations/deployment.md"
          role: "doc"
          git_blob: "c509b0e4ed53082420edb4fd56a9de5158573962"
          git_blob_normalized: "c509b0e4ed53082420edb4fd56a9de5158573962"
        - path: "docs/operations/distribution.md"
          role: "doc"
          git_blob: "fb66df90810b034a6d8a9fc160736547d1e0bc99"
          git_blob_normalized: "fb66df90810b034a6d8a9fc160736547d1e0bc99"
        - path: "docs/operations/observability.md"
          role: "doc"
          git_blob: "c3e35c4f249388455c140eb1602cd5c1883293b2"
          git_blob_normalized: "c3e35c4f249388455c140eb1602cd5c1883293b2"
      unresolved: []
    - id: "scope-and-boundaries"
      sources:
        - path: "docs/operations/deployment.md"
          role: "doc"
          git_blob: "c509b0e4ed53082420edb4fd56a9de5158573962"
          git_blob_normalized: "c509b0e4ed53082420edb4fd56a9de5158573962"
        - path: "docs/operations/runbooks/README.md"
          role: "doc"
          git_blob: "bd725fae949ed5a9f322345c3c209042233a24a5"
          git_blob_normalized: "bd725fae949ed5a9f322345c3c209042233a24a5"
      unresolved: []
    - id: "start-here"
      sources:
        - path: "docs/operations/deployment.md"
          role: "doc"
          git_blob: "c509b0e4ed53082420edb4fd56a9de5158573962"
          git_blob_normalized: "c509b0e4ed53082420edb4fd56a9de5158573962"
        - path: "docs/operations/distribution.md"
          role: "doc"
          git_blob: "fb66df90810b034a6d8a9fc160736547d1e0bc99"
          git_blob_normalized: "fb66df90810b034a6d8a9fc160736547d1e0bc99"
        - path: "docs/operations/observability.md"
          role: "doc"
          git_blob: "c3e35c4f249388455c140eb1602cd5c1883293b2"
          git_blob_normalized: "c3e35c4f249388455c140eb1602cd5c1883293b2"
      unresolved: []
    - id: "detailed-documentation"
      sources:
        - path: "docs/operations/deployment.md"
          role: "doc"
          git_blob: "c509b0e4ed53082420edb4fd56a9de5158573962"
          git_blob_normalized: "c509b0e4ed53082420edb4fd56a9de5158573962"
        - path: "docs/operations/distribution.md"
          role: "doc"
          git_blob: "fb66df90810b034a6d8a9fc160736547d1e0bc99"
          git_blob_normalized: "fb66df90810b034a6d8a9fc160736547d1e0bc99"
        - path: "docs/operations/observability.md"
          role: "doc"
          git_blob: "c3e35c4f249388455c140eb1602cd5c1883293b2"
          git_blob_normalized: "c3e35c4f249388455c140eb1602cd5c1883293b2"
        - path: "docs/operations/runbooks/README.md"
          role: "doc"
          git_blob: "bd725fae949ed5a9f322345c3c209042233a24a5"
          git_blob_normalized: "bd725fae949ed5a9f322345c3c209042233a24a5"
      unresolved: []
    - id: "related-sections"
      sources:
        - path: "docs/README.md"
          role: "doc"
          git_blob: "c26bf46583357c8db29f627fbc0deb41cd7df290"
          git_blob_normalized: "c26bf46583357c8db29f627fbc0deb41cd7df290"
        - path: "docs/engineering/README.md"
          role: "doc"
          git_blob: "c03c59e32926a00ee9ef8344d5df235dd690a4e0"
          git_blob_normalized: "c03c59e32926a00ee9ef8344d5df235dd690a4e0"
        - path: "docs/reference/README.md"
          role: "doc"
          git_blob: "75f4d1cd343f02f86fa451f4b6fa4a160298de44"
          git_blob_normalized: "75f4d1cd343f02f86fa451f4b6fa4a160298de44"
        - path: "docs/security/README.md"
          role: "doc"
          git_blob: "5d45d8e6664111ef4148b28345f1e02c7a0d119e"
          git_blob_normalized: "5d45d8e6664111ef4148b28345f1e02c7a0d119e"
      unresolved: []
---
# Operations

_Last reviewed: 2026-08-14_

This section covers how a running EasyKey is delivered and watched: the single deployable artifact and its release channel, the distribution channels that carry it, and the on-device signals that exist for diagnosing it. Operators and engineers answering "how does this app get built, shipped, and observed?" start here.

## At a glance

EasyKey has exactly one deployable artifact — a universal DMG — and one delivery environment: the public release channel, fed by a tag-triggered CI workflow whose release is draft-gated by the maintainer. Two distribution channels consume the same artifact: direct DMG download and Sparkle in-app updates. Because the app runs entirely on the user's Mac with no server components, observability is on-device only: OSLog entries, an in-memory keyboard-diagnostics ring buffer, and health state surfaced in the UI — with no analytics, telemetry, or alerting by design. The child documents own the exact steps and facts.

## Scope and boundaries

This section owns *delivery and observation*: deployment of the artifact, distribution channels, and on-device observability. It does not own the release procedure itself, which is an engineering workflow ([engineering](../engineering/README.md)), nor the security posture around the channels ([security](../security/README.md)). Incident recovery, where documented, is owned by the runbooks area of this section; the runbooks index is honest about what is not written yet. Nothing here restates the steps a child document owns.

## Start here

| You want to | Read |
|---|---|
| Understand how the app is built, packaged, and delivered to the release channel | [deployment.md](deployment.md) |
| See how users receive updates and how each channel authenticates the artifact | [distribution.md](distribution.md) |
| Diagnose the app from its on-device signals | [observability.md](observability.md) |
| Find a step-by-step recovery procedure for an operational incident | [runbooks/README.md](runbooks/README.md) |

## Detailed documentation

<!-- docforge-children:start -->
| Document | Answers |
|---|---|
| [Deployment](deployment.md) | How is the app built, packaged, and delivered to its single public release channel? |
| [Distribution](distribution.md) | What channels ship the app, and how is the artifact discovered and authenticated in each? |
| [Observability](observability.md) | What signals does the app emit on-device, and what can — and deliberately cannot — be observed? |
| [Runbooks](runbooks/README.md) | What step-by-step recovery procedures exist for operational incidents — and what is the honest state before runbooks are written? |
<!-- docforge-children:end -->

## Related sections

- [Documentation home](../README.md) — the parent index of all sections.
- [Engineering](../engineering/README.md) — the release workflow that produces the artifact this section delivers.
- [Reference](../reference/README.md) — platform compatibility and configuration facts the operations steps depend on.
- [Security](../security/README.md) — the update-channel threats these distribution facts are part of.
