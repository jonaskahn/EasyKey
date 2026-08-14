---
id: "adr-cgevent-tap-input"
title: "Adr Cgevent Tap Input"
description: "Decision: intercept keystrokes system-wide with a CGEvent tap gated on the macOS Accessibility API instead of Input Method Kit."
docforge_provenance:
  schema: "2.0"
  doc_id: "adr-cgevent-tap-input"
  path: "docs/architecture/decisions/cgevent-tap-input.md"
  generated_at: "2026-08-13T11:25:23Z"
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
          git_blob: "0de1699403dbb6d0d24b58a2963cde1ac952a70e"
          role: "doc"
        - path: "docs/product/overview.md"
          git_blob: "f71493c7ff2b280378f4ce271a3a4104cb576aa1"
          git_blob_normalized: "f71493c7ff2b280378f4ce271a3a4104cb576aa1"
          role: "doc"
        - path: "EasyKeyKit/Keyboard/KeyboardEventTap.swift"
          git_blob: "afd7e07bf098c7400aaccab85a72e77fac8a936d"
          role: "code"
        - path: "EasyKeyKit/Keyboard/KeyboardService.swift"
          git_blob: "3246c7e678b841077f3006877c3b2ead836e912b"
          role: "code"
        - path: "EasyKeyKit/Keyboard/KeyboardService.swift"
          git_blob: "3246c7e678b841077f3006877c3b2ead836e912b"
          role: "history"
      unresolved: []
    - id: "decision"
      sources:
        - path: "EasyKeyKit/Keyboard/KeyboardEventTap.swift"
          git_blob: "afd7e07bf098c7400aaccab85a72e77fac8a936d"
          role: "code"
        - path: "EasyKeyKit/Keyboard/KeyboardService.swift"
          git_blob: "3246c7e678b841077f3006877c3b2ead836e912b"
          role: "code"
        - path: "README.md"
          git_blob: "0de1699403dbb6d0d24b58a2963cde1ac952a70e"
          role: "doc"
      unresolved: []
    - id: "consequences"
      sources:
        - path: "EasyKeyKit/Keyboard/KeyboardService.swift"
          git_blob: "3246c7e678b841077f3006877c3b2ead836e912b"
          role: "code"
        - path: "EasyKeyKit/Keyboard/KeyboardEventTap.swift"
          git_blob: "afd7e07bf098c7400aaccab85a72e77fac8a936d"
          role: "code"
      unresolved: []
    - id: "confirmation"
      sources:
        - path: "EasyKeyTests/KeyboardEventTapTests.swift"
          git_blob: "34fe9f0d10a99dda28277ea6fe9580099a28da77"
          role: "test"
        - path: "EasyKeyTests/KeyboardServiceIntegrationTests.swift"
          git_blob: "26ed22b3c0375603aec217223dcbfe9fd9c0f632"
          role: "test"
        - path: "EasyKeyTests/AccessibilityRePromptTests.swift"
          git_blob: "110dd186b210bffd474dddc7e3513ea2643eaf8c"
          role: "test"
      unresolved: []
---
# 1. Use a CGEvent tap with the macOS Accessibility API for input interception

- **Status:** accepted
- **Date:** 2026-07-18
- **Deciders:** project maintainer

## Context and problem statement

EasyKey is a menu-bar Vietnamese typing utility that must transform keystrokes in every application before the target app receives them: the engine composes Telex/VNI sequences, suppresses the original key, and posts synthesized replacement events. The macOS input architecture makes this hard: ordinary apps only see keystrokes after the input source has handled them, and the system input-method surface (Input Method Kit) binds to a focused text-input client, which an accessory menu-bar app has no reason to hold. The first release (commit 8e480af) therefore shipped a single architecture: observe and mutate keyboard events system-wide through the Accessibility API and a `CGEvent` tap, with typing processed entirely locally. The [README](../../../README.md) "Private by Design" section states everything is processed on the Mac with no analytics, telemetry, or typing logs, and [product overview](../../product/overview.md) describes the mechanism: EasyKey observes the keyboard through the macOS Accessibility API (the one permission it requires) and rewrites keystrokes into correctly marked Vietnamese text, app by app.

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
