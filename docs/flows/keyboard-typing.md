---
id: "flow-keyboard-typing"
title: "Flow Keyboard Typing"
description: "How EasyKey transforms system-wide keystrokes into Vietnamese text: trigger, actors, steps, branches, failures, outcome"
docforge_provenance:
  schema: "2.0"
  doc_id: "flow-keyboard-typing"
  path: "docs/flows/keyboard-typing.md"
  generated_at: "2026-08-13T11:26:41Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "deep-dive"
  graph:
    provider: "codegraph"
    flow: "derived"
  sections:
    - id: "keyboard-typing-transformation-telexvni"
      sources:
        - path: "EasyKeyKit/Keyboard/KeyboardEventTap.swift"
          role: "doc"
          git_blob: "afd7e07bf098c7400aaccab85a72e77fac8a936d"
      unresolved: []
    - id: "trigger-and-actors"
      sources:
        - path: "EasyKeyKit/Keyboard/KeyboardEventTap.swift"
          role: "doc"
          git_blob: "afd7e07bf098c7400aaccab85a72e77fac8a936d"
        - path: "EasyKeyKit/Keyboard/KeyboardService.swift"
          role: "doc"
          git_blob: "3246c7e678b841077f3006877c3b2ead836e912b"
      unresolved: []
    - id: "happy-path"
      sources:
        - path: "EasyKeyKit/Keyboard/KeyboardEventTap.swift"
          role: "doc"
          git_blob: "afd7e07bf098c7400aaccab85a72e77fac8a936d"
        - path: "EasyKeyKit/Keyboard/KeyboardService.swift"
          role: "doc"
          git_blob: "3246c7e678b841077f3006877c3b2ead836e912b"
        - path: "EasyKeyKit/Keyboard/KeyboardInputPipeline.swift"
          role: "doc"
          git_blob: "81a9d66e22797ea2b1b0632ecddfcaf73fd06757"
        - path: "EasyEngineCore/Engine/VietnameseEngine.swift"
          role: "doc"
          git_blob: "35a0190749c2ea1c5c37e5bd2c3bfed96f69fc03"
        - path: "EasyEngineCore/Engine/TelexComposer.swift"
          role: "doc"
          git_blob: "2b42730f8b4154642ee53fa92ccc8d9bc63a093b"
        - path: "EasyKeyKit/Keyboard/Synthesis/KeySynthesizer.swift"
          role: "doc"
          git_blob: "d9d56d371db322150cd74a358258fe7243989bab"
        - path: "EasyKeyKit/Keyboard/Diagnostics/KeyboardDiagnosticsRecorder.swift"
          role: "doc"
          git_blob: "5b06cb65f184556907e6ae44d093dc4fae536505"
      unresolved: []
    - id: "branches-and-rules"
      sources:
        - path: "EasyKeyKit/Keyboard/KeyboardInputPipeline.swift"
          role: "doc"
          git_blob: "81a9d66e22797ea2b1b0632ecddfcaf73fd06757"
        - path: "EasyKeyKit/Keyboard/KeyboardService.swift"
          role: "doc"
          git_blob: "3246c7e678b841077f3006877c3b2ead836e912b"
      unresolved: []
    - id: "accessibility-permission-missing-or-revoked"
      sources:
        - path: "EasyKeyKit/Keyboard/KeyboardService.swift"
          role: "doc"
          git_blob: "3246c7e678b841077f3006877c3b2ead836e912b"
        - path: "EasyKeyApp/Coordination/AppCoordinatorWiring.swift"
          role: "doc"
          git_blob: "55243d0eff45f4f8e7ba97eabc8460771ab2c0be"
      unresolved: []
    - id: "keyboard-paused-emergency-pause"
      sources:
        - path: "EasyKeyKit/Keyboard/KeyboardService.swift"
          role: "doc"
          git_blob: "3246c7e678b841077f3006877c3b2ead836e912b"
      unresolved: []
    - id: "ignored-application"
      sources:
        - path: "EasyKeyKit/Keyboard/KeyboardInputPipeline.swift"
          role: "doc"
          git_blob: "81a9d66e22797ea2b1b0632ecddfcaf73fd06757"
      unresolved: []
    - id: "foreign-input-source-without-other-language-support"
      sources:
        - path: "EasyKeyKit/Keyboard/KeyboardInputPipeline.swift"
          role: "doc"
          git_blob: "81a9d66e22797ea2b1b0632ecddfcaf73fd06757"
        - path: "EasyKeyKit/Keyboard/KeyboardService.swift"
          role: "doc"
          git_blob: "3246c7e678b841077f3006877c3b2ead836e912b"
      unresolved: []
    - id: "spotlight-window-active"
      sources:
        - path: "EasyKeyKit/Keyboard/SpotlightWindowDetector.swift"
          role: "doc"
          git_blob: "ab9966a65dc3f038110c81f2081fd81816599885"
        - path: "EasyKeyKit/Keyboard/KeyboardInputPipeline.swift"
          role: "doc"
          git_blob: "81a9d66e22797ea2b1b0632ecddfcaf73fd06757"
      unresolved: []
    - id: "chromium-address-bar"
      sources:
        - path: "EasyKeyKit/Keyboard/KeyboardInputPipeline.swift"
          role: "doc"
          git_blob: "81a9d66e22797ea2b1b0632ecddfcaf73fd06757"
      unresolved: []
    - id: "smart-switch-per-app-language-override"
      sources:
        - path: "EasyKeyApp/Coordination/WorkspaceObserver.swift"
          role: "doc"
          git_blob: "43906864cb9efceb789b0d80709a50e62730b258"
        - path: "EasyKeyApp/Coordination/SmartSwitchController.swift"
          role: "doc"
          git_blob: "ca7709b75a2c8edcd64f350642b0641a94adb1d3"
        - path: "EasyKeyApp/Coordination/AppCoordinatorWiring.swift"
          role: "doc"
          git_blob: "55243d0eff45f4f8e7ba97eabc8460771ab2c0be"
      unresolved: []
    - id: "language-toggle-and-restore-word-shortcuts"
      sources:
        - path: "EasyKeyKit/Keyboard/KeyboardInputPipeline.swift"
          role: "doc"
          git_blob: "81a9d66e22797ea2b1b0632ecddfcaf73fd06757"
        - path: "EasyEngineCore/Engine/VietnameseEngine.swift"
          role: "doc"
          git_blob: "35a0190749c2ea1c5c37e5bd2c3bfed96f69fc03"
      unresolved: []
    - id: "failure-and-recovery"
      sources:
        - path: "EasyKeyKit/Keyboard/KeyboardService.swift"
          role: "doc"
          git_blob: "3246c7e678b841077f3006877c3b2ead836e912b"
        - path: "EasyKeyKit/Keyboard/KeyboardEventTap.swift"
          role: "doc"
          git_blob: "afd7e07bf098c7400aaccab85a72e77fac8a936d"
      unresolved: []
    - id: "event-tap-install-failure"
      sources:
        - path: "EasyKeyKit/Keyboard/KeyboardEventTap.swift"
          role: "doc"
          git_blob: "afd7e07bf098c7400aaccab85a72e77fac8a936d"
        - path: "EasyKeyKit/Keyboard/KeyboardService.swift"
          role: "doc"
          git_blob: "3246c7e678b841077f3006877c3b2ead836e912b"
      unresolved: []
    - id: "tap-disabled-by-system"
      sources:
        - path: "EasyKeyKit/Keyboard/KeyboardService.swift"
          role: "doc"
          git_blob: "3246c7e678b841077f3006877c3b2ead836e912b"
      unresolved: []
    - id: "sleep-and-wake"
      sources:
        - path: "EasyKeyKit/Keyboard/KeyboardEventTap.swift"
          role: "doc"
          git_blob: "afd7e07bf098c7400aaccab85a72e77fac8a936d"
        - path: "EasyKeyKit/Keyboard/KeyboardService.swift"
          role: "doc"
          git_blob: "3246c7e678b841077f3006877c3b2ead836e912b"
      unresolved: []
    - id: "output-synthesis-failure"
      sources:
        - path: "EasyKeyKit/Keyboard/KeyboardInputPipeline.swift"
          role: "doc"
          git_blob: "81a9d66e22797ea2b1b0632ecddfcaf73fd06757"
        - path: "EasyKeyKit/Keyboard/Synthesis/KeySynthesizer.swift"
          role: "doc"
          git_blob: "d9d56d371db322150cd74a358258fe7243989bab"
      unresolved: []
    - id: "outcome"
      sources:
        - path: "EasyKeyKit/Keyboard/KeyboardService.swift"
          role: "doc"
          git_blob: "3246c7e678b841077f3006877c3b2ead836e912b"
        - path: "EasyKeyApp/Coordination/AppCoordinatorWiring.swift"
          role: "doc"
          git_blob: "55243d0eff45f4f8e7ba97eabc8460771ab2c0be"
      unresolved: []
---
# Keyboard typing transformation (Telex/VNI)

_Last reviewed: 2026-08-13_

EasyKey intercepts system-wide keystrokes and transforms them into Vietnamese text per the active input method (Telex, Simple Telex, or VNI) before they reach the frontmost app, and expands macro triggers while typing. The keyboard service, its health/pause states, and the Smart Switch per-app language override all hang off this flow. The exact Telex / Simple Telex rule set is authoritative in [telex.md](telex.md); this page covers how the flow behaves end to end.

## Trigger and actors

**Trigger:** upstream event — every system-wide `CGEvent` (key down/up, flags change, mouse) matching the tap's event mask is delivered to the session event tap; typing becomes transformation when the event is a character key with the Vietnamese language active.

**Preconditions:** `KeyboardService.start()` ran and the Accessibility permission is granted (`AXIsProcessTrusted()`) — the tap is installed only then; the service is not paused.

**Actors:**

- **KeyboardEventTap** — owns the CGEvent tap (session tap, head insertion), its run-loop source, and delegates sleep/wake observation to `KeyboardSleepWakeObserver` (`KeyboardEventTap.swift:32-57, 74-79`).
- **KeyboardService** — routes tap events on a serial queue, tracks health, pause, and permission, and recovers disabled taps.
- **KeyboardInputPipeline** — applies shortcuts, per-app rules, engine transformation, macros, and Spotlight/Chromium workarounds; owns the engine, synthesizer, and macro expander (`KeyboardInputPipeline.swift:11-35`).
- **VietnameseEngine + TelexComposer** — the streaming Telex/VNI transformation and buffer recomposition (`VietnameseEngine.swift:10-63`; `TelexComposer.swift:82-117`).
- **KeySynthesizer** — emits replacement key events and marks them as self-posted.
- **WorkspaceObserver / SmartSwitchController** — per-application language and encoding overrides.
- **KeyboardDiagnosticsRecorder** — ring-buffer telemetry for health reporting.

## Happy path

1. **CGEvent tap captures system-wide keys.** `KeyboardEventTap.install` creates a `.cgSessionEventTap` at `.headInsertEventTap` for key and mouse events and adds its run-loop source; the callback runs on the main thread and forwards to `KeyboardService.handleTapEvent` (`KeyboardEventTap.swift:32-57, 82-94`).
2. **KeyboardService routes the event.** `handleTapEvent` lets self-posted events pass through untouched (`KeySynthesizer.isSelfPosted`), recovers `.tapDisabledByTimeout`/`.tapDisabledByUserInput` events, and runs `pipeline.process` on the serial `processingQueue`; a result with `suppressesOriginal` returns `nil` so the original event never reaches the app (`KeyboardService.swift:229-256`).
3. **Pipeline applies transformation with Smart Switch language.** `process` checks the emergency pause shortcut, ignored applications (bypass + session reset), flags changes, mouse events (composition reset), the language-switch shortcut, the restore-word shortcut, ignored function keys (flush + pass through when `typing.ignoreFunctionKeys` is on), and macros; when the language is Vietnamese and the input source is usable it normalizes the event and calls `engine.process` (`KeyboardInputPipeline.swift:110-183`).
4. **Engine transforms per Telex/VNI rules.** `VietnameseEngine.process` feeds each keystroke into the buffer; `TelexComposer.compose` recomputes atoms and tone per keystroke — ordered tone placement (`toneTargetIndex`), position-free marks, repeat-to-undo (`PendingUndo`), checked-final tone restriction, quick consonants, standalone `w`/bracket shortcuts, and VNI digit rules (`VietnameseEngine.swift:82-102, 135-205`; `TelexComposer.swift:82-158, 225-301, 399-436`). When live confidence scoring is enabled, low-confidence words may display raw keystrokes while composing; word boundaries still flush with Tier 1 spell-check restoration rules (`VietnameseEngine.swift:44-80, 291-304`).
5. **Macro expansion with self-posted re-entry protection.** `MacroExpander.consume` accumulates the trigger up to `MacroStore.maximumTriggerLength` and expands on a delimiter key (space, tab, return) when macros are enabled and the macro's language zone matches the active language; the synthesized backspaces, text, and delimiter events are marked self-posted, so re-entry through the tap is prevented (`KeyboardMacroExpander.swift:28-67`; `KeySynthesizer.swift:156-161, 171-215`).
6. **KeySynthesizer emits transformed output.** The pipeline's `apply` turns engine edits into posted events: `replaceBackward` (focused-text atomic replacement, selection replacement for Spotlight, physical backspace, or autocomplete-breaking), `deleteBackward`, and `insert` of unicode events tracked as encoded units; compatibility workarounds insert empty characters where needed (`KeyboardInputPipeline.swift:214-261`; `KeySynthesizer.swift:91-149`).

```mermaid
sequenceDiagram
  participant OS as CGEvent tap
  participant Service as KeyboardService
  participant Pipeline as KeyboardInputPipeline
  participant App as Frontmost app
  OS->>Service: keyDown event
  Service->>Pipeline: process(event) on serial queue
  Pipeline->>Pipeline: VietnameseEngine transform
  Pipeline->>App: KeySynthesizer posts backspace + text
  App-->>OS: synthesized events (self-posted)
```

## Branches and rules

Branches ordered by how often the trigger actually takes them.

### Accessibility permission missing or revoked

**Branches from step:** 1

**Condition:** `AXIsProcessTrusted()` is false at start, on refresh, or after wake.

**Then:** the event tap is torn down and health is `.requestingPermission`; `requestAccessibilityPermission` re-prompts the system dialog; every application activation and wake re-checks the permission (`KeyboardService.swift:98-119, 202-206`; `AppCoordinatorWiring.swift:94-107`).

**Rejoins at:** step 1 when the user grants permission and `refreshPermission` reinstalls the tap.

### Keyboard paused (emergency pause)

**Branches from step:** 2

**Condition:** the user hits the emergency pause shortcut (default Control+Option+Command, `KeyboardService.swift:34-37`) or toggles pause from the menu; the pipeline matches it before any other handling (`KeyboardInputPipeline.swift:111-114`).

**Then:** `setPaused` tears down the tap, sets health `.stopped`, and publishes the pause state; unpausing re-runs `startIfPermitted` (`KeyboardService.swift:178-190`).

**Rejoins at:** step 1 when unpaused.

### Ignored application

**Branches from step:** 3

**Condition:** the active application's bundle identifier is in `settings.compatibility.ignoredApplicationBundleIdentifiers`.

**Then:** the session is reset and the event is passed through untouched (disposition `.bypassed`) (`KeyboardInputPipeline.swift:116-120`).

**Rejoins at:** step 1 (next event).

### Foreign input source without other-language support

**Branches from step:** 3

**Condition:** the current keyboard input source is foreign (no English in `kTISPropertyInputSourceLanguages`) and `settings.compatibility.otherLanguageSupport` is off.

**Then:** the event passes through and the session resets (`KeyboardInputPipeline.swift:158-167`); `KeyboardService.refreshInputSource` recomputes this on wake and start.

**Rejoins at:** step 1.

### Function keys while typing Vietnamese

**Branches from step:** 3

**Condition:** `typing.ignoreFunctionKeys` is on (default) and the keyDown is a function key (F1–F20).

**Then:** the engine and synthesizer state are flushed and the event passes through untouched (disposition `.bypassed`), so function keys reach the active app instead of being composed as Vietnamese input. EasyKey shortcuts bound to a function key still take precedence because shortcut checks run first (`KeyboardInputPipeline.swift:148-152`).

**Rejoins at:** step 1.

### Spotlight window active

**Branches from step:** 6

**Condition:** `SpotlightWindowDetector.isSpotlightWindowVisible()` is true (an on-screen window owned by the Spotlight process; cached 0.3 s), or the app compatibility rule includes the spotlight workaround.

**Then:** replacement uses shift-arrow selection plus insertion instead of backspaces, and autocomplete breaking is enabled (`KeyboardInputPipeline.swift:214-261, 314-316, 401-407`; `SpotlightWindowDetector.swift:12-20`; `SpotlightContextResolver.swift:6, 18-31`).

**Rejoins at:** step 6.

### Chromium address bar

**Branches from step:** 6

**Condition:** the focused element is a Chromium address bar (`FocusedElementInspector.isChromiumAddressBar`, cached 1.5 s) or the compatibility rule says so.

**Then:** `shouldBreakAutocomplete` inserts a narrow no-break space and backspaces it before replacing, breaking inline autocomplete; the empty-character workarounds are skipped (`KeyboardInputPipeline.swift:250-256, 301-308, 401-407`; `KeySynthesizer.swift:113-133`; `ChromiumAddressBarContextResolver.swift:6`).

**Rejoins at:** step 6.

### Smart Switch per-app language override

**Branches from step:** 3

**Condition:** Smart Switch is enabled and the frontmost application changes (`NSWorkspace.didActivateApplicationNotification`).

**Then:** `SmartSwitchController.handleApplicationActivation` resolves the remembered choice for the app identity — applying language (and encoding when `rememberEncoding`) — or records the current choice on first focus; the coordinator then pushes `input.language` through settings into the pipeline's engine configuration; ignored and self apps are exempt (`WorkspaceObserver.swift:11-53`; `SmartSwitchController.swift:60-126`; `AppCoordinatorWiring.swift:216-223`).

**Rejoins at:** step 3 (new session for the activated app).

### Language toggle and restore-word shortcuts

**Branches from step:** 3

**Condition:** the configured switch shortcut (keyDown or flagsChanged) or the restore-word shortcut matches with Vietnamese active.

**Then:** the switch shortcut toggles the input language and suppresses the event; the restore shortcut calls `VietnameseEngine.restoreRawKeys`, which replaces the composed word with the raw keystrokes and freezes transformation per word (`KeyboardInputPipeline.swift:139-146, 350-365, 378-390`; `VietnameseEngine.swift:121-133`).

**Rejoins at:** step 1 (switch) or step 6 (restore edits are applied and posted).

### Literal technical tokens

**Branches from step:** 4

**Condition:** `typing.literalTechnicalTokens` is on (default) and the next character begins a new whitespace-delimited token (start of input or right after a word boundary) and is one of `/`, `@`, `#`, `!`, or `:` (`TypingOptions.swift:16, 32`; `VietnameseEngine.swift:13-16`).

**Then:** the engine enters literal mode for that token: the prefix and every following character — including punctuation — are passed through verbatim (suppressed and re-inserted) instead of being composed as Vietnamese, so slash commands, mentions, references, shell mode, and shortcodes in coding agents and chat apps type as-is (`VietnameseEngine.swift:135-163`). The mode ends at the next space, tab, or return, and Vietnamese transformation resumes for the following token. Backspace deletes the literal characters one at a time and exits literal mode once the prefix itself is removed; arrow keys, escape, and session resets cancel it (`VietnameseEngine.swift:230-245, 306-311`). A lone `!` still counts as a sentence terminator for capitalization (`VietnameseEngine.swift:318-326`).

**Rejoins at:** step 6 (literal keystrokes are inserted as synthesized events) or step 1 (after the token's whitespace).

**Other rules:** sentence-start capitalization applies per configuration when the buffer is empty (`VietnameseEngine.swift:176-181`); spell check with `autoRestoreKeys` decides whether an invalid composed word reverts to raw keys at word boundaries (`VietnameseEngine.swift:291-304`); mouse events always reset composition state, and non-Shift flags changes do too — a bare Shift press/release preserves an in-progress composition so an uppercase first letter followed by a tone key isn't lost (`KeyboardInputPipeline.swift:126-131, 350-376`).

## Failure and recovery

Ordered by blast radius, most severe first. Evidence is the health states and recovery paths in `KeyboardService`.

### Event tap install failure

**Detected by:** `CGEvent.tapCreate` or run-loop source creation returning nil (`KeyboardEventTap.swift:38-49`).

**Immediate response:** fail fast — the tap is not installed and health becomes `.failed` (`KeyboardService.swift:221-226`).

**State left behind:** no tap exists; keystrokes pass through untouched.

**Recovery:** `restartKeyboardService` in the status menu (or the app coordinator) stops and restarts the service, re-running permission checks (`EasyKeyApp/Coordination/AppCoordinator.swift:326-335`).

**Escalation boundary:** none — the status item shows health; the user restarts the service.

### Tap disabled by system

**Detected by:** `.tapDisabledByTimeout` or `.tapDisabledByUserInput` events in `handleTapEvent`.

**Immediate response:** the event passes through, the diagnostic is recorded with disposition `.disabled`, and `recoverTapAfterDisable` tears the tap down, sets health `.degraded`, and re-checks permission (`KeyboardService.swift:229-243, 258-265`).

**State left behind:** composition state is lost with the tap teardown; the original event reached the app.

**Recovery:** automatic — `refreshPermission` reinstalls the tap once trusted.

**Escalation boundary:** none.

### Sleep and wake

**Detected by:** `NSWorkspace.willSleepNotification` / `didWakeNotification` observers in `KeyboardSleepWakeObserver` (`KeyboardSleepWakeObserver.swift:12-30`).

**Immediate response:** on sleep the tap is torn down and health becomes `.degraded`; on wake the input source and permission are refreshed (`KeyboardService.swift:192-206`).

**State left behind:** the session is reset (`AppCoordinatorWiring.swift:102-106`).

**Recovery:** automatic on wake — `startIfPermitted` reinstalls the tap.

**Escalation boundary:** none.

### Output synthesis failure

**Detected by:** `KeySynthesizer` event-creation failures (`makeUnicodeEvents`/`makePhysicalKeyEvents` returning nil, or a replacement strategy of `.failed`); `apply` returns false.

**Immediate response:** the session resets and the original event passes through unmodified (`KeyboardInputPipeline.swift:178-181`; `KeySynthesizer.swift:263-277, 344-363`).

**State left behind:** composition is cleared; the app received raw keystrokes.

**Recovery:** the user simply keeps typing — the next keystroke starts a fresh session.

**Escalation boundary:** none.

## Outcome

**On success:** each keystroke either passes through or is replaced by synthesized events that render the correctly composed Vietnamese word in the frontmost app; macro triggers expand; health is `.active`; diagnostics feed the latency and disposition telemetry (`EasyKeyKit/Keyboard/Diagnostics/KeyboardDiagnosticsRecorder.swift:29-54`).

**On safe failure:** when transformation cannot be applied, the original event is always delivered — the app never loses a keystroke, and self-posted output never loops back through the engine.

**Deferred work:** diagnostics continue recording after each event; Smart Switch records remembered choices after the user manually switches language (`SmartSwitchController.swift:128-162`).

> **Related:** [Flows index](README.md) tracks discovery status and priority for this flow.
