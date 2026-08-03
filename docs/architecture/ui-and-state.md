---
id: "app_ui_state"
title: "App Ui State"
docforge_provenance:
  schema: "2.0"
  doc_id: "app_ui_state"
  path: "docs/architecture/ui-and-state.md"
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
    - id: "ui-navigation-and-state"
      sources:
        - path: "EasyKeyApp/Coordination/StatusItemController.swift"
          role: "code"
          git_blob: "41325adb028f17e1f2fb0a7cb7983c23c93824fe"
      unresolved: []
    - id: "menu-bar-status-item-and-popover"
      sources:
        - path: "EasyKeyApp/Coordination/StatusItemController.swift"
          role: "code"
          git_blob: "41325adb028f17e1f2fb0a7cb7983c23c93824fe"
        - path: "EasyKeyApp/Coordination/StatusMenuActionTarget.swift"
          role: "code"
          git_blob: "9858ae5651e3792442d734b39868dbdac404dc9d"
        - path: "EasyKeyApp/Coordination/AppCoordinatorWiring.swift"
          role: "code"
          git_blob: "e5b6d9a47e88e742e3b303ec1001d1492538fbb0"
      unresolved: []
    - id: "settings-window"
      sources:
        - path: "EasyKeyApp/Features/Settings/SettingsShell.swift"
          role: "code"
          git_blob: "82e0b617c929f5076a9b20f517e48af17e7a3f98"
        - path: "EasyKeyApp/ContentView.swift"
          role: "code"
          git_blob: "29467061dbb69c39c281d3d7ed3c2a0006179562"
        - path: "EasyKeyApp/Coordination/SettingsWindowPresenter.swift"
          role: "code"
          git_blob: "b01c95cc650c238cc2b57dd47860d5a729dcda42"
        - path: "EasyKeyApp/Features/Settings/SettingsSection.swift"
          role: "code"
          git_blob: "eb182d8c4afbb691e697cf0eee605d774361995c"
      unresolved: []
    - id: "clipboard-panel"
      sources:
        - path: "EasyKeyApp/Features/Clipboard/ClipboardServices.swift"
          role: "code"
          git_blob: "b9179d71d130b93c4f9f9dbe198eb5153be42637"
        - path: "EasyKeyApp/Features/Clipboard/ClipboardHotKeyController.swift"
          role: "code"
          git_blob: "ec3333371220d6e0b782a7e9bda1d6d715a22f50"
        - path: "EasyKeyApp/Features/Clipboard/ClipboardHistoryModel.swift"
          role: "code"
          git_blob: "6fe0b0f894f3d17c9546f48eb32f497701ac0ede"
      unresolved: []
    - id: "translation-panel"
      sources:
        - path: "EasyKeyApp/Features/Translation/AppTranslationRuntime.swift"
          role: "code"
          git_blob: "c4df84fdde3f664cd167d91ce3a64b387e6ef30e"
        - path: "EasyKeyApp/Features/Translation/TranslationCredentialStore.swift"
          role: "code"
          git_blob: "768aab956a8d02978101105e7a896b6d55c75376"
      unresolved: []
    - id: "onboarding"
      sources:
        - path: "EasyKeyApp/Features/Onboarding/OnboardingView.swift"
          role: "code"
          git_blob: "6607f26cd0e27f49ac6d0e77492557411063e170"
        - path: "EasyKeyApp/ContentView.swift"
          role: "code"
          git_blob: "29467061dbb69c39c281d3d7ed3c2a0006179562"
      unresolved: []
---
# UI navigation and state

_Last reviewed: 2026-08-03_

EasyKey has five surfaces — the menu-bar status item with popover, the Settings window, the clipboard panel, the translation panel, and the onboarding flow (which renders inside the settings window's content area). There is no `NavigationStack`-style hierarchy; navigation is a small set of intentional transitions between these surfaces, all owned by `AppCoordinator`-published state, and the transient popovers are torn down before the Settings window is presented (the close-then-present ordering is handled by dispatching to the next run-loop pass to avoid an AppKit popover race).

```mermaid
stateDiagram-v2
  [*] --> Onboarding
  Onboarding --> SettingsWindow: finish
  MenuBar --> SettingsWindow: left-click / menu item
  MenuBar --> ClipboardPanel: hotkey / menu item
  MenuBar --> TranslationPanel: hotkey / popover translate
  ClipboardPanel --> SettingsWindow: open settings
  TranslationPanel --> SettingsWindow: open settings
  SettingsWindow --> MenuBar: close
```

_Repeat the `##` block below per surface._

## Menu bar status item and popover

**State owner:** `StatusItemController` (the `NSStatusItem`/`NSPopover` pair) with `AppCoordinator` published state feeding the menu snapshot.

**Allowed transitions:** left-click toggles the popover (`togglePopover`, which also refreshes Accessibility permission); the status menu routes to `showSettings(section:)`, the clipboard panel, the translation popover, restart keyboard service, convert clipboard, show logs, about, and quit; the popover can host the translation mini-surface and an "open settings" action.

**Survives transition:** popover content is rebuilt on demand from the coordinator's snapshot (`menuSnapshotProvider` reads live settings — language, input method, encoding, current app, Smart Switch status, pause state), so an open popover reflects changes; opening Settings from the popover closes the popover first.

**Restoration on process death:** none — the popover does not exist across launches; the status item is reinstalled at launch with state rebuilt from settings.

**Error presentation:** keyboard health (`HealthPill`) and pause state render in the popover and menu; permission-request state routes "open settings" to the System section (`showSettingsFromPopover`).

## Settings window

**State owner:** `SettingsWindowPresenter` (window lifecycle) + `AppCoordinator.selectedSettingsSection` (`@Published`, default `.typing`).

**Allowed transitions:** entered from any surface via `showSettings(section:)`; sidebar selection switches the detail pane among the nine sections (typing, encoding, smartSwitch, translation, clipboard, macros, behavior, system, about); the sidebar toggle hides/shows the sidebar (`--ui-sidebar-hidden` preset for UI tests); closing returns to the menu bar.

**Survives transition:** the selected section survives window close/reopen within the process (coordinator-owned); the detail view is tagged `.id(selectedSettingsSection)` so switching sections resets per-section local state; `systemHealthNavigationRevision` forces a refresh of the System card when permission state changed.

**Restoration on process death:** the section resets to `.typing`; settings values themselves restore from `settings.json` on relaunch.

**Error presentation:** per-section status rows (Smart Switch current-app status, clipboard hotkey conflict, translation credential states, keyboard health card); permission-required navigation jumps to System.

## Clipboard panel

**State owner:** `ClipboardHistoryModel` (entries, selection, pins, in-memory history) with `ClipboardPanelPresenter` owning the transient `NSPopover`.

**Allowed transitions:** opened by hotkey (default `⌥V`) or the status menu; panel actions route to `showSettings(section: .clipboard)`, close, or reveal files in Finder; the panel closes before any paste action's cancel-pending-paste completes.

**Survives transition:** selection action and pinned state are model-owned and persist while the app runs; history persistence is a separate opt-in (`persistsHistory`) that survives process death via the AES-GCM sealed document.

**Restoration on process death:** loads persisted history only when enabled; otherwise an empty history.

**Error presentation:** hotkey conflict (`hasConflict`, old shortcut kept registered on failure), pasteboard-read failures, and persistence errors (`keyUnavailable`, `decryptionFailed`) surface as status/alert text.

## Translation panel

**State owner:** `AppTranslationRuntime` — `TranslationModel` for the active request/result, `TranslationDisclosureController` for the first-use gate, `TranslationHotKeyController` (Carbon registrar) for activation.

**Allowed transitions:** opened by hotkey (default `⌥C`), from the menu popover translate action, or from settings; panel actions open the translation settings section, dismiss, or replace the editor text with the result.

**Survives transition:** credential status and provider selection are persisted settings; an in-flight request is cancelled on panel dismissal (maps to `.cancelled`, no corrupted state).

**Restoration on process death:** none for the panel itself; provider configuration restores from settings and the Keychain.

**Error presentation:** per-provider credential states (`missing`/`saved`/`validating`/`ready`/`invalid`) in settings; provider/language errors shown in the panel with the source text preserved.

## Onboarding

**State owner:** `OnboardingView` local `@State step` (0–3: Welcome, Accessibility, Typing method, Ready) plus `@AppStorage("hasCompletedOnboarding")` as the gate.

**Allowed transitions:** shown instead of `SettingsShell` inside the ContentView when onboarding is incomplete; Back/Continue move between steps; Finish sets the flag and swaps to the Settings shell; the Accessibility step requests permission and reflects `keyboardHealth` live.

**Survives transition:** the completion flag is sticky (UserDefaults) — onboarding is never re-shown after Finish; UI-test arguments can preset the flag (`--ui-skip-onboarding`) and the language.

**Restoration on process death:** the flag restores from UserDefaults, so a user who finished onboarding is not re-onboarded after a crash.

**Error presentation:** the Accessibility step shows the health pill and a Grant button when the process is not trusted.
