---
id: "arch_high_level"
title: "Arch High Level"
docforge_provenance:
  schema: "2.0"
  doc_id: "arch_high_level"
  path: "docs/architecture/high-level.md"
  generated_at: "2026-08-03T10:00:00Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "orientation"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "high-level-architecture"
      sources:
        - path: "README.md"
          role: "doc"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
        - path: "EasyKeyApp/Info.plist"
          role: "config"
          git_blob: "f4603871fa675111bd6db1472dfb04936ff3f645"
      unresolved: []
    - id: "system-in-context"
      sources:
        - path: "EasyKeyApp/AppDelegate.swift"
          role: "code"
          git_blob: "8ecc5922afe0e99166cbcf3425afd2514b887ae2"
        - path: "EasyKeyApp/UpdateService.swift"
          role: "code"
          git_blob: "27386d368017c0c64f38e75fbd5e23e62c7a4dd6"
        - path: "EasyKeyApp/Features/Translation/AppTranslationRuntime.swift"
          role: "code"
          git_blob: "c4df84fdde3f664cd167d91ce3a64b387e6ef30e"
      unresolved: []
    - id: "containers-and-blackboxes"
      sources:
        - path: "EasyKey.xcodeproj/project.pbxproj"
          role: "config"
          git_blob: "3fc1f4a80e4851be8a519efbb99f80102a4b41d4"
        - path: "EasyKeyLoginHelper/main.swift"
          role: "code"
          git_blob: "f0f724c4c8a6644555990bff4e08325f80625a66"
        - path: "EasyKeyApp/AppCoordinator.swift"
          role: "code"
          git_blob: "64de70b72c5fac1e218063377a05fbd4fb6adafa"
      unresolved: []
    - id: "relationship-matrix"
      sources:
        - path: "EasyKeyApp/Coordination/AppCoordinatorWiring.swift"
          role: "code"
          git_blob: "e5b6d9a47e88e742e3b303ec1001d1492538fbb0"
        - path: "EasyKeyKit/KeyboardService.swift"
          role: "code"
          git_blob: "3d2db069ec81fb639d6eb9a6fc69121580854d31"
        - path: "EasyEngineCore/Engine/VietnameseEngine.swift"
          role: "code"
          git_blob: "ce4d89e4d4d777c094e6bb2db46da198fae68c52"
      unresolved: []
    - id: "boundaries-and-invariants"
      sources:
        - path: "EasyKeyApp/EasyKeyApp.entitlements"
          role: "config"
          git_blob: "e89b7f323cf06c0f693e45a878b20d54db92e85c"
        - path: "EasyEngineCore/Clipboard/ClipboardOptions.swift"
          role: "code"
          git_blob: "f1409bbfebea82ad1d8e76ec6d75612f0b1b7a93"
        - path: "EasyKeyApp/Features/Clipboard/ClipboardPersistence.swift"
          role: "code"
          git_blob: "2f2f6e1c7c03071c95010c565309b55a06b15c34"
        - path: "EasyKeyApp/AppCoordinator.swift"
          role: "code"
          git_blob: "64de70b72c5fac1e218063377a05fbd4fb6adafa"
        - path: "README.md"
          role: "doc"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
      unresolved: []
    - id: "stable-by-design"
      sources:
        - path: "README.md"
          role: "doc"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
        - path: "docs/architecture/decisions/README.md"
          role: "doc"
          git_blob: "6f0b80df275ccf5bd2bdf030d5f86daa7d9d18cf"
      unresolved: []
    - id: "why-it-is-like-this"
      sources:
        - path: "docs/architecture/decisions/README.md"
          role: "doc"
          git_blob: "6f0b80df275ccf5bd2bdf030d5f86daa7d9d18cf"
        - path: "docs/architecture/tech-debt.md"
          role: "doc"
          git_blob: "413d6c52fc6560568453ef5b6cb6f5dcbf78e575"
        - path: "docs/architecture/constraints.md"
          role: "doc"
          git_blob: "d57bfc3d6113872611941d5248978223c80a3bad"
      unresolved: []
---
# High-level architecture

_Last reviewed: 2026-08-03_

EasyKey is a macOS menu-bar utility that turns raw keystrokes into Vietnamese text (Telex, Simple Telex, and VNI rule sets), keeps a private clipboard history, and translates selected or typed text through on-device or cloud providers. It owns the "type Vietnamese in any application, with per-application preferences, without a telemetry trail" capability: transformation runs entirely on the Mac, the app behaves as a menu-bar accessory (`LSUIElement`), and it is distributed as a universal DMG with Sparkle updates.

## System in context

_C4 context view: this system as one box among the actors and services around it — name the neighbors and the contracts between them, never the internals._

EasyKey sits between the user and the macOS input pipeline. The user interacts through the menu-bar status item, popovers, a Settings window, and configurable hotkeys. The system consumes keyboard events system-wide via a `CGEvent` tap and reads/writes focused text through the Accessibility API — the same trust boundary that gates the entire typing feature. It persists user data only to the local filesystem and the user's Keychain. It makes two optional outbound network calls: to a cloud translation provider (never for typing itself) and to an HTTPS Sparkle appcast for updates.

```mermaid
flowchart LR
  User["User (keyboard, menu bar, hotkeys)"] --> EasyKey["EasyKey (macOS menu-bar utility)"]
  EasyKey -->|"CGEvent tap / AXUIElement"| MacOS["macOS input pipeline"]
  EasyKey -->|"SecItem device-only"| Keychain["User Keychain"]
  EasyKey -->|"HTTPS translate API"| Providers["Cloud translation providers (optional)"]
  EasyKey -->|"HTTPS appcast"| Appcast["Sparkle update feed"]
```

What crosses each boundary: keystrokes and focused-text edits in both directions with macOS (the event tap suppresses originals and the app posts synthesized edits); credentials and the clipboard history key into the Keychain (never synchronized); source text plus language pair to a cloud provider only when the user translates and a provider is configured; a signed DMG metadata feed from the Sparkle appcast. Typing itself crosses no network boundary.

## Containers and blackboxes

_C4 container view: the deployable pieces inside that one box — never mix this zoom level with the context diagram above._

Five deployable pieces make up the app: three in-process Swift targets, one embedded login item, and one framework the app bundles. Component-level mechanism lives in [low-level.md](low-level.md); deep subsystem write-ups live under [concepts/](concepts/README.md).

_One row per block that matters for orientation. Technology cites [tech-stack.md](../reference/tech-stack.md)._

| Block | Responsibility | Technology | External interface | Boundary it owns |
|---|---|---|---|---|
| EasyKeyApp | Runs the menu-bar presence, Settings scene, clipboard manager, translation runtime, and all coordination wiring | SwiftUI + AppKit | `NSStatusItem`, `NSPopover`, Settings window, Carbon hotkeys, `NSWorkspace` notifications | Orchestration and user-facing state |
| EasyKeyKit | Owns system input plumbing: event tap, input pipeline, key synthesis, focused-text replacement, per-app compatibility | CoreGraphics, ApplicationServices, Foundation | `CGEvent` tap, `AXUIElement` | Everything that touches the keyboard/AX boundary |
| EasyEngineCore | Framework-free domain: Vietnamese engine (Telex/VNI), settings model, macros, Smart Switch, converter, clipboard policy, translation contracts | Pure Swift (Foundation only) | None (in-process calls) | Typing rules, settings schema, persistence formats |
| EasyKeyLoginHelper | Launches the host app at login if it is not already running | AppKit, ServiceManagement | SMAppService login item | Host-launch guarantee and integrity checks |
| Sparkle (bundled) | Delivers signed updates from an HTTPS appcast | Sparkle 2.9.4 (SPM) | `SPUStandardUpdaterController` | Update lifecycle and EdDSA verification |

## Relationship matrix

_One row per material edge between blocks, or between a block and an external actor — directional, one specific active verb._

| Origin | Destination | Action | Protocol / channel |
|---|---|---|---|
| User | EasyKeyApp | triggers (left-click, hotkeys, menu items) | `NSStatusItem` events, Carbon hotkeys, `NSPopover` clicks |
| EasyKeyApp | EasyKeyKit | starts/stops, pushes settings and macros | direct in-process calls (`KeyboardService`) |
| EasyKeyKit | EasyEngineCore | feeds `KeyEvent`s, reads `EngineConfiguration` | direct in-process calls (`VietnameseEngine`) |
| EasyKeyKit | macOS | installs event tap, reads/replaces focused text | `CGEvent` + `AXUIElement` |
| EasyKeyApp | Keychain | stores/loads credentials and history key | `SecItem` (device-only, non-sync) |
| EasyKeyApp | Cloud providers | sends translation requests | HTTPS JSON via `URLSession` |
| EasyKeyApp | Sparkle appcast | polls for updates | HTTPS RSS via `SPUStandardUpdaterController` |

## Boundaries and invariants

- **Typing is local, always.** Keyboard transformation and preferences are processed on the Mac; general keyboard input is never translated or uploaded ([README.md](../README.md)).
- **The main app is not sandboxed.** `com.apple.security.app-sandbox` is `false` for EasyKeyApp — required for the session-wide event tap, the Sparkle updater, and the login helper contract. The login helper itself runs sandboxed.
- **Clipboard capture is off by default** (`isCaptureEnabled = false`), and persistence is opt-in: history stays in memory unless the user enables it, in which case it is AES-GCM sealed with a device-only Keychain key.
- **Single instance.** A second launch detects the running instance and terminates itself.
- **Cloud translation is opt-in per provider.** Source text leaves the device only from explicit translation surfaces when a provider is configured; credentials live in the Keychain and are never synchronized.
- **No telemetry.** The app ships no analytics; logging is local and redacted ([log-redaction](decisions/log-redaction.md)).

## Stable by design

This document changes once or twice a year: blocks are named at the level of targets and responsibilities, not classes. A claim here that a routine refactor would falsify — e.g. exactly which component posts a synthesized key — is written too close to the code and belongs in [low-level.md](low-level.md). Per-app compatibility rules, spotlight workarounds, and event-mask details live there and in [PROBLEMS.md](../reference/limitations.md), not here.

## Why it is like this

Rationale for the architecture choices — the event-tap approach instead of Input Method Kit, single-instance enforcement, the encrypted clipboard, settings deltas, Sparkle updates — lives in the [decision log](decisions/README.md). Known shortcuts are tracked in [tech-debt.md](tech-debt.md). Hard, externally imposed bounds (macOS 14 target, Accessibility requirement, sandbox constraint) live in [constraints.md](constraints.md).
