---
id: "runbooks_index"
title: "Runbooks"
description: "Runbook documentation overview: what runbooks are, scope, and the reader question each runbook answers"
docforge_provenance:
  schema: "2.0"
  doc_id: "runbooks_index"
  path: "docs/operations/runbooks/README.md"
  generated_at: "2026-08-13T12:05:04Z"
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
        - path: "docs/operations/README.md"
          role: "doc"
          git_blob: "aec2487a702a755dcfd080d0d8921cbe0b3bb2bf"
        - path: "docs/operations/deployment.md"
          role: "doc"
          git_blob: "be236f34aca5c44878cca3422e9a7f5356459578"
      unresolved: []
    - id: "scope-and-boundaries"
      sources:
        - path: "docs/operations/deployment.md"
          role: "doc"
          git_blob: "be236f34aca5c44878cca3422e9a7f5356459578"
        - path: "docs/operations/distribution.md"
          role: "doc"
          git_blob: "81c218a74d54e2570a3e52075ea822906e7e75a5"
        - path: "docs/operations/observability.md"
          role: "doc"
          git_blob: "2a446332896ed1314e5136dfa30a8e9708d290a6"
        - path: "docs/architecture/platform-integration.md"
          role: "doc"
          git_blob: "e813aa3dd2fc4c8a50c6f95d132971b8dfd04592"
      unresolved: []
    - id: "start-here"
      sources:
        - path: "docs/operations/deployment.md"
          role: "doc"
          git_blob: "be236f34aca5c44878cca3422e9a7f5356459578"
        - path: "docs/operations/distribution.md"
          role: "doc"
          git_blob: "81c218a74d54e2570a3e52075ea822906e7e75a5"
        - path: "docs/architecture/platform-integration.md"
          role: "doc"
          git_blob: "e813aa3dd2fc4c8a50c6f95d132971b8dfd04592"
        - path: "docs/operations/observability.md"
          role: "doc"
          git_blob: "2a446332896ed1314e5136dfa30a8e9708d290a6"
      unresolved: []
    - id: "detailed-documentation"
      sources:
        - path: "docs/operations/deployment.md"
          role: "doc"
          git_blob: "be236f34aca5c44878cca3422e9a7f5356459578"
        - path: "docs/operations/distribution.md"
          role: "doc"
          git_blob: "81c218a74d54e2570a3e52075ea822906e7e75a5"
      unresolved: []
    - id: "related-sections"
      sources:
        - path: "docs/operations/README.md"
          role: "doc"
          git_blob: "aec2487a702a755dcfd080d0d8921cbe0b3bb2bf"
        - path: "docs/README.md"
          role: "doc"
          git_blob: "f46130b93e8bd0bfe43446dd7d42555ae5133400"
      unresolved: []
---
# Runbooks

_Last reviewed: 2026-08-13_

This section is where EasyKey's runbooks live: step-by-step recovery procedures for operational incidents — a bad release, a lost permission, a broken update channel. It exists so the operator (in practice the project's maintainer) has a checklist to follow under pressure instead of reconstructing the procedure from memory. No runbooks are written yet; the procedures they would contain are owned by the operations documents below, which this README routes to.

## At a glance

A runbook here would capture the manual, maintainer-only recovery procedures: rolling back a release by regenerating the appcast, and recovering from lost system permissions. Today both topics are owned by existing operations documents — the [deployment](../deployment.md) and [distribution](../distribution.md) documents cover release rollback, and [platform integration](../../architecture/platform-integration.md) with [observability](../observability.md) cover permission loss — so those documents are the working substitutes until runbooks materialize.

## Scope and boundaries

A document belongs here when it is a runbook: a procedure to recover from a known incident, written as ordered steps with verification. Procedure content that already has a home stays there:

- release rollback and appcast regeneration — owned by [deployment](../deployment.md) and [distribution](../distribution.md);
- permission loss, health states, and log export — owned by [platform integration](../../architecture/platform-integration.md) and [observability](../observability.md);
- permission rationale and security policy — owned by the [permissions](../../security/permissions.md) document.

The deployment document routes incident recovery to this runbooks section rather than carrying the procedure itself.

## Start here

| You want to | Read |
|---|---|
| Roll back or withdraw a released version | [Update and rollback](../distribution.md) and [Rollback](../deployment.md) |
| Recover after Accessibility permission is lost or revoked | [Accessibility](../../architecture/platform-integration.md) and [Signals](../observability.md) |
| Understand why a health state means the keyboard pipeline is down | [Status and health](../observability.md) |

## Detailed documentation

<!-- docforge-children:start -->
No runbooks are written yet, and none are selected in this run — an empty section is the honest state, not a missing deliverable. When an incident produces a repeatable recovery procedure, it belongs here as a numbered runbook; until then, the rollback procedures in [deployment](../deployment.md) and [distribution](../distribution.md) own those topics.
<!-- docforge-children:end -->

## Related sections

- Parent index: [Operations](../README.md)
- Repository docs index: [docs](../../README.md)
