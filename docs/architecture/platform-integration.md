# Platform integration

_Last reviewed: 2026-08-15_

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

**Callback contract:** none — synchronous `SecItem` calls; translation credentials go through the narrow `SecItemAccessing` seam (also the test injection point), and the clipboard key store calls `SecItem*` directly.

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

**Fallback if unavailable:** missing HTTPS feed or ED key disables the updater at init (with a log line) — the app runs untouched; a failed check leaves the current version installed.

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
