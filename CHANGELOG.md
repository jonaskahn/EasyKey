---
docforge_provenance:
  schema: "2.0"
  doc_id: "changelog"
  path: "CHANGELOG.md"
  generated_at: "2026-08-03T09:24:40Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "reference"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "changelog"
      sources:
        - path: "README.md"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
          role: "doc"
        - path: "docs/reference/platform-compatibility.md"
          git_blob: "8cf9debf8d8f66f4d5247b5f87fceeb45463f605"
          role: "doc"
      unresolved: []
    - id: "unreleased"
      sources:
        - path: "EasyKey.xcodeproj/project.pbxproj"
          git_blob: "3fc1f4a80e4851be8a519efbb99f80102a4b41d4"
          role: "history"
        - path: "README.md"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
          role: "doc"
      unresolved: []
    - id: "007-2026-07-23"
      sources:
        - path: "EasyKey.xcodeproj/project.pbxproj"
          git_blob: "3fc1f4a80e4851be8a519efbb99f80102a4b41d4"
          role: "history"
        - path: "README.md"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
          role: "doc"
        - path: "docs/_archive/RELEASE.md"
          git_blob: "c749b17a004e3cf47af6af61e82db4aa9d40494d"
          role: "doc"
        - path: "docs/security/threat-model.md"
          git_blob: "11052cc08965a7b20651d827ee29645154b0578c"
          role: "doc"
      unresolved: []
    - id: "006-2026-07-22"
      sources:
        - path: "EasyKey.xcodeproj/project.pbxproj"
          git_blob: "3fc1f4a80e4851be8a519efbb99f80102a4b41d4"
          role: "history"
        - path: "README.md"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
          role: "doc"
      unresolved: []
    - id: "005-2026-07-21"
      sources:
        - path: "EasyKey.xcodeproj/project.pbxproj"
          git_blob: "3fc1f4a80e4851be8a519efbb99f80102a4b41d4"
          role: "history"
        - path: "README.md"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
          role: "doc"
      unresolved: []
    - id: "004-2026-07-21"
      sources:
        - path: "EasyKey.xcodeproj/project.pbxproj"
          git_blob: "3fc1f4a80e4851be8a519efbb99f80102a4b41d4"
          role: "history"
        - path: "README.md"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
          role: "doc"
      unresolved: []
    - id: "003-2026-07-21"
      sources:
        - path: "EasyKey.xcodeproj/project.pbxproj"
          git_blob: "3fc1f4a80e4851be8a519efbb99f80102a4b41d4"
          role: "history"
        - path: "README.md"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
          role: "doc"
      unresolved: []
    - id: "002-2026-07-21"
      sources:
        - path: "EasyKey.xcodeproj/project.pbxproj"
          git_blob: "3fc1f4a80e4851be8a519efbb99f80102a4b41d4"
          role: "history"
        - path: "README.md"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
          role: "doc"
      unresolved: []
    - id: "001-2026-07-18"
      sources:
        - path: "EasyKey.xcodeproj/project.pbxproj"
          git_blob: "3fc1f4a80e4851be8a519efbb99f80102a4b41d4"
          role: "history"
      unresolved: []
    - id: "release-history"
      sources:
        - path: "EasyKey.xcodeproj/project.pbxproj"
          git_blob: "3fc1f4a80e4851be8a519efbb99f80102a4b41d4"
          role: "history"
        - path: "README.md"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
          role: "doc"
      unresolved: []
---
# Changelog

_Last reviewed: 2026-08-03_

Notable changes to EasyKey. Format follows Keep a Changelog; versioning follows Semantic Versioning. EasyKey requires macOS 14.0 or later; see [platform compatibility](docs/reference/platform-compatibility.md) for the tested minimums.

## [0.0.8] - 2026-08-11

**Added**

- Optional Tier 2 live-confidence scoring: while typing, show raw keystrokes when the in-progress word looks unlikely to be Vietnamese; Tier 1 spell-check at word boundaries is unchanged (off by default).
- Optional iOS-UniKey-like mode (on by default): after repeating a Telex key to remove its mark, the rest of that word stays literal until a space or punctuation, so `seeen` becomes `seen` and `resstore` becomes `restore` instead of re-applying diacritics.
- Optional literal technical tokens (on by default): words starting with `/`, `@`, `#`, `!`, or `:` type as-is without Vietnamese conversion — slash commands, mentions, references, shell mode, and shortcodes in coding agents and chat apps — with Vietnamese resuming after the next space.

## [0.0.7] - 2026-07-23

**Security**

- Diagnostic log exports now redact sensitive keys and restrict output file permissions to 0600.
- The Sparkle toolchain download is pinned by SHA256, and the Sparkle public key is a parameterized build setting (see [RELEASE.md](docs/engineering/release.md) and the [threat model](docs/security/threat-model.md) for the update channel).

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

Initial public release of the EasyKey Vietnamese typing utility. The current capability set is described in [product overview](docs/product/overview.md).

## Release history

The entries above are summarized from tag-to-tag commit subjects and the tag dates; the full commit history is in git.
