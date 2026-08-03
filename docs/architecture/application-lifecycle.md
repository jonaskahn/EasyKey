---
id: "app_lifecycle"
title: "App Lifecycle"
docforge_provenance:
  schema: "2.0"
  doc_id: "app_lifecycle"
  path: "docs/architecture/application-lifecycle.md"
  generated_at: "2026-08-03T10:00:00Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "deep-dive"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "application-lifecycle"
      sources:
        - path: "EasyKeyApp/AppDelegate.swift"
          role: "code"
          git_blob: "8ecc5922afe0e99166cbcf3425afd2514b887ae2"
      unresolved: []
    - id: "launch"
      sources:
        - path: "EasyKeyApp/AppDelegate.swift"
          role: "code"
          git_blob: "8ecc5922afe0e99166cbcf3425afd2514b887ae2"
        - path: "EasyKeyApp/AppCoordinator.swift"
          role: "code"
          git_blob: "64de70b72c5fac1e218063377a05fbd4fb6adafa"
        - path: "EasyEngineCore/Settings/SettingsRepository.swift"
          role: "code"
          git_blob: "f718fcf9ea3a84f0aa770650c15c8c059e450a19"
      unresolved: []
    - id: "active"
      sources:
        - path: "EasyKeyApp/Coordination/AppCoordinatorWiring.swift"
          role: "code"
          git_blob: "e5b6d9a47e88e742e3b303ec1001d1492538fbb0"
        - path: "EasyKeyKit/KeyboardService.swift"
          role: "code"
          git_blob: "3d2db069ec81fb639d6eb9a6fc69121580854d31"
      unresolved: []
    - id: "asleep"
      sources:
        - path: "EasyKeyKit/Keyboard/KeyboardEventTap.swift"
          role: "code"
          git_blob: "2df63cc191f2509471b02cfad60b8a3113be0933"
        - path: "EasyKeyApp/Coordination/WorkspaceObserver.swift"
          role: "code"
          git_blob: "43906864cb9efceb789b0d80709a50e62730b258"
        - path: "EasyKeyApp/Features/Clipboard/ClipboardServices.swift"
          role: "code"
          git_blob: "b9179d71d130b93c4f9f9dbe198eb5153be42637"
      unresolved: []
    - id: "terminated"
      sources:
        - path: "EasyKeyApp/AppDelegate.swift"
          role: "code"
          git_blob: "8ecc5922afe0e99166cbcf3425afd2514b887ae2"
        - path: "EasyKeyApp/AppCoordinator.swift"
          role: "code"
          git_blob: "64de70b72c5fac1e218063377a05fbd4fb6adafa"
        - path: "EasyKeyApp/Features/Clipboard/ClipboardHistoryModel.swift"
          role: "code"
          git_blob: "6fe0b0f894f3d17c9546f48eb32f497701ac0ede"
      unresolved: []
---
# Application lifecycle

_Last reviewed: 2026-08-03_

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

_Repeat per state below — Launch, Active, Asleep, Terminated._

## Launch

**Owner:** `AppDelegate.applicationDidFinishLaunching` + `AppCoordinator.start()`.

**Trigger:** user launch, Finder open, or the login item (`EasyKeyLoginHelper`) launching the host.

**Must do before leaving:** run the single-instance check; set activation policy (`.accessory`, or `.regular` under `--uitesting` so the settings window can receive clicks on headless CI); install the system Edit menu (`AppMainMenuInstaller`) because accessory apps lack one — without it Cmd+V never reaches text fields; then `AppCoordinator.start()`, which installs the status item, wires workspace/settings observers, starts the update service (skipped under `--uitesting`), starts the keyboard service, starts translation, and begins clipboard capture as a chained task.

**Restoration on relaunch:** `SettingsRepository` loads `settings.json` from `~/Library/Application Support/EasyKey/` (migrating schema versions), `MacroStore` loads `macros.json`, `SmartSwitchStore` loads `smart-switch.json`, and the clipboard model loads persisted history only when `clipboard.persistsHistory` is enabled. The onboarding gate (`hasCompletedOnboarding`) restores from `UserDefaults`.

**On kill mid-transition:** before `start()` completes nothing is registered and nothing persists — a kill here is a clean no-op. The only risk window is a kill during the debounced settings write (see [tech-debt.md](tech-debt.md)).

## Active

**Owner:** `AppCoordinator` (state) with `KeyboardService` (event tap health).

**Trigger:** launch completes; also every system wake and every return from sleep state.

**Must do before leaving:** when the tap is active and Accessibility is trusted, `KeyboardService` keeps health at `.active`; on application activation it updates the active-app context (deferring the switch mid-composition) and refreshes Accessibility permission; on `activeSpaceDidChange` it resets the composition session; on wake it resets the session and re-checks permission. The clipboard monitor polls while capture is enabled.

**Restoration on relaunch:** in-memory only — the composition session, popovers, and published state (`selectedSettingsSection` resets to `.typing`) are not restored across process death; persisted state comes back from the stores named under Launch.

**On kill mid-transition:** `KeyboardService` holds no persistent state, so a kill is clean; in-memory clipboard history is lost unless persistence is enabled (then it is AES-GCM sealed on the debounced save path, losing at most the newest entries).

## Asleep

**Owner:** `KeyboardEventTap` (tap teardown) + `WorkspaceObserver` (notification routing).

**Trigger:** `NSWorkspace.willSleepNotification` (both observers fire it).

**Must do before leaving:** the event tap tears down its `CFMachPort` and run-loop source and health drops to `.degraded`; the workspace observer resets the composition session. The status item, clipboard monitor, and updater keep running as normal.

**Restoration on relaunch (wake):** `didWakeNotification` routes to `AppCoordinator.configureWorkspaceObserver`, which resets the keyboard session, refreshes the input source and Accessibility permission (reinstalling the tap if trusted), and calls `clipboard.handleWake()` to refresh the monitor's observed change count. The pipeline's per-app context is re-derived from the frontmost application on the next activation event.

**On kill mid-transition:** nothing is mid-write during sleep; the tap is already torn down, so a kill while asleep is equivalent to a kill in Active minus the tap.

## Terminated

**Owner:** `AppDelegate.applicationShouldTerminate` + `AppCoordinator.stop()`/`awaitShutdown()`.

**Trigger:** user Quit, `NSApp.terminate(nil)` (status-item Quit), or the second-instance self-termination.

**Must do before leaving:** `applicationShouldTerminate` calls `coordinator.stop()` and returns `.terminateLater`; `stop()` cancels the settings/localization observers, stops the workspace observer, tears down the status item and popover, stops keyboard service and translation, closes the settings window, cancels the clipboard start task, then awaits the clipboard stop — which flushes any pending persisted-history write (`flushPendingSave`) — and `settingsStore.saveNow()`. Only when `awaitShutdown()` completes does the app reply `.terminateNow`.

**Restoration on relaunch:** same as Launch — file stores are reloaded; the persisted clipboard document's sealed payloads decrypt with the device-only Keychain key.

**On kill mid-transition:** a hard kill (force-quit, crash) skips the stop choreography: the debounced settings write (300 ms) may be lost, and any pending clipboard persistence flush is lost; the sealed document on disk is only ever replaced atomically, so it stays readable (or absent) rather than corrupt. Failure boundaries for each subsystem's flush are documented in [low-level.md](low-level.md).
