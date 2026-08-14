---
id: "app_lifecycle"
title: "App Lifecycle"
description: "Launch/activation/background/termination states, ownership, restoration, failure boundaries"
docforge_provenance:
  schema: "2.0"
  doc_id: "app_lifecycle"
  path: "docs/architecture/application-lifecycle.md"
  generated_at: "2026-08-13T11:10:56Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "spine"
  target_depth: "deep-dive"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "application-lifecycle"
      sources:
        - path: "EasyKeyApp/AppDelegate.swift"
          git_blob: "a0ba11e8c1cc4bd2a48d1cd346edfade871c67b8"
          role: "code"
        - path: "EasyKeyApp/Coordination/AppCoordinator.swift"
          git_blob: "815b5dad186802739e0969eb509af2469570b583"
          role: "code"
      unresolved: []
    - id: "launch"
      sources:
        - path: "EasyKeyApp/AppDelegate.swift"
          git_blob: "a0ba11e8c1cc4bd2a48d1cd346edfade871c67b8"
          role: "code"
        - path: "EasyKeyApp/Coordination/AppCoordinator.swift"
          git_blob: "815b5dad186802739e0969eb509af2469570b583"
          role: "code"
        - path: "EasyEngineCore/Settings/SettingsRepository.swift"
          git_blob: "8dbf2339135a67a57533869cca68d46cc6e8c991"
          role: "code"
        - path: "EasyKeyApp/Settings/SettingsStore.swift"
          git_blob: "65074f5684006b032e635e9bcf80ad7bf37f4929"
          role: "code"
      unresolved: []
    - id: "active"
      sources:
        - path: "EasyKeyApp/Coordination/AppCoordinatorWiring.swift"
          git_blob: "55243d0eff45f4f8e7ba97eabc8460771ab2c0be"
          role: "code"
        - path: "EasyKeyKit/Keyboard/KeyboardService.swift"
          git_blob: "3246c7e678b841077f3006877c3b2ead836e912b"
          role: "code"
      unresolved: []
    - id: "asleep"
      sources:
        - path: "EasyKeyKit/Keyboard/KeyboardEventTap.swift"
          git_blob: "afd7e07bf098c7400aaccab85a72e77fac8a936d"
          role: "code"
        - path: "EasyKeyKit/Keyboard/Lifecycle/KeyboardSleepWakeObserver.swift"
          git_blob: "634d6f6aa19c6b6b4ee749cf6aa766e8945446b8"
          role: "code"
        - path: "EasyKeyApp/Coordination/WorkspaceObserver.swift"
          git_blob: "43906864cb9efceb789b0d80709a50e62730b258"
          role: "code"
        - path: "EasyKeyApp/Coordination/AppCoordinatorWiring.swift"
          git_blob: "55243d0eff45f4f8e7ba97eabc8460771ab2c0be"
          role: "code"
        - path: "EasyKeyApp/Features/Clipboard/ClipboardServices.swift"
          git_blob: "c15b3e5f0e30c4e0b62491f4050428d5dd4a19b9"
          role: "code"
      unresolved: []
    - id: "terminated"
      sources:
        - path: "EasyKeyApp/AppDelegate.swift"
          git_blob: "a0ba11e8c1cc4bd2a48d1cd346edfade871c67b8"
          role: "code"
        - path: "EasyKeyApp/Coordination/AppCoordinator.swift"
          git_blob: "815b5dad186802739e0969eb509af2469570b583"
          role: "code"
        - path: "EasyKeyApp/Features/Clipboard/ClipboardHistoryModel.swift"
          git_blob: "6fe0b0f894f3d17c9546f48eb32f497701ac0ede"
          role: "code"
        - path: "EasyKeyApp/Features/Clipboard/ClipboardServices.swift"
          git_blob: "c15b3e5f0e30c4e0b62491f4050428d5dd4a19b9"
          role: "code"
      unresolved: []
---
# Application lifecycle

_Last reviewed: 2026-08-13_

EasyKey is a menu-bar accessory (`LSUIElement`, activation policy `.accessory` unless UI testing) with no document windows and no iOS-style backgrounding. Its lifecycle is therefore: launch, active (menu-bar presence with the event tap installed), system sleep as the only true suspension, and termination. Single-instance enforcement is part of launch: `AppCoordinator.isOnlyInstanceForCurrentUser()` terminates a second instance before it registers anything.

```mermaid
stateDiagram-v2
  [*] --> Launch
  Launch --> Active
  Active --> Asleep
  Asleep --> Active
  Active --> Terminated
  Asleep --> Terminated
  Launch --> Terminated
  Terminated --> [*]
```

## Launch

**Owner:** `AppDelegate.applicationDidFinishLaunching` + `AppCoordinator.start()`.

**Trigger:** user launch, Finder open, or the login item (`EasyKeyLoginHelper`) launching the host.

**Must do before leaving:** run the single-instance check (skipped under `--uitesting`); set activation policy (`.accessory`, or `.regular` under `--uitesting` so the settings window can receive clicks on headless CI); install the system Edit menu (`AppMainMenuInstaller`) because accessory apps lack one — without it Cmd+V never reaches text fields; then `AppCoordinator.start()`, which binds and installs the status item, observes settings and localization changes, starts the workspace observer, starts the update service (skipped under `--uitesting`), seeds the active-application context, starts the keyboard service, starts translation, chains the clipboard start task (awaiting any previous start/stop task first), and shows the Settings window at launch when `settings.system.showSettingsAtLaunch` is enabled.

**Restoration on relaunch:** `SettingsStore` (wrapping `SettingsRepository`) loads `settings.json` from `~/Library/Application Support/EasyKey/` — decoding supported schema versions and migrating older ones — `MacroStore` loads `macros.json`, `SmartSwitchStore` loads `smart-switch.json`, and the clipboard model loads persisted history only when `clipboard.persistsHistory` is enabled. The onboarding gate (`hasCompletedOnboarding`) restores from `UserDefaults`.

**On kill mid-transition:** before `start()` completes nothing is registered and nothing persists — a kill here is a clean no-op. The only risk window is a kill during the debounced settings write (`SettingsStore`, 300 ms debounce).

## Active

**Owner:** `AppCoordinator` (state) with `KeyboardService` (event tap health).

**Trigger:** launch completes; also every system wake and every return from sleep state.

**Must do before leaving:** when the tap is installed and Accessibility is trusted, `KeyboardService` keeps health at `.active` (`startIfPermitted`); on application activation it updates the active-app context (deferring the switch while the pipeline is composing) and refreshes Accessibility permission; on `activeSpaceDidChange` it resets the composition session; on wake it resets the session, refreshes the input source, and re-checks permission. Each tap event is recorded with its disposition (passed/suppressed/bypassed/self-posted/disabled) and latency — no key content. The clipboard monitor polls while capture is enabled.

**Restoration on relaunch:** in-memory only — the composition session, popovers, and published state (`selectedSettingsSection` resets to `.typing`) are not restored across process death; persisted state comes back from the stores named under Launch.

**On kill mid-transition:** `KeyboardService` holds no persistent state, so a kill is clean; in-memory clipboard history is lost unless persistence is enabled (then it is AES-GCM sealed on the debounced save path, losing at most the newest entries).

## Asleep

**Owner:** `KeyboardService` via its sleep/wake observer (tap teardown) + `WorkspaceObserver` (session-reset routing).

**Trigger:** `NSWorkspace.willSleepNotification` — observed independently by both `KeyboardSleepWakeObserver` (installed by `KeyboardService.start()` through `KeyboardEventTap`) and `WorkspaceObserver`.

**Must do before leaving:** `KeyboardService.handleSystemSleep()` tears down the tap's `CFMachPort` and run-loop source and drops health to `.degraded` (or `.stopped` when paused); the workspace observer resets the composition session. The status item, clipboard monitor, and updater keep running as normal.

**Restoration on relaunch (wake):** `didWakeNotification` reaches both observers: `KeyboardSleepWakeObserver` routes to `handleSystemWake()`, which refreshes the input source and re-installs the tap when Accessibility is trusted; `WorkspaceObserver` routes to `AppCoordinator.configureWorkspaceObserver`'s wake handler, which resets the keyboard session, refreshes the input source and Accessibility permission, and calls `clipboard.handleWake()` to refresh the monitor's observed change count. The pipeline's per-app context is re-derived from the frontmost application on the next activation event.

**On kill mid-transition:** nothing is mid-write during sleep; the tap is already torn down, so a kill while asleep is equivalent to a kill in Active minus the tap.

## Terminated

**Owner:** `AppDelegate.applicationShouldTerminate` + `AppCoordinator.stop()`/`awaitShutdown()`.

**Trigger:** user Quit, `NSApp.terminate(nil)` (status-item Quit), or the second-instance self-termination.

**Must do before leaving:** `applicationShouldTerminate` calls `coordinator.stop()` and returns `.terminateLater`; `stop()` cancels the settings and localization observers, stops the workspace observer, tears down the status item and popover, stops keyboard service and translation, closes the settings window, cancels the clipboard start task, then awaits the clipboard stop — which flushes any pending persisted-history write (`flushPendingSave`) — and `settingsStore.saveNow()`. Only when `awaitShutdown()` completes does the app reply `true` to the terminate request.

**Restoration on relaunch:** same as Launch — file stores are reloaded; the persisted clipboard document's sealed payloads decrypt with the device-only Keychain key.

**On kill mid-transition:** a hard kill (force-quit, crash) skips the stop choreography: the debounced settings write (300 ms) may be lost, and any pending clipboard persistence flush is lost; the sealed document on disk is only ever replaced atomically, so it stays readable (or absent) rather than corrupt. Failure boundaries for each subsystem's flush are covered by the [architecture overview](README.md#scope-and-boundaries).
