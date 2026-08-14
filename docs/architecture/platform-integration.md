---
id: "platform_integration"
title: "Platform Integration"
description: "OS services, adapters, permissions boundary, callbacks, failure and fallback"
docforge_provenance:
  schema: "2.0"
  doc_id: "platform_integration"
  path: "docs/architecture/platform-integration.md"
  generated_at: "2026-08-13T11:10:56Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "deep-dive"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "platform-integration"
      sources:
        - path: "EasyKeyKit/Keyboard/KeyboardService.swift"
          role: "code"
          git_blob: "3246c7e678b841077f3006877c3b2ead836e912b"
      unresolved: []
    - id: "accessibility"
      sources:
        - path: "EasyKeyKit/Keyboard/KeyboardService.swift"
          role: "code"
          git_blob: "3246c7e678b841077f3006877c3b2ead836e912b"
        - path: "EasyKeyKit/Keyboard/FocusedElementInspector.swift"
          role: "code"
          git_blob: "2f61fac3a31d989c03784cff00519097d0d50f7b"
        - path: "EasyKeyApp/Features/Translation/SelectedTextCapture.swift"
          role: "code"
          git_blob: "c4124fe1499209bf7096f8bbdecb394d8df95f80"
        - path: "EasyKeyKit/Keyboard/Synthesis/KeySynthesizer.swift"
          role: "code"
          git_blob: "d9d56d371db322150cd74a358258fe7243989bab"
      unresolved: []
    - id: "cgevent-tap"
      sources:
        - path: "EasyKeyKit/Keyboard/KeyboardEventTap.swift"
          role: "code"
          git_blob: "afd7e07bf098c7400aaccab85a72e77fac8a936d"
        - path: "EasyKeyKit/Keyboard/KeyboardInputPipeline.swift"
          role: "code"
          git_blob: "81a9d66e22797ea2b1b0632ecddfcaf73fd06757"
        - path: "EasyKeyKit/Keyboard/Lifecycle/KeyboardSleepWakeObserver.swift"
          role: "code"
          git_blob: "634d6f6aa19c6b6b4ee749cf6aa766e8945446b8"
      unresolved: []
    - id: "nsworkspace-notifications"
      sources:
        - path: "EasyKeyApp/Coordination/WorkspaceObserver.swift"
          role: "code"
          git_blob: "43906864cb9efceb789b0d80709a50e62730b258"
      unresolved: []
    - id: "keychain"
      sources:
        - path: "EasyKeyApp/Features/Translation/TranslationCredentialStore.swift"
          role: "code"
          git_blob: "768aab956a8d02978101105e7a896b6d55c75376"
        - path: "EasyKeyApp/Features/Clipboard/ClipboardKeyStore.swift"
          role: "code"
          git_blob: "8308409cb0bb907254e169b15dd74b9304399ed3"
      unresolved: []
    - id: "carbon-hotkeys"
      sources:
        - path: "EasyKeyApp/Features/Clipboard/ClipboardHotKeyController.swift"
          role: "code"
          git_blob: "ec3333371220d6e0b782a7e9bda1d6d715a22f50"
        - path: "EasyKeyApp/Features/Translation/AppTranslationRuntime.swift"
          role: "code"
          git_blob: "4f6f75d8aa093c688ec77d6722ba0cc62769b87d"
      unresolved: []
    - id: "login-item"
      sources:
        - path: "EasyKeyApp/Coordination/LoginItemController.swift"
          role: "code"
          git_blob: "7833a6d82792ded3986386ac26e40b686feab12d"
        - path: "EasyKeyLoginHelper/main.swift"
          role: "code"
          git_blob: "f0f724c4c8a6644555990bff4e08325f80625a66"
      unresolved: []
    - id: "sparkle-updates"
      sources:
        - path: "EasyKeyApp/Coordination/UpdateService.swift"
          role: "code"
          git_blob: "186960351c6c963cfee981caef34e7aa8a544457"
          git_blob_normalized: "186960351c6c963cfee981caef34e7aa8a544457"
        - path: "EasyKeyApp/Info.plist"
          role: "config"
          git_blob: "f4603871fa675111bd6db1472dfb04936ff3f645"
        - path: "Scripts/generate-appcast.py"
          role: "config"
          git_blob: "b11742e9715d352ad971f4ab8d5f3dabf5ef38d9"
      unresolved: []
    - id: "input-source-query"
      sources:
        - path: "EasyKeyKit/Keyboard/KeyboardInputPipeline.swift"
          role: "code"
          git_blob: "81a9d66e22797ea2b1b0632ecddfcaf73fd06757"
        - path: "EasyKeyKit/Keyboard/Context/KeyboardInputSourceInspector.swift"
          role: "code"
          git_blob: "368cb48f12a963ce755cce110cee897f888aa603"
      unresolved: []
    - id: "spotlight-detection"
      sources:
        - path: "EasyKeyKit/Keyboard/SpotlightWindowDetector.swift"
          role: "code"
          git_blob: "ab9966a65dc3f038110c81f2081fd81816599885"
        - path: "docs/reference/limitations.md"
          role: "doc"
          git_blob: "341a719fbd1a4d71aa36d334c5d863764948f685"
          git_blob_normalized: "341a719fbd1a4d71aa36d334c5d863764948f685"
      unresolved: []
    - id: "integration-surface"
      sources:
        - path: "EasyKeyApp/Coordination/StatusItemController.swift"
          role: "code"
          git_blob: "41325adb028f17e1f2fb0a7cb7983c23c93824fe"
      unresolved: []
---
# Platform integration

_Last reviewed: 2026-08-13_

Every OS service and platform adapter this repository actually integrates, one section each. Permission rationale and scope live in [permissions](../security/permissions.md); this document names which permission each integration requires and what happens when the service is unavailable.

## Accessibility

**Used for:** the two halves of the typing feature — gating system-wide keyboard observation (`AXIsProcessTrusted` / `AXIsProcessTrustedWithOptions` prompt) and contextual reads of the focused element. Text edits no longer go through `AXUIElement` writes: composition output is applied as synthesized CGEvent sequences (`KeySynthesizer`) posted into the tap. The AX reads that remain are `FocusedElementInspector` (identifies the Chromium address bar via AX description "Address and search bar"/"Address field" or an identifier containing "omnibox") and `AccessibilitySelectedTextReader` (role-gated selected-text capture for translation).

**Permission boundary:** see [permissions](../security/permissions.md) — the app must be listed under System Settings → Privacy & Security → Accessibility; revoking it disables typing immediately.

**Callback contract:** none — Accessibility is polled/checked, not evented. `KeyboardService.refreshPermission()` re-checks trust on app activation, wake, and status-item interactions; `requestAccessibilityPermission()` prompts via the system trust dialog.

**Fallback if unavailable:** the event tap is torn down and health is set to `.requestingPermission`; typing is unavailable, the status menu shows the state, onboarding offers a Grant button, and the System health card routes users to the settings pane. All other features keep working.

## CGEvent tap

**Used for:** intercepting keyDown/keyUp/flagsChanged plus mouse-down/drag events session-wide (`KeyboardEventTap` installs a `.cgSessionEventTap` at `.headInsertEventTap` with a mask covering those types).

**Permission boundary:** requires Accessibility trust (the tap is created only after `AXIsProcessTrusted()` passes).

**Callback contract:** the C callback `keyboardEventTapCallback` asserts the main thread and forwards via `MainActor.assumeIsolated` to `KeyboardService.handleTapEvent(proxy:type:event:)`, which processes the event on the serial processing queue and returns a suppressed original (nil) or the passed event.

**Fallback if unavailable:** a `tapDisabledByTimeout` / `tapDisabledByUserInput` event tears the tap down, sets health to `.degraded`, and re-requests permission (`recoverTapAfterDisable`); on sleep the tap is torn down pre-emptively via the sleep/wake observer (`handleSystemSleep`) and reinstalled on wake. Install failure sets health to `.failed` (surfaced in the System health card).

## NSWorkspace notifications

**Used for:** frontmost-application tracking (`didActivateApplication`), composition reset on space change (`activeSpaceDidChange`), and sleep/wake handling (`willSleep`/`didWake`) — wired in `WorkspaceObserver` and again in `KeyboardEventTap.installWorkspaceObserversIfNeeded`.

**Permission boundary:** none.

**Callback contract:** main-queue notification closures — activation updates per-app context and Smart Switch; sleep resets sessions and tears down the tap; wake resets sessions, refreshes input source + Accessibility permission, and refreshes the clipboard monitor.

**Fallback if unavailable:** notifications do not fail; a missed `didWake` (rare) is covered by the next activation event, which also refreshes permission.

## Keychain

**Used for:** two device-local secrets — cloud translation API keys (`KeychainTranslationCredentialStore`, service `one.ifelse.easykey.translation`) and the clipboard history encryption key (`KeychainClipboardKeyStore`, service `one.ifelse.easykey.clipboard`, account `history-key`).

**Permission boundary:** no user prompt (generic passwords); items are `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` and never synchronized.

**Callback contract:** none — synchronous `SecItem` calls through the narrow `SecItemAccessing` seam (also the test injection point).

**Fallback if unavailable:** unexpected `OSStatus` results throw typed errors surfaced per surface (credential status in translation settings; `keyUnavailable`/`decryptionFailed` for clipboard persistence, which degrades to an empty in-memory history rather than crashing).

## Carbon hotkeys

**Used for:** the clipboard-panel shortcut (`ClipboardHotKeyController` + `CarbonHotKeyRegistrar`, default `⌥V`) and the translation panel hotkey (`CarbonTranslationHotKeyRegistrar`) via `RegisterEventHotKey`.

**Permission boundary:** none — Carbon hotkeys are global by design.

**Callback contract:** one application-level event handler routes `kEventHotKeyPressed` events to per-identifier closures on the main actor.

**Fallback if unavailable:** registration failure marks a conflict (`hasConflict`); a replacement registers the new shortcut first and unregisters the old one only on success, so a conflicting shortcut leaves the previous binding working. Inactive shortcuts are unregistered.

## Login item

**Used for:** launch-at-login via `SMAppService.loginItem(identifier: AppIdentifiers.loginHelper)` — the embedded `EasyKeyLoginHelper` accessory app (`LSBackgroundOnly`, sandboxed) walks four path components up from `Contents/Library/LoginItems/` to the host `.app`, validates its bundle identifier, and launches it if it is not already running, then exits (3 s watchdog).

**Permission boundary:** the user grants/revokes login-item registration through the settings toggle; the helper itself requests no permissions.

**Callback contract:** none — fire-once launch orchestration.

**Fallback if unavailable:** `LoginItemController.Status` distinguishes `.disabled`/`.enabled`/`.unsupported` (SMAppService `.notFound`) /`.failed`; settings and the System section surface the localized state. A manually relaunched app re-registers when the user toggles the setting.

## Sparkle updates

**Used for:** signed automatic updates (`SPUStandardUpdaterController`, deferred `startUpdater()` until `AppCoordinator.start()`), feed and EdDSA key read from `SUFeedURL`/`SUPublicEDKey` build settings in `Info.plist`.

**Permission boundary:** none; the app is not sandboxed, which Sparkle requires.

**Callback contract:** `start()` begins scheduled checks; `checkForUpdates()` forces one (status-menu "Check for Updates"); appcast XML is produced by `Scripts/generate-appcast.py`.

**Fallback if unavailable:** missing HTTPS feed or ED key disables the updater at init (with a log line) — the app runs untouched; a failed check leaves the current version installed. Decision: [sparkle-updates](decisions/sparkle-updates.md).

## Input source query

**Used for:** detecting a non-English ("foreign") input source via `TISCopyCurrentKeyboardInputSource` — the pipeline's `isCurrentInputSourceForeign()` delegates to `KeyboardInputSourceInspector`, which treats any layout whose languages contain no "en"-prefixed code as foreign and feeds the pipeline's `usesForeignInputSource` flag so composition adapts.

**Permission boundary:** none — TIS is a read-only public API.

**Callback contract:** queried on start and on wake (`refreshInputSource()`); no callbacks.

**Fallback if unavailable:** query failure returns false (treated as not foreign); composition proceeds with the normal path.

## Spotlight detection

**Used for:** recognizing the Spotlight search field, which never activates as an app, by polling `CGWindowListCopyWindowInfo` for a window owned by "Spotlight" with a 0.3 s detection cache (`SpotlightWindowDetector`).

**Permission boundary:** none — window-list polling is public; it is an on-screen heuristic, not a focus event.

**Callback contract:** polled from the pipeline; a detected Spotlight window switches composition to the selection-replacement workaround.

**Fallback if unavailable:** during the detection lag, keystrokes bypass the workaround and can look briefly broken; the app self-corrects — a documented platform limitation ([limitations.md](../reference/limitations.md)).

## Integration surface

_One row per OS service/adapter — permission required, callback contract, fallback behavior._

| OS service / adapter | Permission | Callback contract | Fallback if unavailable |
|---|---|---|---|
| Accessibility (AX) | System Settings → Accessibility grant | None — polled/checked | Tap torn down, health `requestingPermission`, typing disabled |
| CGEvent tap | Same AX grant | Main-run-loop C callback per masked event | Tear down + re-request; health `degraded`/`failed` |
| NSWorkspace notifications | None | Main-queue closures (activation, space, sleep, wake) | N/A — next activation refreshes state |
| Keychain (SecItem) | None (device-only items) | Synchronous calls via `SecItemAccessing` | Typed errors → surface status text |
| Carbon hotkeys | None | One event handler routing per-ID closures | Conflict flag; previous binding kept |
| SMAppService login item | User toggle | Fire-once host launch | `.unsupported` / `.failed` status surfaced |
| Sparkle | None (unsandboxed) | `startUpdater()` + `checkForUpdates()` | Updater disabled at init; manual installs remain |
| TIS input source | None | Queried on start/wake | Treated as not foreign |
| Spotlight window poll | None | Polled via `CGWindowListCopyWindowInfo` | Detection lag → brief broken typing, self-corrects |
| NSStatusItem / NSPopover | None | `NSStatusItem` action + `NSPopoverDelegate` close | Popover closes; status item content rebuilt |

A lifecycle transition affected by these callbacks (sleep/wake/termination) is described in [application-lifecycle.md](application-lifecycle.md), not restated here.
