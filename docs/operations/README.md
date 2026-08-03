---
id: "operations_index"
title: "Operations"
docforge_provenance:
  schema: "2.0"
  doc_id: "operations_index"
  path: "docs/operations/README.md"
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
    - id: "operations"
      sources:
        - path: "README.md"
          role: "doc"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
        - path: "docs/operations/deployment.md"
          role: "doc"
          git_blob: "a049cb233da59da928a4566ad8bd2f2f104eac2c"
      unresolved: []
    - id: "at-a-glance"
      sources:
        - path: "docs/operations/deployment.md"
          role: "doc"
          git_blob: "a049cb233da59da928a4566ad8bd2f2f104eac2c"
        - path: "docs/operations/distribution.md"
          role: "doc"
          git_blob: "c31adeb4073e1768bc7db93d5cc451396144eea6"
        - path: "docs/operations/observability.md"
          role: "doc"
          git_blob: "bd705a76d0cadaa3a012d9df184894aba8f88c5f"
      unresolved: []
    - id: "scope-and-boundaries"
      sources:
        - path: "docs/operations/deployment.md"
          role: "doc"
          git_blob: "a049cb233da59da928a4566ad8bd2f2f104eac2c"
      unresolved: []
    - id: "start-here"
      sources:
        - path: "docs/operations/deployment.md"
          role: "doc"
          git_blob: "a049cb233da59da928a4566ad8bd2f2f104eac2c"
        - path: "docs/operations/distribution.md"
          role: "doc"
          git_blob: "c31adeb4073e1768bc7db93d5cc451396144eea6"
        - path: "docs/operations/observability.md"
          role: "doc"
          git_blob: "bd705a76d0cadaa3a012d9df184894aba8f88c5f"
      unresolved: []
    - id: "detailed-documentation"
      sources:
        - path: "docs/operations/deployment.md"
          role: "doc"
          git_blob: "a049cb233da59da928a4566ad8bd2f2f104eac2c"
        - path: "docs/operations/distribution.md"
          role: "doc"
          git_blob: "c31adeb4073e1768bc7db93d5cc451396144eea6"
        - path: "docs/operations/observability.md"
          role: "doc"
          git_blob: "bd705a76d0cadaa3a012d9df184894aba8f88c5f"
        - path: "docs/operations/runbooks/README.md"
          role: "doc"
          git_blob: "462235533292404e5eeedb505a0dab08dff7f042"
      unresolved: []
    - id: "related-sections"
      sources:
        - path: "docs/engineering/README.md"
          role: "doc"
          git_blob: "7363e3a9e0edd2b57706aa64e4ef319af6728bc6"
      unresolved: []
---
# Operations

_Last reviewed: 2026-08-03_

This section covers how a running EasyKey is delivered and watched: the single deployable artifact and its release channel, the two distribution channels that carry it, and the on-device signals that exist for diagnosing it. Operators and engineers answering "how does this app get built, shipped, and observed?" start here.

## At a glance

EasyKey has exactly one deployable artifact — a universal DMG — and one delivery environment: the public release channel, fed by a tag-triggered CI workflow whose release is draft-gated by the maintainer. Two distribution channels consume the same artifact: direct DMG download and Sparkle in-app updates. Because the app runs entirely on the user's Mac with no server components, observability is on-device only: OSLog entries, an in-memory keyboard-diagnostics ring buffer, and health state surfaced in the UI — with no analytics, telemetry, or alerting by design. The child documents own the exact steps and facts.

## Scope and boundaries

This section owns *delivery and observation*: deployment of the artifact, distribution channels, and on-device observability. It does not own the release procedure itself, which is an engineering workflow ([engineering](../engineering/README.md)), nor the security posture around the channels ([security](../security/README.md)). Incident recovery, where documented, is owned by the runbooks area of this section; nothing here restates the steps a child document owns.

## Start here

| You want to | Read |
|---|---|
| Understand how the app is built, packaged, and delivered to the release channel | [deployment.md](deployment.md) |
| See how users receive updates and how each channel authenticates the artifact | [distribution.md](distribution.md) |
| Diagnose the app from its on-device signals | [observability.md](observability.md) |

## Detailed documentation

<!-- docforge-children:start -->
| Document | Answers |
|---|---|
| [Deployment](deployment.md) | How is the app built, packaged, and delivered to its single public release channel? |
| [Distribution](distribution.md) | What channels ship the app, and how is the artifact discovered and authenticated in each? |
| [Observability](observability.md) | What signals does the app emit on-device, and what can — and deliberately cannot — be observed? |
| [Runbooks](runbooks/README.md) | What step-by-step recovery procedures exist for operational incidents, and where does release rollback live until runbooks are written? |
<!-- docforge-children:end -->

## Related sections

- [Documentation home](../README.md) — the parent index of all sections.
- [Engineering](../engineering/README.md) — the release workflow that produces the artifact this section delivers.
- [Reference](../reference/README.md) — platform compatibility and configuration facts the operations steps depend on.
