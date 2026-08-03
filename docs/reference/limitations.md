---
id: "limitations"
title: "Limitations"
docforge_provenance:
  schema: "2.0"
  doc_id: "limitations"
  path: "docs/reference/limitations.md"
  generated_at: "2026-08-03T08:48:15Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "deep-dive"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "limitations-and-known-issues"
      sources:
        - path: "README.md"
          role: "doc"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
      unresolved: []
    - id: "known-limitations"
      sources:
        - path: "docs/_archive/PROBLEMS.md"
          role: "doc"
          git_blob: "acb0eac12772c9857d236b931083ae0de175c6fe"
        - path: "EasyEngineCore/Clipboard/ClipboardEntry.swift"
          role: "code"
          git_blob: "2b6b2d0d1e12143a526f8aca275cee59a3a5b017"
        - path: "EasyKeyApp/AppDelegate.swift"
          role: "code"
          git_blob: "8ecc5922afe0e99166cbcf3425afd2514b887ae2"
        - path: "EasyKeyApp/Info.plist"
          role: "config"
          git_blob: "f4603871fa675111bd6db1472dfb04936ff3f645"
        - path: "EasyKeyApp/Features/Translation/AppTranslationRuntime.swift"
          role: "code"
          git_blob: "c4df84fdde3f664cd167d91ce3a64b387e6ef30e"
        - path: "EasyEngineCore/Translation/TranslationPlatformCapability.swift"
          role: "code"
          git_blob: "414733ed3284bccb04ed05bb1cd1b0d6bd09e99a"
      unresolved: []
    - id: "known-issues"
      sources:
        - path: "Makefile"
          role: "config"
          git_blob: "b8fa0059c061eef05cb083ae69e8e7d46336aa64"
        - path: "README.md"
          role: "doc"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
      unresolved: []
    - id: "not-supported"
      sources:
        - path: "README.md"
          role: "doc"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
        - path: "docs/_archive/RELEASE.md"
          role: "doc"
          git_blob: "c749b17a004e3cf47af6af61e82db4aa9d40494d"
      unresolved: []
    - id: "scale-and-performance-envelope"
      sources:
        - path: "EasyEngineCore/Clipboard/ClipboardOptions.swift"
          role: "code"
          git_blob: "f1409bbfebea82ad1d8e76ec6d75612f0b1b7a93"
        - path: "EasyEngineCore/Settings/SettingsRepository.swift"
          role: "code"
          git_blob: "f718fcf9ea3a84f0aa770650c15c8c059e450a19"
        - path: "EasyEngineCore/Macros/MacroStore.swift"
          role: "code"
          git_blob: "b8a7256fcac4629b3824c752dd654f849170de08"
        - path: "EasyEngineCore/Translation/TranslationOptions.swift"
          role: "code"
          git_blob: "1c0c39a3d9bc405c47c447ac21c90b0d9545d89f"
        - path: "EasyKeyKit/KeyboardService.swift"
          role: "code"
          git_blob: "3d2db069ec81fb639d6eb9a6fc69121580854d31"
      unresolved: []
    - id: "deployment-specific-caveats"
      sources:
        - path: "docs/_archive/RELEASE.md"
          role: "doc"
          git_blob: "c749b17a004e3cf47af6af61e82db4aa9d40494d"
        - path: "docs/_archive/PROBLEMS.md"
          role: "doc"
          git_blob: "acb0eac12772c9857d236b931083ae0de175c6fe"
      unresolved: []
---
# Limitations and known issues

_Last reviewed: 2026-08-03_

Read this before building on EasyKey. Several limits are deliberate
consequences of macOS platform behavior or of the app's privacy posture —
they are trade-offs, not defects — and are tracked in
[PROBLEMS.md](limitations.md) or the product README
([product overview](../product/overview.md)) rather than as open bugs.

## Known limitations

Design constraints and deliberate trade-offs — the shape of the system, not defects.

| Area | Limitation | Impact | Workaround | Tracking |
|---|---|---|---|---|
| Spotlight typing | Typing Vietnamese into Spotlight (`⌘Space`) can look briefly broken right after opening it, then self-correct. Spotlight never activates as an `NSRunningApplication`, exposes no usable `AXUIElement` focus, and its autocomplete eats plain backspace, so EasyKey falls back to a selection-replacement workaround gated on a 0.3 s `CGWindowListCopyWindowInfo` detection cache. | Users who start typing immediately after invoking Spotlight see a moment of literal keystrokes or duplicated characters (`ttttuyền`). | Pause a beat before typing, or retype; restarting EasyKey helps if it persists. No API exists to fix it from outside Spotlight. | [PROBLEMS.md](limitations.md) |
| Ignored-applications filtering | The ignored-application lists (typing and clipboard) are best-effort filters, not a security boundary: macOS cannot always identify the source application of a clipboard change or focus event. | Content copied in an ignored app can still be captured; typing rules can still apply where a filter missed the app. | Do not rely on these lists for confidentiality; disable capture entirely when it matters. | [product overview](../product/overview.md), `ClipboardSource` in `ClipboardEntry.swift` |
| Clipboard source attribution | `ClipboardSource.applicationName` / `bundleIdentifier` are advisory: macOS exposes no pasteboard source, so attribution can be missing or wrong. | The clipboard panel may show no source or a misattributed one. | Treat source display as informational only. | `ClipboardEntry.swift` |
| Accessory app windows | The app runs as an accessory (`LSUIElement`, activation policy `.accessory`), so its windows do not appear in the Dock or Cmd-Tab and cannot reliably become the key window in normal operation. | Users cannot switch to EasyKey like a regular app; paste-in-place and panel focus depend on panel subclasses overriding `canBecomeKey`. | Panels are presented from the menu bar; Settings opens from the menu. No workaround needed for normal use. | `AppDelegate.swift`, `Info.plist` |
| Apple Translation availability | On-device Apple Translation exists only on macOS 15+ (`TranslationPlatformCapability` is computed with `if #available(macOS 15.0, *)`). On macOS 14 the Apple provider is unsupported and Automatic resolution falls back to a configured cloud provider. | macOS 14 users get no on-device translation option. | Configure a cloud provider, or leave translation off. | `AppTranslationRuntime.swift`, `TranslationPlatformCapability.swift` |
| Ad-hoc signed distribution | Current public builds are universal and ad-hoc signed but not Developer ID notarized. | Gatekeeper blocks first launch with an "unidentified developer" warning. | Control-click → Open, or System Settings → Privacy & Security → Open Anyway. | [product overview](../product/overview.md), [RELEASE.md](../engineering/release.md) |

## Known issues

Defects under investigation.

| Issue | Symptom | Affected versions | Status |
|---|---|---|---|
| Headless CI hit-testing | Real-window click-then-verify-effect UI tests cannot reliably run on hosted macOS CI runners: the accessibility tree is queryable and `isHittable` reports true, but window activation never lands, so tests flake or fail. EasyKey therefore activates as a `.regular` app under `--uitesting`. | CI only; not a shipped-app behavior | Known; the affected test shard is executed but never blocks merge (see [Makefile](../../Makefile) shard filters and the AppDelegate comment). |
| Parallel UI test shards | `make test-parallel` shards share one `UserDefaults` domain on a single Mac, so UI shards may flake against each other's persisted state. | Local parallel runs | Known; `make test` (serial) is the reliable local default; CI runs shards on separate runners. |
| Spotlight startup detection race | The `CGWindowListCopyWindowInfo` poll does not see the Spotlight panel instantly; keystrokes in that gap bypass the workaround. | All macOS versions | Documented platform behavior, not fixable from outside Spotlight. |

## Not supported

Things a reasonable person expects and will not find.

- Input Method Kit input sources. EasyKey uses a `CGEvent` tap plus the Accessibility API instead — a deliberate architecture choice (see [product overview](../product/overview.md)); no IMK input source is produced.
- Any non-macOS platform. The deployment target is macOS 14.0+; iOS, iPadOS, and visionOS are not planned.
- Cloud-translation proxying. EasyKey sends source text directly to the selected provider from translation surfaces only; there is no EasyKey relay server, and this is a privacy feature, not a gap.
- Notarized distribution as of the current public release. The release pipeline is wired for Developer ID signing and notarization (see [RELEASE.md](../engineering/release.md)) but requires certificate and notary credentials that current builds do not ship with.
- Synchronizing or cloud-backed clipboard history. Persisted history is AES-GCM sealed with a device-only, non-synchronizing Keychain key; iCloud sync of history is not planned.

## Scale and performance envelope

| Dimension | Tested limit | Notes |
|---|---|---|
| Clipboard entries per history | Default 100 (`ClipboardOptions.maximumEntryCount`), configurable | Beyond the cap, oldest unpinned entries are trimmed (retention default 7 days). |
| Settings import file size | 1 MiB (`SettingsRepository.maxImportFileBytes`) | Larger files are rejected with `SettingsRepositoryError.importFileTooLarge`. |
| Macro trigger length | 128 characters (`MacroStore.maximumTriggerLength`) | Longer triggers are rejected at add/edit. |
| Macro expansion length | 16384 characters (`MacroStore.maximumExpansionLength`) | Beyond this the store refuses to save. |
| Auto-translate delay presets | 250–1500 ms (`TranslationOptions.AutoTranslateDelayPreset`) | Values outside presets are rejected by the settings model. |
| Keyboard callback latency | Measured, surfaced via `KeyboardService.medianCallbackLatencyNanoseconds` and the System health card | No published upper bound; latency tests assert no unbounded growth during sustained typing. |

Beyond these figures the system is untested rather than known to fail.

## Deployment-specific caveats

- On macOS 14, translation settings expose cloud providers only; the Apple card is hidden because the platform capability is false.
- Manual release gates in [RELEASE.md](../engineering/release.md) require re-testing the login helper after reboot and after macOS upgrade, Accessibility reauthorization when bundle identity or signing team changes, and a Sparkle rejection test with an unsigned archive.
- `make test-parallel` is a sharded convenience; treat its failures as suspicious until confirmed by a serial `make test` run.
- Spotlight behavior notes in [PROBLEMS.md](limitations.md) apply to every macOS version EasyKey supports.
