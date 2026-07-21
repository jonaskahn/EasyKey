# Known Platform Problems

Issues below are caused by macOS system behavior EasyKey cannot control, not by EasyKey's own logic. They are documented here rather than tracked as bugs.

## Spotlight Search Field

Typing Vietnamese into Spotlight (`⌘Space`) is inherently harder to support than a normal text field, for reasons rooted entirely in how Spotlight is built:

1. **Spotlight is not a regular app.** It never activates as an `NSRunningApplication` and never posts `NSWorkspace.didActivateApplicationNotification`, so the usual per-application detection that most of EasyKey's compatibility rules rely on never fires for it. The only way to know Spotlight is on screen is to poll `CGWindowListCopyWindowInfo` for a window owned by `"Spotlight"` — an on-screen-window heuristic, not a real focus event.

2. **No Accessibility access to its text field.** Spotlight's search field does not expose a usable `AXUIElement` focused-text reference to third-party Accessibility clients. EasyKey's normal "read the focused text and replace it directly" path (used for Chrome's address bar, etc.) simply has nothing to attach to here. The only remaining option is a blind workaround: select backward with `Shift+←` for the composed syllable's grapheme count, then retype over the selection.

3. **Spotlight's own autocomplete eats backspace.** Spotlight shows a live suggestion/completion inline as you type. A plain backspace keystroke deletes the suggestion overlay instead of the character underneath it, which is what produced the duplicated-character bug ("ttttuyền") before the selection-replacement workaround existed. Arrow keys are used deliberately because they cancel the suggestion first; backspace bursts do not.

4. **Detection has a startup lag.** `CGWindowListCopyWindowInfo` does not report the Spotlight panel the instant it opens — there is a short window (governed by EasyKey's 0.3s detection cache) where the panel is on screen but not yet visible to the poll. Keystrokes typed in that gap bypass the Spotlight workaround. This is why typing can look broken for a moment right after invoking Spotlight and then self-corrects shortly after — it is a detection race, not a persistent failure.

None of the above can be fixed from outside Spotlight: there is no public API for its internal focus, selection, or completion state. The selection-replacement workaround is the same approach used by [OpenKey](https://github.com/tuyenvm/OpenKey), which hit the same platform constraints.
