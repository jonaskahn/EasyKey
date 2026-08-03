---
id: "flows_index"
title: "Flows"
docforge_provenance:
  schema: "2.0"
  doc_id: "flows_index"
  path: "docs/flows/README.md"
  generated_at: "2026-08-03T08:35:56+00:00"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "orientation"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "flows"
      sources:
        - path: ".docforge/flow-index.json"
          git_blob: "b6a06cc6d316c41d09d81abf18dd0c4dc86c5d49"
          role: "manifest"
      unresolved: []
    - id: "how-to-read-this-index"
      sources:
        - path: ".docforge/flow-index.json"
          git_blob: "b6a06cc6d316c41d09d81abf18dd0c4dc86c5d49"
          role: "manifest"
      unresolved: []
---
# Flows

_Last reviewed: 2026-08-03_

This index lists every evidence-backed flow candidate and routes readers
to the deep-dive flow documents. **Main** priority **standalone** rows get
deep-dive documentation; **member** rows are composed into a parent;
**index_only** / deferred rows stay discoverable without stub files.

## How to read this index

Pick a flow by trigger or entry point. **main** rows are the current
operating paths and own deep-dive documents; **deferred** rows are
evidenced but not yet documented; **placeholder** rows are candidates
awaiting confirmation; **documented** rows point at their flow document;
**skipped** rows were examined and set aside. `Confidence` states how much
evidence backs the candidate; `Reach` is steps / boundaries / changes.

| Status | Role | Flow | Trigger | Entry point | Area | Confidence | Reach |
|---|---|---|---|---|---|---|---|
| documented | standalone | [Clipboard history capture, persistence, and restore](./clipboard-history.md) | internal | `` | ['clipboard'] | candidate | 7 steps / 3 boundaries / 0 changes |
| documented | standalone | [Translation via on-device or cloud providers](./translation.md) | internal | `` | ['translation'] | candidate | 8 steps / 3 boundaries / 0 changes |
| documented | standalone | [Keyboard typing transformation (Telex/VNI)](./keyboard-typing.md) | internal | `` | ['keyboard'] | candidate | 6 steps / 3 boundaries / 0 changes |
| deferred | index_only | Per-application language Smart Switch | internal | `` | ['keyboard'] | candidate | 3 steps / 2 boundaries / 0 changes |
| deferred | index_only | Macro expansion from triggers | internal | `` | ['keyboard'] | candidate | 3 steps / 2 boundaries / 0 changes |
| deferred | index_only | Launch-at-login helper registration and watchdog | internal | `` | ['system-integration'] | candidate | 2 steps / 2 boundaries / 0 changes |
| deferred | index_only | Sparkle app updates | internal | `` | ['system-integration'] | candidate | 3 steps / 2 boundaries / 0 changes |

_Generated 2026-08-03T08:35:56+00:00; source of truth: `.docforge/flow-index.json`._
