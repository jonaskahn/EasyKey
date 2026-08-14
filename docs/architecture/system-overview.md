---
id: "system_overview"
title: "System Overview"
description: "Major capabilities, the components each touches and its owning flow, the primary end-to-end path tying features together, and the boundary systems"
docforge_provenance:
  schema: "2.1"
  doc_id: "system_overview"
  path: "docs/architecture/system-overview.md"
  generated_at: "2026-08-13T11:10:56Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "deep-dive"
  graph:
    provider: "codegraph"
    flow: "derived"
  sections:
    - id: "system-overview"
      sources:
        - path: "docs/architecture/high-level.md"
          role: "doc"
          git_blob: "ac229c696ba34750987a45df2e80762926d77a01"
          git_blob_normalized: "ac229c696ba34750987a45df2e80762926d77a01"
        - path: "docs/flows/README.md"
          role: "doc"
          git_blob: "83492bedf226fa49c62e8290fd14fd6fe6b62f89"
        - path: ".docforge/tmp/flow-graph.json"
          role: "manifest"
          git_blob: "908611da74a9394034e0444c761481351d43ad08"
      unresolved: []
    - id: "primary-end-to-end-path"
      sources:
        - path: "docs/flows/keyboard-typing.md"
          role: "doc"
          git_blob: "7f6cbe5904aba625eefd8c3b826e64c9614ee76f"
        - path: "EasyKeyKit/Keyboard/KeyboardEventTap.swift"
          role: "code"
          git_blob: "afd7e07bf098c7400aaccab85a72e77fac8a936d"
        - path: "EasyEngineCore/Engine/VietnameseEngine.swift"
          role: "code"
          git_blob: "35a0190749c2ea1c5c37e5bd2c3bfed96f69fc03"
        - path: "EasyKeyKit/Keyboard/Synthesis/KeySynthesizer.swift"
          role: "code"
          git_blob: "d9d56d371db322150cd74a358258fe7243989bab"
      unresolved: []
    - id: "feature-owning-flow-subsystem"
      sources:
        - path: "docs/flows/README.md"
          role: "doc"
          git_blob: "83492bedf226fa49c62e8290fd14fd6fe6b62f89"
        - path: ".docforge/tmp/flow-graph.json"
          role: "manifest"
          git_blob: "908611da74a9394034e0444c761481351d43ad08"
        - path: "docs/architecture/high-level.md"
          role: "doc"
          git_blob: "ac229c696ba34750987a45df2e80762926d77a01"
          git_blob_normalized: "ac229c696ba34750987a45df2e80762926d77a01"
      unresolved: []
---
# System overview

_Last reviewed: 2026-08-13_

EasyKey is a macOS menu-bar utility with three main-priority capabilities: Vietnamese keyboard typing transformation (Telex/Simple Telex/VNI) that runs entirely on the machine through a session-wide CGEvent tap; a private clipboard history manager whose capture is memory-only by default with opt-in encrypted persistence; and translation through Apple's on-device framework (macOS 15+) or user-configured cloud providers. Typing and clipboard content never cross a network boundary; the only outbound calls are translation requests from explicit translation surfaces and the Sparkle update check. Component detail per capability lives in [high-level.md](high-level.md) and [low-level.md](low-level.md); this page routes to the flows.

```mermaid
flowchart LR
  User["User (keyboard, menu bar, hotkeys)"] --> EasyKey["EasyKey (macOS menu-bar utility)"]
  EasyKey -->|"CGEvent tap / AXUIElement"| MacOS["macOS input pipeline"]
  EasyKey -->|"SecItem device-only"| Keychain["User Keychain"]
  EasyKey -->|"HTTPS translate (optional)"| Providers["Cloud translation providers"]
  EasyKey -->|"HTTPS appcast"| Feed["Sparkle update feed"]
```

## Primary end-to-end path

The journey a newcomer should trace first is a keystroke becoming Vietnamese text: it crosses the most capabilities — the event tap, the pipeline's shortcut/compatibility gates, the Telex/VNI engine, synthesis back into the target application — and it is the only path every other feature orbits. Trace it in [keyboard-typing.md](../flows/keyboard-typing.md).

```mermaid
sequenceDiagram
  participant User as User
  participant Tap as CGEvent tap (EasyKeyKit)
  participant Pipeline as KeyboardInputPipeline
  participant Engine as VietnameseEngine + KeySynthesizer
  participant Target as Target application
  User->>Tap: types "tuyen"
  Tap->>Pipeline: handleTapEvent(keyDown)
  Pipeline->>Engine: process(KeyEvent)
  Engine-->>Pipeline: EngineOutput (backspace + Vietnamese text)
  Pipeline-->>Tap: suppress original keystroke
  Engine->>Target: synthesized edits via tapPostEvent
```

## Feature → owning flow → subsystem

_One row per major capability — enough for a newcomer to find their way, not the
full feature list. Rows marked "indexed, deferred" are evidenced in the flow
index but have no deep-dive flow document yet._

| Capability | Owning flow | Implementing subsystem |
|---|---|---|
| Vietnamese keyboard typing (Telex/Simple Telex/VNI) | [keyboard-typing](../flows/keyboard-typing.md) | EasyKeyKit (event tap, pipeline, synthesis) + EasyEngineCore (`VietnameseEngine`) |
| Clipboard history capture, persistence, restore | [clipboard-history](../flows/clipboard-history.md) | EasyKeyApp (`ClipboardMonitor`, `ClipboardHistoryModel`) |
| Translation via on-device or cloud providers | [translation](../flows/translation.md) | EasyKeyApp (`AppTranslationRuntime`) |
| Per-application language Smart Switch | [indexed, deferred](../flows/README.md) | EasyKeyApp (`SmartSwitchController`) + EasyEngineCore |
| Macro expansion from triggers | [indexed, deferred](../flows/README.md) | EasyKeyKit (`KeyboardMacroExpander`) + EasyEngineCore |
| Launch-at-login registration and watchdog | [indexed, deferred](../flows/README.md) | EasyKeyApp (`LoginItemController`) + `EasyKeyLoginHelper` |
| Sparkle app updates | [indexed, deferred](../flows/README.md) | EasyKeyApp (`UpdateService`) |

Link out to [`docs/flows/README.md`](../flows/README.md) for the full matrix;
do not duplicate its rows.
