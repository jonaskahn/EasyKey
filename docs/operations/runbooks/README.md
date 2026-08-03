---
id: "runbooks_index"
title: "Runbooks"
docforge_provenance:
  schema: "2.0"
  doc_id: "runbooks_index"
  path: "docs/operations/runbooks/README.md"
  generated_at: "2026-08-03T09:24:12Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "orientation"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "at-a-glance"
      sources:
        - path: "docs/operations/deployment.md"
          role: "doc"
          git_blob: "a049cb233da59da928a4566ad8bd2f2f104eac2c"
      unresolved: []
    - id: "scope-and-boundaries"
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
    - id: "start-here"
      sources:
        - path: "docs/operations/distribution.md"
          role: "doc"
          git_blob: "c31adeb4073e1768bc7db93d5cc451396144eea6"
        - path: "docs/operations/deployment.md"
          role: "doc"
          git_blob: "a049cb233da59da928a4566ad8bd2f2f104eac2c"
        - path: "docs/architecture/platform-integration.md"
          role: "doc"
          git_blob: "79fced1ae49f8a341d0420ecc16652bea43ab2aa"
      unresolved: []
    - id: "detailed-documentation"
      sources:
        - path: "docs/operations/deployment.md"
          role: "doc"
          git_blob: "a049cb233da59da928a4566ad8bd2f2f104eac2c"
      unresolved: []
    - id: "related-sections"
      sources:
        - path: "docs/operations/deployment.md"
          role: "doc"
          git_blob: "a049cb233da59da928a4566ad8bd2f2f104eac2c"
      unresolved: []
---
# Runbooks

_Last reviewed: 2026-08-03_

This section is where EasyKey's runbooks live: step-by-step recovery procedures for operational incidents — a bad release, a lost permission, a broken update channel. It exists so the operator (in practice the project's maintainer) has a checklist to follow under pressure instead of reconstructing the procedure from memory. No runbooks are written yet; the procedures they would contain are owned by the operations documents below, which this README routes to.

## At a glance

A runbook here would capture the manual, maintainer-only recovery procedures: rolling back a release by regenerating the appcast, and recovering from lost system permissions. Today both topics are owned by existing operations documents — [deployment](../deployment.md) and [distribution](../distribution.md) cover release rollback, and [platform integration](../../architecture/platform-integration.md) with [observability](../observability.md) cover permission loss — so those documents are the working substitutes until runbooks materialize.

## Scope and boundaries

A document belongs here when it is a runbook: a procedure to recover from a known incident, written as ordered steps with verification. Procedure content that already has a home stays there:

- release rollback and appcast regeneration — owned by [deployment](../deployment.md) and [distribution](../distribution.md);
- permission loss, health states, and log export — owned by [platform integration](../../architecture/platform-integration.md) and [observability](../observability.md);
- permission rationale and security policy — owned by the [permissions](../../security/permissions.md) document.

The deployment document states the boundary explicitly: incident recovery belongs to this runbooks section, not to the deployment procedure itself.

## Start here

| You want to | Read |
|---|---|
| Roll back or withdraw a released version | [Update and rollback](../distribution.md) and [Rollback](../deployment.md) |
| Recover after Accessibility permission is lost or revoked | [Accessibility](../../architecture/platform-integration.md) and [Signals](../observability.md) |
| Understand why a health state means the keyboard pipeline is down | [Status and health](../observability.md) |

## Detailed documentation

<!-- docforge-children:start -->
No runbooks are written yet, and none are selected in this run — an empty section is the honest state, not a missing deliverable. When an incident produces a repeatable recovery procedure, it belongs here as a numbered runbook; until then the operations documents above own those topics.
<!-- docforge-children:end -->

## Related sections

- Parent index: [Operations](../README.md)
- Repository docs index: [docs](../../README.md)
