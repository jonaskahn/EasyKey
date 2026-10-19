# Changelog

_Last reviewed: 2026-10-19_

Notable changes to EasyKey. Format follows Keep a Changelog; versioning follows Semantic Versioning. EasyKey requires macOS 14.0 or later; tested OS and Mac minimums are owned by [platform compatibility](docs/reference.md#platform-compatibility) in the compact reference. Supported report scope for a given version is in [SECURITY.md](SECURITY.md). How a version is built and published is in [CONTRIBUTING.md](CONTRIBUTING.md) and [engineering](docs/engineering.md#release).

## [Unreleased]

## [0.1.0] - 2026-10-19

**Fixed**

- Macro expansion deletes the rendered trigger rather than its raw Telex key count, accepts Shift, handles backspace, and clears stale triggers after navigation or app changes.
- Safari and Terminal have native compatibility rules and appear in the default compatibility list.
- `Huaan`, `tuaanf`, `thuaatj`, `Huees`, `thuees`, `hoawcj`, `xoawn`, and `ngoawnf` no longer revert to raw keys at a word boundary.
- `Onw`, `onw`, `anw`, and `Anw` now become `Ơn`, `ơn`, `ăn`, and `Ăn`.
- Vietnamese composition now emits only the changed suffix instead of replacing the whole word on every keystroke, which removes the visible flash.
- Chromium and VSCode no longer post an invisible workaround character after every keystroke.

**Added**

- System settings include live verbose keyboard diagnostics and log export. Diagnostics record decisions and counts without typed text; exports retain the newest entries.

## [0.0.15] - 2026-10-16

**Security**

- Release DMGs are now signed with a Developer ID certificate and notarized by Apple, so Gatekeeper opens them without the Control-click workaround. The archived app, its login helper and Sparkle are all signed with the hardened runtime, which notarization requires and which `make verify-release` now asserts.

**Fixed**

- Vietnamese text typed into Chromium/Electron web-page fields and Safari is now precomposed (NFC) again: these apps had been forced to combining-diacritic output, which rendered correctly but broke website search and find-in-page because sites compare precomposed text. All Unicode-class typing output is now canonically composed at the emission point (legacy TCVN3/VNI Windows/CP1258 output is unchanged), and the user's typing-encoding setting is honored in every app.
- The Chromium zero-width-space (and VSCode word-joiner) workaround is now transient — inserted and immediately deleted — instead of being left in the field until the next edit. A leftover invisible character used to travel inside search queries (live filtering while typing, and submits after "query + space + Enter") so site search never matched.

**Added**

- `make update-secrets` stages the signing, notarization and Sparkle credentials in GitHub for the Release workflow. The Developer ID `.p12` is exported from the keychain rather than pasted, and the Sparkle keypair is read from it instead of regenerated, so a published update-trust key is never rotated by accident.

## [0.0.14] - 2026-08-27

**Fixed**

- Typing multi-syllable Vietnamese words in Chromium web-page fields no longer produces duplicated characters (for example "tuyeenf nguyeenx" rendering as "ttututuyền nnngnguyễn"): replacement backspaces are now counted per UTF-16 code unit in Chromium page fields, matching how Blink deletes combining-diacritic output, while native fields (Safari, Spotlight, the Chrome omnibox, VSCode) keep grapheme-cluster counting.

**Added**

- Opt-in keyboard diagnostics (enable with EASYKEY_KEYBOARD_DEBUG) that log detection state and hex-dumped field/payload lengths to help reproduce field-divergence bugs without logging raw keystroke content.

## [0.0.13] - 2026-08-27

**Fixed**

- Typing a second Vietnamese word after a space in Chrome and Safari no longer deletes the space (or preceding characters): replacement backspaces are now counted per grapheme cluster instead of per UTF-16 unit, matching how apps delete text with combining-diacritic output.
- Chromium compatibility workarounds (zero-width space insertion, combining output, autocomplete breaks) no longer leak into Spotlight: because Spotlight opens without an activation event, the pipeline now detects the Spotlight context and applies the Spotlight rule instead of the previously active app's rule.

## [0.0.12] - 2026-08-26

**Fixed**

- Pressing Return while a Vietnamese word is composing no longer needs a second press in Chrome and other apps: the commit now re-posts a physical Return (and Tab) key event instead of a unicode newline, and Chrome no longer receives a stray zero-width space after the committed word.

## [0.0.11] - 2026-08-15

**Added**

- The chosen translation provider is now remembered and restored on next launch instead of always resetting to the default.
- A warning in translation settings when saving a cloud provider key fails, and a "Choose Provider" empty state in the provider picker when no provider is available.

**Changed**

- The provider picker rows highlight the selected provider and show hover feedback; the trigger button no longer adds its own background.
- Saving a cloud provider key now falls back to adding the item when updating a missing one, and the Data Protection keychain flag was removed so classic login-keychain items remain readable.

**Fixed**

- Smart switch now tracks the correct state when EasyKey is the frontmost app.

## [0.0.10] - 2026-08-15

**Added**

- Selectable menu bar icon style: 12 styles with localized names in System settings; the default is "Inverted Solid Capsule (Dark Pill)" and the E/V letter still follows the active input language.
- Monitoring toggle in the menu bar popover status area: turn EasyKey on or off for the current app without opening Settings.

**Changed**

- Menu bar icons (all styles plus the pause and health indicators) render at a user-selectable scale: 1.0×–1.5×, default 1.3×.
- The popover monitor row now shows the current app name as its title, the language in use below it (e.g. "Use Vietnamese"), and a Monitor toggle.

**Fixed**

- The popover status now keeps showing the app you are working in instead of changing to "EasyKey" whenever the popover opens.
- Shortcuts in Typing, Translation, and Clipboard settings now change only after pressing Record; key combinations pressed while browsing settings no longer reassign them.

## [0.0.9] - 2026-08-14

**Changed**

- Macro categories when adding or editing are now English, Vietnamese, or Both; the 9x and Gen Z packs remain available as sample macros only.

## [0.0.8] - 2026-08-14

**Added**

- Optional Tier 2 live-confidence scoring: while typing, show raw keystrokes when the in-progress word looks unlikely to be Vietnamese; Tier 1 spell-check at word boundaries is unchanged (off by default).
- Optional iOS-UniKey-like mode (on by default): after repeating a Telex key to remove its mark, the rest of that word stays literal until a space or punctuation, so `seeen` becomes `seen` and `resstore` becomes `restore` instead of re-applying diacritics.
- Optional literal technical tokens (on by default): words starting with `/`, `@`, `#`, `!`, or `:` type as-is without Vietnamese conversion — slash commands, mentions, references, shell mode, and shortcodes in coding agents and chat apps — with Vietnamese resuming after the next space.
- Macros can expand in a chosen language zone: English only, Vietnamese only, or both.
- Built-in sample macros: ready-made expansions can be added from the macro editor with one click.

**Fixed**

- Function keys (F1–F20) no longer get swallowed while typing Vietnamese: a new pass-function-keys-through option (on by default) flushes the composition and lets function keys reach the active app.
- Telex tone marks now compose correctly after an uppercase vowel, and releasing Shift mid-word no longer drops the pending mark.
- Macros now expand in Chrome/Spotlight contexts, and the macro editor sheet no longer clips its content.

**Changed**

- Translation defaults to Apple on-device translation; the automatic provider option is removed, provider selection happens in settings, and translation settings copy is localized in English and Vietnamese.

## [0.0.7] - 2026-07-23

**Security**

- Diagnostic log exports now redact sensitive keys and restrict output file permissions to 0600.
- The Sparkle toolchain download is pinned by SHA256, and the Sparkle public key is a parameterized build setting.

**Fixed**

- Importing a malformed settings document now surfaces a clear error instead of a silent warning path.
- Typing engine: invalid VNI tone digits are dropped, undo semantics are aligned, sentence-start state clears on empty backspace, and a restored raw word commits on the next character after force-raw.
- Macro expansion gained a loop-detection fallback.
- Clipboard monitoring short-circuits its poll when no content kinds are captured, and clipboard start/stop task cancellation is chained safely.
- Quitting now awaits coordinator shutdown and settings save; model-catalog load cancels its prior task.
- Removed URL force-unwrap and `fatalError` crash paths in the app shell.

**Changed**

- Keyboard-service updates are gated on actual settings changes (`SettingsDelta`), reducing churn.
- The System Health card surfaces median callback latency, and keyboard diagnostics recording is enabled by default.
- Translation provider availability is exposed in translation settings.

## [0.0.6] - 2026-07-22

**Changed**

- Auto-capture translation is replaced by a double Command-C gesture that quick-translates, with language updates.

## [0.0.5] - 2026-07-21

**Changed**

- The default input rule is Simple Telex.
- A new translate shortcut with auto-capture mode was added.
- The Spotlight typing glitch was fixed.
- CI was split so merges are not blocked by tests that cannot pass on hosted macOS runners.

## [0.0.4] - 2026-07-21

**Changed**

- The Telex engine was re-implemented; translation layout and provider handling were updated; sources were reorganized into separate classes.

## [0.0.3] - 2026-07-21

**Changed**

- Translation panel sizing, session control, and safer shortcuts; the Apple Translate provider language-selection popup was fixed.

## [0.0.2] - 2026-07-21

**Added**

- Opt-in private clipboard manager.
- Macro expansion at word boundaries.
- Cloud translation providers alongside on-device translation.

**Fixed**

- Engine shortcuts are preserved when settings change; logging stays private; key codes are omitted from diagnostics; clipboard history persistence survives replace; history deletion asks for confirmation first.

## [0.0.1] - 2026-07-18

Initial public release of the EasyKey Vietnamese typing utility. The current capability set is owned by [product](docs/product.md).

## Release history

The entries through 0.0.7 are summarized from tag-to-tag commit subjects and the tag dates; 0.0.8 and 0.0.9 (both tagged 2026-08-14) are summarized from the commits since `v0.0.7` and the `v0.0.8`/`v0.0.9` tag history. Unreleased is empty until the next tagged release. The full commit history is in git.
