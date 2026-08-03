---
id: "adr-settings-delta"
title: "Adr Settings Delta"
docforge_provenance:
  schema: "2.0"
  doc_id: "adr-settings-delta"
  path: "docs/architecture/decisions/settings-delta.md"
  generated_at: "2026-08-03T08:44:33Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "reference"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "context-and-problem-statement"
      sources:
        - path: "EasyKeyApp/Coordination/AppCoordinatorWiring.swift"
          git_blob: "e5b6d9a47e88e742e3b303ec1001d1492538fbb0"
          role: "code"
        - path: "EasyEngineCore/Settings/EasyKeySettings.swift"
          git_blob: "b42c58c6e3f1eba416bca3c809ba579441fe87cc"
          role: "code"
        - path: "EasyEngineCore/Settings/EasyKeySettings.swift"
          git_blob: "b42c58c6e3f1eba416bca3c809ba579441fe87cc"
          role: "history"
      unresolved: []
    - id: "decision"
      sources:
        - path: "EasyEngineCore/Settings/EasyKeySettings.swift"
          git_blob: "b42c58c6e3f1eba416bca3c809ba579441fe87cc"
          role: "code"
        - path: "EasyKeyApp/Coordination/AppCoordinatorWiring.swift"
          git_blob: "e5b6d9a47e88e742e3b303ec1001d1492538fbb0"
          role: "code"
        - path: "EasyKeyKit/KeyboardService.swift"
          git_blob: "3d2db069ec81fb639d6eb9a6fc69121580854d31"
          role: "code"
        - path: "EasyEngineCore/Settings/EasyKeySettings.swift"
          git_blob: "b42c58c6e3f1eba416bca3c809ba579441fe87cc"
          role: "history"
      unresolved: []
    - id: "consequences"
      sources:
        - path: "EasyEngineCore/Settings/EasyKeySettings.swift"
          git_blob: "b42c58c6e3f1eba416bca3c809ba579441fe87cc"
          role: "code"
        - path: "EasyKeyApp/Coordination/AppCoordinatorWiring.swift"
          git_blob: "e5b6d9a47e88e742e3b303ec1001d1492538fbb0"
          role: "code"
      unresolved: []
    - id: "confirmation"
      sources:
        - path: "EasyKeyTests/EasyKeySettingsDeltaTests.swift"
          git_blob: "61ffe1c5516c87bd6d62b03162641660483d2d31"
          role: "test"
        - path: "EasyKeyTests/SettingsStoreTests.swift"
          git_blob: "f0012503b72984f8103e11ec188c205a9231e1da"
          role: "test"
        - path: "EasyKeyTests/KeyboardInputPipelineSettingsUpdateTests.swift"
          git_blob: "0407bb4956dd4aea845783d31bbc30517d47b8fe"
          role: "test"
      unresolved: []
---
# 4. Gate keyboard service reconfiguration on a SettingsDelta diff

- **Status:** accepted
- **Date:** 2026-07-23
- **Deciders:** project maintainer

## Context and problem statement

`AppCoordinator` observes the published `settingsStore.$settings` stream and pushes configuration downstream. Before commit d2b1469, any settings publish — even a change with nothing to do with typing, like toggling clipboard persistence — flowed into `KeyboardService.update(settings:)`, which rebuilds the engine configuration and calls `resetSession()`, dropping in-progress Vietnamese composition. A user typing a long phrase lost the composition buffer whenever an unrelated setting changed. The fix ("fix(core): introduce SettingsDelta to gate keyboard service updates on settings changes") introduces `SettingsDelta` so the coordinator can gate each downstream update on the sections that actually changed.

## Considered options

- **Full-settings push on every change** — the behavior before the fix: simple, but resets the engine on unrelated edits.
- **`SettingsDelta` diff computed from old/new settings** — chosen: per-section flags let each consumer decide.
- **Per-field observation** — most precise, but couples the coordinator to every individual setting key.
- **Manual equality checks at each call site** — duplicates the comparison logic in every consumer.

## Decision

We chose **the `SettingsDelta` struct**. `EasyKeySettings.delta(from:to:)` computes one boolean per top-level settings section (`input`, `typing`, `compatibility`, `macro`, `smartSwitch`, `system`, `converter`, `clipboard`, `translation`, `schemaVersion`) plus `hasAnyChange`. In `AppCoordinatorWiring.observeSettings`, the keyboard service is reconfigured only when `inputChanged || typingChanged || compatibilityChanged` (or on first observation), and the macro store's active encoding follows only `inputChanged`. `KeyboardService.update(settings:)` still applies the settings themselves to the engine pipeline; the delta only decides when the update is pushed.

## Decision drivers

- Engine reset on unrelated changes was a real user-visible defect (dropped composition), evidenced by the purpose of commit d2b1469.
- A per-section boolean diff keeps the decision at the coordination layer without leaking it into the engine.
- Consumers with different sensitivity (keyboard service vs. macro store) subscribe to different sections.

## Option comparison

| Option | Good | Neutral | Bad |
|---|---|---|---|
| SettingsDelta diff | one cheap comparison per publish; each consumer gates its own update | new sections must add a delta flag | none observed |
| Full push every change | zero diff logic | — | engine resets composition on unrelated settings edits |
| Per-field observers | maximal precision | — | complex wiring; every new setting adds coordinator surface |
| Ad-hoc equality checks | no new type | — | duplicated, drift-prone comparisons |

## Consequences

**Positive:** typing is no longer interrupted by unrelated settings changes; the keyboard service only reconfigures when input, typing, or compatibility semantics actually changed; `SettingsDelta` is `Equatable`/`Sendable` and unit-tested in isolation.

**Negative:** every future top-level settings section must add a flag to `SettingsDelta` and a call-site decision — forgetting the flag silently degrades to "never update" for that section; the diff is per-section, not per-key, so coarse-grained changes still propagate (the engine reconfiguration cost is low, so this is acceptable).

**Neutral:** `delta` is computed on every settings publish regardless of change — a trivially small cost relative to the work it gates.

## Revisit if

- The settings model gains a section whose changes must be pushed unconditionally (rethink the first-observation rule that bypasses the delta).
- Cross-section coupling appears (a change in one section must trigger work keyed to another).
- Per-key granularity becomes necessary to avoid full-section reconfiguration.

## Confirmation

`EasyKeySettingsDeltaTests` pins the flag computation, `SettingsStoreTests` covers delta behavior across store updates, and `KeyboardInputPipelineSettingsUpdateTests` covers engine reconfiguration on settings updates. All run under `make test`; the 90% line-coverage gate is enforced by `make coverage` and CI.
