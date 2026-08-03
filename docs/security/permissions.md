---
id: "platform_permissions"
title: "Platform Permissions"
docforge_provenance:
  schema: "2.0"
  doc_id: "platform_permissions"
  path: "docs/security/permissions.md"
  generated_at: "2026-08-03T08:45:41Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "deep-dive"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "accessibility-keyboard-event-tap"
      sources:
        - path: "EasyKeyKit/KeyboardService.swift"
          git_blob: "3d2db069ec81fb639d6eb9a6fc69121580854d31"
          role: "code"
        - path: "EasyKeyKit/Keyboard/KeyboardEventTap.swift"
          git_blob: "2df63cc191f2509471b02cfad60b8a3113be0933"
          role: "code"
        - path: "EasyKeyApp/Features/Onboarding/OnboardingView.swift"
          git_blob: "6607f26cd0e27f49ac6d0e77492557411063e170"
          role: "code"
        - path: "EasyKeyApp/Features/Settings/System/SystemHealthCard.swift"
          git_blob: "5fe0c69e5c0be68ba8d102710418aeade56f6c0f"
          role: "code"
        - path: "EasyKeyApp/Coordination/AppCoordinatorWiring.swift"
          git_blob: "e5b6d9a47e88e742e3b303ec1001d1492538fbb0"
          role: "code"
      unresolved: []
    - id: "login-item-smappservice"
      sources:
        - path: "EasyKeyApp/Coordination/LoginItemController.swift"
          git_blob: "7833a6d82792ded3986386ac26e40b686feab12d"
          role: "code"
        - path: "EasyKeyLoginHelper/main.swift"
          git_blob: "f0f724c4c8a6644555990bff4e08325f80625a66"
          role: "code"
      unresolved: []
    - id: "network-clients-translation-and-update-no-system-prompt"
      sources:
        - path: "EasyKeyApp/Features/Translation/TranslationProviding.swift"
          git_blob: "5c70817f7b83a111395b771d818f235db64e39c1"
          role: "code"
        - path: "EasyKeyApp/Features/Translation/GoogleTranslationProvider.swift"
          git_blob: "a58ea2ffd3149408365009e036353d1c130b3056"
          role: "code"
        - path: "EasyKeyApp/UpdateService.swift"
          git_blob: "27386d368017c0c64f38e75fbd5e23e62c7a4dd6"
          role: "code"
        - path: "EasyKeyApp/Info.plist"
          git_blob: "f4603871fa675111bd6db1472dfb04936ff3f645"
          role: "config"
      unresolved: []
    - id: "capabilities-without-system-prompts"
      sources:
        - path: "EasyKeyApp/Features/Clipboard/ClipboardMonitor.swift"
          git_blob: "b554c2a511999b5eab5b545232bd3fc2c8cedf76"
          role: "code"
        - path: "EasyKeyApp/Features/Clipboard/ClipboardServices.swift"
          git_blob: "b9179d71d130b93c4f9f9dbe198eb5153be42637"
          role: "code"
        - path: "EasyKeyApp/EasyKeyApp.entitlements"
          git_blob: "e89b7f323cf06c0f693e45a878b20d54db92e85c"
          role: "config"
        - path: "EasyKeyApp/Info.plist"
          git_blob: "f4603871fa675111bd6db1472dfb04936ff3f645"
          role: "config"
      unresolved: []
---
# Permissions

_Last reviewed: 2026-08-03_

EasyKey requests exactly one TCC-gated capability — Accessibility — and
registers one login item. Everything else it touches (pasteboard, network,
files) is ungated on macOS and is listed below with its manifest evidence so
reviewers can see both halves of the picture. Threats and controls around these
capabilities are in [threat-model.md](threat-model.md).

## Accessibility — keyboard event tap

**Requested at:** first launch, from onboarding (`OnboardingView` calls
`coordinator.requestAccessibilityPermission()`); afterwards from the System
Health card whenever health is `.requestingPermission`; permission is
re-checked (`refreshPermission`) on every application activation, workspace
wake, and status-item popover open.

**User value:** system-wide Vietnamese typing transformation and macro
expansion (session event tap in any frontmost application), plus synthesized
paste for clipboard actions (`ClipboardServices.synthesizePaste`).

**On denial:** the tap is never installed; health is set to
`.requestingPermission`; the menu bar and System settings surface a
"Grant Accessibility" action that re-raises the system prompt
(`AXIsProcessTrustedWithOptions` with prompt). Typing continues untransformed.

**On later revocation:** `refreshPermission` detects `AXIsProcessTrusted() ==
false`, tears down the installed tap, and moves health to
`.requestingPermission`; the app keeps running with the grant button available.
The tap also self-recovers from `tapDisabledByTimeout` /
`tapDisabledByUserInput` (e.g. login windows) by reinstalling on the next
opportunity.

**Change later:** System Settings → Privacy & Security → Accessibility.

**Evidence:** `KeyboardService.swift` (`requestAccessibilityPermission`,
`refreshPermission`, `startIfPermitted`); `KeyboardEventTap.swift`
(`CGEvent.tapCreate` session tap, install/teardown, sleep/wake observers);
`OnboardingView.swift`; `SystemHealthCard.swift`; `AppCoordinatorWiring.swift`
(per-activation refresh). No other permission is declared or requested.

## Login item (SMAppService)

**Requested at:** explicit settings action — the launch-at-login toggle calls
`LoginItemController.configure(enabled:)`, which registers or unregisters
`SMAppService.loginItem(identifier: AppIdentifiers.loginHelper)`.

**User value:** restarts EasyKey at login through a dedicated helper
(`EasyKeyLoginHelper`) that validates the host bundle before launching it.

**On denial:** registration is either unsupported (`.notFound` →
`.unsupported`) or failed (`.failed`); the status is surfaced in the settings
UI and the app continues.

**On later revocation:** turning the toggle off unregisters the login item;
`status` reflects the live `SMAppService` state after each call.

**Change later:** EasyKey settings, or System Settings → General → Login Items.

**Evidence:** `LoginItemController.swift` (register/unregister, status
mapping); `EasyKeyLoginHelper/main.swift` (host URL and bundle validation,
host-running check, 3-second watchdog, team-identifier check in non-debug
builds).

## Network clients (translation and update) — no system prompt

**Requested at:** translation, when the user enables a provider and triggers a
translation from a translation surface; updates, when Sparkle starts at app
launch or on the explicit "Check for Updates" menu action.

**User value:** opt-in cloud translation and signed automatic updates.

**On denial:** there is no TCC gate for outbound network on macOS; failures
surface as typed errors (`networkUnavailable`, `requestTimedOut`,
`providerUnavailable`), and a failed update check leaves the app fully
functional.

**On later revocation:** not applicable — no system-granted permission to
revoke; users can disable the provider toggle in Translation settings.

**Change later:** provider enable toggle in Translation settings; update feed
and pinned public key are build-time values (`SUFeedURL`, `SUPublicEDKey` in
`Info.plist`), so change requires a build.

**Evidence:** `TranslationProviding.swift` (ephemeral `URLSession` with no
cookies, cache, or credential storage); `GoogleTranslationProvider.swift`
(fixed endpoints, key headers, validation without source text);
`UpdateService.swift` (Sparkle configured only with HTTPS feed and EdDSA key);
`Info.plist` (`SUFeedURL`, `SUPublicEDKey`).

## Capabilities without system prompts

| Capability | Mechanism | Runtime evidence |
|---|---|---|
| Pasteboard reading | `NSPasteboard.general` polling (0.3 s) while capture is enabled | `ClipboardMonitor.swift` |
| Pasteboard writing | `PasteboardWriter` with change-count suppression of own writes | `ClipboardServices.swift`, `PasteboardWriter.swift` |
| File writes under Application Support | Persistence directory and settings JSON | `ClipboardPersistence.swift`, `SettingsRepository.swift` |
| Keychain read/write | `SecItem` generic-password items, device-only | `ClipboardKeyStore.swift`, `TranslationCredentialStore.swift` |
| Synthesized key events | `CGEvent.post` for paste, guarded by `AXIsProcessTrusted()` | `ClipboardServices.swift` |

**Manifest evidence:** `EasyKeyApp.entitlements` declares
`com.apple.security.app-sandbox = false` — the app is not sandboxed — and
declares no other entitlements. `Info.plist` sets `LSUIElement = true`
(menu-bar accessory, no Dock icon by default). These are declarations, not
grants; the only user-grantable permission in this application is
Accessibility above. A missing sandbox means file and network access are
governed by the logged-in user's permissions rather than a container profile;
this is declared here because security reviewers routinely ask for it.
