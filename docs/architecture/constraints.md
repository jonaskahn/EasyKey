---
id: "architecture_constraints"
title: "Architecture Constraints"
description: "Hard bounds with source and design implication; deliberate non-goals"
docforge_provenance:
  schema: "2.0"
  doc_id: "architecture_constraints"
  path: "docs/architecture/constraints.md"
  generated_at: "2026-08-13T11:08:46Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "deep-dive"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "architectural-constraints"
      sources:
        - path: "README.md"
          role: "doc"
          git_blob: "adbd4f30d3c2f11bb855e6645195493a6c6a34f7"
      unresolved: []
    - id: "ceilings"
      sources:
        - path: "EasyKey.xcodeproj/project.pbxproj"
          role: "config"
          git_blob: "515597131540b043af2543b4d881e1509bbe8c40"
        - path: "EasyKeyApp/EasyKeyApp.entitlements"
          role: "config"
          git_blob: "e89b7f323cf06c0f693e45a878b20d54db92e85c"
        - path: "EasyKeyApp/Coordination/UpdateService.swift"
          role: "code"
          git_blob: "27386d368017c0c64f38e75fbd5e23e62c7a4dd6"
        - path: "EasyKeyKit/Keyboard/KeyboardService.swift"
          role: "code"
          git_blob: "3246c7e678b841077f3006877c3b2ead836e912b"
        - path: "EasyKeyApp/Features/Translation/AppTranslationRuntime.swift"
          role: "code"
          git_blob: "4f6f75d8aa093c688ec77d6722ba0cc62769b87d"
        - path: "EasyKeyApp/Features/Clipboard/ClipboardKeyStore.swift"
          role: "code"
          git_blob: "8308409cb0bb907254e169b15dd74b9304399ed3"
        - path: "EasyKeyApp/Features/Translation/TranslationCredentialStore.swift"
          role: "code"
          git_blob: "768aab956a8d02978101105e7a896b6d55c75376"
        - path: "EasyKeyKit/Keyboard/SpotlightWindowDetector.swift"
          role: "code"
          git_blob: "ab9966a65dc3f038110c81f2081fd81816599885"
        - path: "docs/reference/limitations.md"
          role: "doc"
          git_blob: "8e3e23bf6b098a52db5efcd4e4328dfea588b6e1"
      unresolved: []
    - id: "boundaries"
      sources:
        - path: "EasyKeyApp/Coordination/AppCoordinator.swift"
          role: "code"
          git_blob: "815b5dad186802739e0969eb509af2469570b583"
        - path: "EasyKeyLoginHelper/main.swift"
          role: "code"
          git_blob: "f0f724c4c8a6644555990bff4e08325f80625a66"
        - path: "README.md"
          role: "doc"
          git_blob: "adbd4f30d3c2f11bb855e6645195493a6c6a34f7"
      unresolved: []
    - id: "non-goals"
      sources:
        - path: "docs/architecture/decisions/cgevent-tap-input.md"
          role: "doc"
          git_blob: "ac1023240f0b8125e506db14e142563f83acd5a3"
        - path: "EasyKeyApp/EasyKeyApp.entitlements"
          role: "config"
          git_blob: "e89b7f323cf06c0f693e45a878b20d54db92e85c"
        - path: "README.md"
          role: "doc"
          git_blob: "adbd4f30d3c2f11bb855e6645195493a6c6a34f7"
      unresolved: []
---
# Architectural constraints

_Last reviewed: 2026-08-13_

The hard limits this architecture imposes by design, and the things it deliberately does not do. These are ceilings and boundaries, not defects — stating them prevents wasted effort and sets honest expectations under review.

## Ceilings

_A bound without a traceable source reads as an opinion, not a fact a reviewer can verify._

| Constraint | Limit | Source | Why it exists | What lifting it would take |
|---|---|---|---|---|
| Deployment target | macOS 14.0 minimum (`MACOSX_DEPLOYMENT_TARGET = 14.0` in the project build settings, mirrored by `LSMinimumSystemVersion` in the app's Info.plist) | `EasyKey.xcodeproj/project.pbxproj` | Broad reach for a utility app | Bumping the target re-signs the appcast `minimumSystemVersion` and drops older macOS support |
| On-device Apple Translation | Available only on macOS 15+ | `AppTranslationRuntime.Dependencies.production` availability guard | The `Translation` framework ships with macOS 15 | None — OS capability; cloud providers cover macOS 14 |
| Accessibility trust | Mandatory: the event tap and AX text replacement require the process to be Accessibility-trusted (`AXIsProcessTrusted`) | `EasyKeyKit/Keyboard/KeyboardService.swift` | macOS requires user consent for system-wide keyboard observation | Switching to Input Method Kit (deliberately not chosen, see decision `cgevent-tap-input`) |
| Sandbox | Main app is **not** sandboxed (`com.apple.security.app-sandbox = false`) | `EasyKeyApp/EasyKeyApp.entitlements` | Session event tap, Sparkle, and login-helper launch need non-sandboxed access; only the login helper is sandboxed | App Store distribution — not on the roadmap |
| Sparkle feed | `SUFeedURL` must be HTTPS and `SUPublicEDKey` non-empty at runtime, else the updater disables itself | `EasyKeyApp/Coordination/UpdateService.swift` (`hasReleaseConfiguration`) | Signed updates only; no silent unauthenticated update path | None — this is the intended safety posture |
| Keychain scope | All EasyKey items are device-only and non-synchronizing (`kSecAttrSynchronizable = false`, `WhenUnlockedThisDeviceOnly`) | `EasyKeyApp/Features/Clipboard/ClipboardKeyStore.swift`, `EasyKeyApp/Features/Translation/TranslationCredentialStore.swift` | Clipboard history and provider keys must not roam or leave the device | Enabling iCloud Keychain sync would trade privacy for convenience — not planned |
| Clipboard history | Capture off by default; defaults cap 100 entries / 7-day retention | `EasyEngineCore/Clipboard/ClipboardOptions.swift` | Privacy-first posture; user-raised limits | User-configurable already; no hard ceiling |
| Single instance | One process per user session; a second launch terminates | `EasyKeyApp/Coordination/AppCoordinator.swift` (`isOnlyInstanceForCurrentUser`) + decision `single-instance` | One event tap; avoids duplicate key handling | Multi-instance support — not planned |
| Spotlight typing | Inherently degraded: no public API for Spotlight's internal focus/completion; EasyKey polls `CGWindowListCopyWindowInfo` with a 0.3 s detection lag | `docs/reference/limitations.md`, `EasyKeyKit/Keyboard/SpotlightWindowDetector.swift` | Platform limitation imposed by Apple's Spotlight implementation | None — outside EasyKey's control |

## Boundaries

What this system assumes about its environment and inputs — the assumptions that, if violated, break it.

- **A logged-in GUI user session.** Everything — status item, event tap, hotkeys, login item — assumes an active user with a window server. There is no daemon or headless mode.
- **Accessibility trust granted.** Without it the typing feature is entirely unavailable (health stays `requestingPermission`); every other feature still works.
- **Frontmost-application model.** Per-app behavior (Smart Switch, compatibility, ignore lists) is driven by `NSWorkspace` activation events; apps that never activate (Spotlight) fall back to window-polling heuristics.
- **Host bundle layout.** The login helper walks exactly four path components up from `Contents/Library/LoginItems/` to reach the host `.app` and validates its bundle identifier — moving the helper breaks the launch contract.
- **User Keychain available.** Persisted clipboard history and provider credentials are unrecoverable without it; decryption failure degrades to an empty in-memory history, not a crash.
- **No network needed for typing.** The core feature is offline; only translation and update checks touch the network.
- **Provider data leaves under provider terms.** Text submitted to a cloud provider is handled under that provider's own terms ([data-handling](../security/data-handling.md)); EasyKey does not proxy or store it.

## Non-goals

What this system deliberately does not do, and which component does it instead. A reasonable person might expect these; say plainly that they are out of scope.

- **No Input Method Kit implementation.** The system uses a `CGEvent` tap + Accessibility instead, so it is not a selectable system input method and cannot be used on the macOS login screen or in password fields by design (decision [cgevent-tap-input](decisions/cgevent-tap-input.md)).
- **No analytics or telemetry.** There is no tracking SDK, no usage reporting; logging is local and redacted (decision [log-redaction](decisions/log-redaction.md)).
- **No translation proxy/relay service.** Cloud translation calls go directly from the app to the chosen provider; there is no EasyKey-operated server in the path.
- **No sandboxed / App Store build.** The main app's sandbox entitlement is explicitly disabled; distribution is signed DMG + Sparkle only.
- **No clipboard capture by default.** Capture is opt-in per user; even enabled, concealed/transient/auto-generated content is rejected.
- **No cloud sync of settings, macros, or history.** Persistence is local files plus the device-only Keychain; no sync service exists.
- **No background daemon mode.** The app is a menu-bar accessory; it does not run as a launchd agent beyond its login item.

_Distinct from [tech-debt.md](tech-debt.md) (shortcuts to be paid down) and [limitations](../reference/limitations.md) (feature gaps). Cross-link; do not duplicate._
