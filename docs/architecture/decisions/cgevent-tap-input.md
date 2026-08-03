---
id: "adr-cgevent-tap-input"
title: "Adr Cgevent Tap Input"
docforge_provenance:
  schema: "2.0"
  doc_id: "adr-cgevent-tap-input"
  path: "docs/architecture/decisions/cgevent-tap-input.md"
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
        - path: "README.md"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
          role: "doc"
        - path: "EasyKeyKit/Keyboard/KeyboardEventTap.swift"
          git_blob: "2df63cc191f2509471b02cfad60b8a3113be0933"
          role: "code"
        - path: "EasyKeyKit/KeyboardService.swift"
          git_blob: "3d2db069ec81fb639d6eb9a6fc69121580854d31"
          role: "code"
        - path: "EasyKeyKit/Keyboard/KeyboardEventTap.swift"
          git_blob: "2df63cc191f2509471b02cfad60b8a3113be0933"
          role: "history"
      unresolved: []
    - id: "decision"
      sources:
        - path: "EasyKeyKit/Keyboard/KeyboardEventTap.swift"
          git_blob: "2df63cc191f2509471b02cfad60b8a3113be0933"
          role: "code"
        - path: "EasyKeyKit/KeyboardService.swift"
          git_blob: "3d2db069ec81fb639d6eb9a6fc69121580854d31"
          role: "code"
        - path: "README.md"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
          role: "doc"
      unresolved: []
    - id: "consequences"
      sources:
        - path: "EasyKeyKit/KeyboardService.swift"
          git_blob: "3d2db069ec81fb639d6eb9a6fc69121580854d31"
          role: "code"
        - path: "EasyKeyKit/Keyboard/KeyboardEventTap.swift"
          git_blob: "2df63cc191f2509471b02cfad60b8a3113be0933"
          role: "code"
      unresolved: []
    - id: "confirmation"
      sources:
        - path: "EasyKeyTests/KeyboardEventTapTests.swift"
          git_blob: "34fe9f0d10a99dda28277ea6fe9580099a28da77"
          role: "test"
        - path: "EasyKeyTests/KeyboardServiceIntegrationTests.swift"
          git_blob: "f9fc2b7a29d5360099851ebc6454f799486620c6"
          role: "test"
        - path: "EasyKeyTests/AccessibilityRePromptTests.swift"
          git_blob: "07bc3348a7176166847b29729ccbbbd7b680a834"
          role: "test"
      unresolved: []
---
# 1. Use a CGEvent tap with the macOS Accessibility API for input interception

- **Status:** accepted
- **Date:** 2026-07-18
- **Deciders:** project maintainer

## Context and problem statement

EasyKey is a menu-bar Vietnamese typing utility that must transform keystrokes in every application before the target app receives them: the engine composes Telex/VNI sequences, suppresses the original key, and posts synthesized replacement events. The macOS input architecture makes this hard: ordinary apps only see keystrokes after the input source has handled them, and the system input-method surface (Input Method Kit) binds to a focused text-input client, which an accessory menu-bar app has no reason to hold. The first release (commit 8e480af) therefore shipped a single architecture: observe and mutate keyboard events system-wide through the Accessibility API and a `CGEvent` tap, with typing processed entirely locally. [product overview](../../product/overview.md) states the contract explicitly: "Typing is processed locally. EasyKey uses the macOS Accessibility API and a `CGEvent` tap instead of Input Method Kit."

## Considered options

- **CGEvent tap + Accessibility permission** — the app installs a session event tap and gates it on `AXIsProcessTrusted()`.
- **Input Method Kit (IMK)** — a proper input-method bundle that binds to a focused text-input client.
- **Text services / per-application observation** — transform keystrokes only in cooperating applications.
- **No interception (post-processing)** — transform text only via clipboard or explicit actions.

## Decision

We chose **the CGEvent tap with the Accessibility API**, because EasyKey needs uniform, low-latency, system-wide interception from a single accessory process, and the clean-room engine (EasyEngineCore) is framework-independent. `KeyboardEventTap` installs a `.cgSessionEventTap` at `.headInsertEventTap` on the main run loop, tears it down on sleep or pause, and re-installs on wake; `KeyboardService` owns the permission lifecycle — `requestAccessibilityPermission()` prompts via `AXIsProcessTrustedWithOptions`, `refreshPermission()` re-checks trust and reinstalls the tap, and `handleTapEvent` routes every event through the engine pipeline, returning `nil` to suppress the original when the engine consumed it. (KeyboardEventTap.swift, KeyboardService.swift)

## Decision drivers

- Accessibility permission is an established macOS flow with an explicit privacy disclosure in [product overview](../../product/overview.md).
- The pipeline must inspect and optionally suppress every key event system-wide — of the options considered, only a CGEvent tap allows both.
- The engine lives in a pure domain module with no AppKit dependency, so the input path is a thin adapter that stays testable without an IMK bundle lifecycle.

## Option comparison

| Option | Good | Neutral | Bad |
|---|---|---|---|
| CGEvent tap + Accessibility | system-wide coverage, full suppression and synthesis, one process | requires an Accessibility trust prompt at first launch | tap can be disabled by the system after prolonged user input; callback runs on the main thread |
| Input Method Kit | first-class input-method integration, no Accessibility prompt | — | requires binding to a focused input client — fragile for an accessory app |
| Text services / per-app observation | no system-wide permission | — | cannot cover apps that do not expose text services |
| Post-processing only | simplest, zero permissions | — | cannot correct keystrokes as they are typed; fails the core requirement |

## Consequences

**Positive:** every keystroke passes through one deterministic pipeline regardless of the frontmost application; composition state, pause, and diagnostics live in one process; typing stays fully local as promised in the privacy story.

**Negative:** the user must grant Accessibility access or the app stays stopped/requesting; the tap is a system-managed resource — after `.tapDisabledByTimeout` or `.tapDisabledByUserInput` the tap must be torn down, permission re-checked, and reinstalled (`recoverTapAfterDisable` in KeyboardService.swift), and because the callback runs on the main thread, per-event work must stay bounded.

**Neutral:** permission state is now part of app health (`stopped`, `requestingPermission`, `active`, `degraded`, `failed`) and surfaces in the status item — a shift from "always on" to "active only while trusted".

## Revisit if

- The system starts disabling the tap frequently (recovery churn) or Apple changes event-tap entitlements.
- An IMK-based distribution becomes necessary (for example if macOS restricts event taps on future releases).
- The app must express per-app input-source switching that only IMK can provide.

## Confirmation

`KeyboardEventTapTests` covers tap lifecycle installation and teardown, `KeyboardServiceIntegrationTests` covers permission refresh paths (trusted, untrusted, wake), and `AccessibilityRePromptTests` pins the prompt and recovery behavior. These run under `make test`; the 90% line-coverage gate is enforced by `make coverage` and CI.
