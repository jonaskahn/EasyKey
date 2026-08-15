# Limitations and known issues

_Last reviewed: 2026-08-15_

Read this before building on EasyKey. Several limits are deliberate
consequences of macOS platform behavior or of the app's privacy posture —
they are trade-offs, not defects — and are tracked in
this document's [known-limitations table](#known-limitations) or the product
README
([product overview](../product/overview.md)) rather than as open bugs.

## Known limitations

Design constraints and deliberate trade-offs — the shape of the system, not defects.

| Area | Limitation | Impact | Workaround | Tracking |
|---|---|---|---|---|
| Spotlight typing | Typing Vietnamese into Spotlight (`⌘Space`) can look briefly broken right after opening it, then self-correct. Spotlight never activates as an application, so the only dependable signal that keystrokes are going to it is an on-screen window owned by the `Spotlight` process; EasyKey polls `CGWindowListCopyWindowInfo` for that window (0.3 s detection cache) and switches composition to a selection-replacement workaround instead of plain backspaces. | Users who start typing immediately after invoking Spotlight see a moment of literal keystrokes or duplicated characters before the detector catches up. | Pause a beat before typing, or retype; restarting EasyKey helps if it persists. No API exists to fix it from outside Spotlight. | This page |
| Ignored-applications filtering | The ignored-application lists (typing and clipboard) are best-effort filters, not a security boundary: macOS cannot always identify the source application of a clipboard change or focus event. | Content copied in an ignored app can still be captured; typing rules can still apply where a filter missed the app. | Do not rely on these lists for confidentiality; disable capture entirely when it matters. | [product overview](../product/overview.md), `ClipboardSource` in `ClipboardEntry.swift` |
| Clipboard source attribution | `ClipboardSource.applicationName` / `bundleIdentifier` are advisory: macOS exposes no pasteboard source, so attribution can be missing or wrong. | The clipboard panel may show no source or a misattributed one. | Treat source display as informational only. | `ClipboardEntry.swift` |
| Accessory app windows | The app runs as an accessory (`LSUIElement`, activation policy `.accessory`), so its windows do not appear in the Dock or Cmd-Tab and cannot reliably become the key window in normal operation. | Users cannot switch to EasyKey like a regular app; paste-in-place and panel focus depend on panel subclasses overriding `canBecomeKey`. | Panels are presented from the menu bar; Settings opens from the menu. No workaround needed for normal use. | `AppDelegate.swift`, `Info.plist` |
| Apple Translation availability | On-device Apple Translation exists only on macOS 15+ (`AppTranslationRuntime` builds the Apple provider only under `if #available(macOS 15.0, *)` and constructs `TranslationPlatformCapability(supportsAppleTranslation: false)` on older systems). On macOS 14 the Apple provider is unsupported and Automatic resolution falls back to a configured cloud provider. | macOS 14 users get no on-device translation option. | Configure a cloud provider, or leave translation off. | `AppTranslationRuntime.swift`, `TranslationPlatformCapability.swift` |
| Ad-hoc signed distribution | Current public builds are universal and ad-hoc signed but not Developer ID notarized. | Gatekeeper blocks first launch with an "unidentified developer" warning. | Control-click → Open, or System Settings → Privacy & Security → Open Anyway. | [distribution.md](../operations/distribution.md) |

## Known issues

Defects under investigation.

| Issue | Symptom | Affected versions | Status |
|---|---|---|---|
| Headless CI hit-testing | Real-window click-then-verify-effect UI tests cannot reliably run on hosted macOS CI runners: the accessibility tree is queryable and `isHittable` reports true, but window activation never lands, so tests flake or fail. EasyKey therefore activates as a `.regular` app under `--uitesting`. | CI only; not a shipped-app behavior | Known; the affected test shard is executed but never blocks merge (the CI workflow's `ui-known-broken-on-hosted-runner` shard runs with `continue-on-error`; see the [Makefile](../../Makefile) shard filters and the AppDelegate comment). |
| Parallel UI test shards | `make test-parallel` runs its shards serially on one Mac because every shard launches the same `EasyKey.app` bundle (`EasyKeyTests` is app-hosted via `TEST_HOST`), so concurrent shards would kill each other's app instances mid-test ("Lost connection to the application"). | Local runs of the sharded target | Known; `make test` (serial) is the reliable local default; CI runs each shard on its own runner and can parallelize. |
| Spotlight startup detection race | The `CGWindowListCopyWindowInfo` poll does not see the Spotlight panel instantly; keystrokes in that gap bypass the workaround. | All macOS versions | Documented platform behavior, not fixable from outside Spotlight. |

## Not supported

Things a reasonable person expects and will not find.

- Input Method Kit input sources. EasyKey uses a `CGEvent` tap plus the Accessibility API instead — a deliberate architecture choice (see [product overview](../product/overview.md)); no IMK input source is produced.
- Any non-macOS platform. The deployment target is macOS 14.0+ (`MACOSX_DEPLOYMENT_TARGET`, `LSMinimumSystemVersion`); the build defines no iOS, iPadOS, or other Apple-platform targets in the Xcode project.
- Cloud-translation proxying. EasyKey sends source text directly to the selected provider from translation surfaces only; there is no EasyKey relay server, and this is a privacy feature, not a gap.
- Notarized distribution as of the current public release. The release pipeline is wired for Developer ID signing and notarization (see [distribution.md](../operations/distribution.md)) but requires certificate and notary credentials that current builds do not ship with.
- Synchronizing or cloud-backed clipboard history. Persisted history is AES-GCM sealed with a device-only, non-synchronizing Keychain key (`ClipboardKeyStore`); no clipboard data leaves the device.

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
- Release verification in [distribution.md](../operations/distribution.md) covers the artifact checks (`verify-arch.sh` for both architectures, `verify-release.sh` for bundled LICENSE/NOTICE/THIRD_PARTY_NOTICES, and spctl assessment on the signed path).
- `make test-parallel` is a sharded convenience; treat its failures as suspicious until confirmed by a serial `make test` run.
- Spotlight behavior notes above apply to every macOS version EasyKey supports.
