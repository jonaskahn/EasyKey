---
id: "observability"
title: "Observability"
description: "Signals, ownership, correlation, alert intent, blind spots"
docforge_provenance:
  schema: "2.0"
  doc_id: "observability"
  path: "docs/operations/observability.md"
  generated_at: "2026-08-13T11:23:28Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "deep-dive"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "signals"
      sources:
        - path: "EasyEngineCore/Diagnostics/AppLog.swift"
          git_blob: "827ef0baa84980d0df634f19d06d944c856a4293"
          role: "code"
        - path: "EasyKeyApp/Features/Settings/System/SystemHealthCard.swift"
          git_blob: "45184202082f9947ebb6885a1f9e694d0cb2844d"
          role: "code"
        - path: "EasyKeyKit/Keyboard/Diagnostics/KeyboardDiagnosticsRecorder.swift"
          git_blob: "5b06cb65f184556907e6ae44d093dc4fae536505"
          role: "code"
        - path: "EasyKeyKit/Keyboard/KeyboardService.swift"
          git_blob: "3246c7e678b841077f3006877c3b2ead836e912b"
          role: "code"
      unresolved: []
    - id: "logging"
      sources:
        - path: "EasyEngineCore/Diagnostics/AppLog.swift"
          git_blob: "827ef0baa84980d0df634f19d06d944c856a4293"
          role: "code"
        - path: "README.md"
          git_blob: "adbd4f30d3c2f11bb855e6645195493a6c6a34f7"
          role: "doc"
        - path: "docs/engineering/rulebook.md"
          git_blob: "dba86c139b41f2fe59027bab1f0e9982fd8d0e00"
          role: "doc"
      unresolved: []
    - id: "log-export"
      sources:
        - path: "EasyKeyApp/Coordination/AppCoordinator.swift"
          git_blob: "815b5dad186802739e0969eb509af2469570b583"
          role: "code"
        - path: "EasyKeyApp/Coordination/LogExporter.swift"
          git_blob: "d4cb310fd2cb020302eb4ecac9ccb154505493d7"
          role: "code"
        - path: "EasyKeyApp/Coordination/StatusMenuBuilder.swift"
          git_blob: "a377dcfb9ea8265d43b9e2b802c1cc90edc0cb67"
          role: "code"
      unresolved: []
    - id: "status-and-health"
      sources:
        - path: "EasyKeyApp/Coordination/StatusItemController.swift"
          git_blob: "41325adb028f17e1f2fb0a7cb7983c23c93824fe"
          role: "code"
        - path: "EasyKeyApp/Features/Settings/System/SystemHealthCard.swift"
          git_blob: "45184202082f9947ebb6885a1f9e694d0cb2844d"
          role: "code"
        - path: "EasyKeyKit/Keyboard/Diagnostics/KeyboardDiagnosticsRecorder.swift"
          git_blob: "5b06cb65f184556907e6ae44d093dc4fae536505"
          role: "code"
        - path: "EasyKeyKit/Keyboard/KeyboardService.swift"
          git_blob: "3246c7e678b841077f3006877c3b2ead836e912b"
          role: "code"
      unresolved: []
    - id: "correlation"
      sources:
        - path: "EasyEngineCore/Diagnostics/AppLog.swift"
          git_blob: "827ef0baa84980d0df634f19d06d944c856a4293"
          role: "code"
        - path: "EasyKeyApp/Coordination/LogExporter.swift"
          git_blob: "d4cb310fd2cb020302eb4ecac9ccb154505493d7"
          role: "code"
      unresolved: []
    - id: "blind-spots"
      sources:
        - path: "EasyEngineCore/Diagnostics/AppLog.swift"
          git_blob: "827ef0baa84980d0df634f19d06d944c856a4293"
          role: "code"
        - path: "README.md"
          git_blob: "adbd4f30d3c2f11bb855e6645195493a6c6a34f7"
          role: "doc"
        - path: "docs/security/data-handling.md"
          git_blob: "5403a91f4763dbb6e4d1c679f4ec4ff265ac3545"
          role: "doc"
      unresolved: []
---
# Observability

_Last reviewed: 2026-08-13_

EasyKey is a local menu-bar utility with no server components, so observability is entirely on-device. The system emits three kinds of signals — OSLog entries under a single subsystem, an in-memory keyboard-diagnostics ring buffer, and derived health state surfaced in the UI — and by design collects no analytics, telemetry, or crash reports. Everything below is visible only on the machine where the app runs, and there is no alerting infrastructure: every "alert intent" in this document is log-only or on-screen, and nothing ever pages a human.

## Signals

| Signal | Source | Visible in | Owner | Alert intent |
|---|---|---|---|---|
| Latency (keyboard callback) | `KeyboardDiagnosticsRecorder` — median of `callbackDurationNanoseconds` over the last 128 events | Settings → System health card ("X.XX ms") | maintainer | log-only — in-app display; nothing alerts |
| Traffic (event volume and disposition) | `KeyboardService.Diagnostic` records — eventType, disposition, outputCount, bundleIdentifier | in-memory snapshot only; never written to logs | maintainer | log-only — debugging aid, no threshold |
| Errors | `AppLog.error(...)` per category — event-tap install, translation providers, login item, settings, export | unified log + Show Logs export | maintainer | log-only — no paging exists |
| Saturation (CPU / memory / energy) | none instrumented | — | — | not observable — see Blind spots |

The latency signal is the only one with a derived, user-visible value: `SystemHealthCard` appends the median callback latency in milliseconds to its detail line when the service is active. Traffic is recorded per key event — each record carries the event type, a disposition (`passed`, `suppressed`, `bypassed`, `selfPosted`, `disabled`), the number of output events, and the frontmost app's bundle identifier — but the ring buffer is never logged or exported. Errors span real failure modes: event-tap install failures ("CGEvent tap install failed"), translation provider response failures ("DeepL response decoding failed"), login-item configuration failures, settings load/write failures, and log-export failures.

## Logging

All logging goes through `AppLog` (`EasyEngineCore/Diagnostics/AppLog.swift`), which wraps OSLog with the fixed subsystem `one.ifelse.easykey` and nine named categories. Levels are `debug`, `info`, `notice`, and `error`; messages are interpolated with `privacy: .private` for debug/info/notice and `privacy: .public` for errors. The facility's doc comment states the hard rule: "Never log raw keystroke content", mirrored by [rulebook.md](../engineering/rulebook.md) ("Never record raw keyboard input or clipboard payloads in logs or analytics").

| Category | Emitters | What it records |
|---|---|---|
| app | `AppCoordinator` start/stop/restart, clipboard conversions, log export | lifecycle and coordination events |
| engine | none in production code (probe usage in `AppLogTests` only) | declared, not yet emitted |
| keyboard | `KeyboardService`, `KeyboardEventTap` | event-tap install/teardown, permission requests, sleep/wake notices |
| synth | `KeySynthesizer` | key-event synthesis failures |
| smartSwitch | `SmartSwitchController` | per-app language preferences, focus handling failures |
| settings | `SettingsRepository` | settings load/save/import/export/reset outcomes |
| update | `UpdateService` | Sparkle enablement and update checks |
| loginItem | `LoginItemController` | login-item configure results |
| translation | DeepL and Google providers, `TranslationSettingsModel` | provider response failures, credential save/validate/delete results |

Entries are visible in the unified log (Console.app or `log show`); nothing is shipped off-device. [product overview](../product/overview.md) states the product guarantee: "EasyKey collects no analytics or telemetry."

## Log export

Menu bar → **Show Logs** (`StatusMenuBuilder` item `menuShowLogs`) triggers `AppCoordinator` → `LogExporter.exportAndReveal()`. The export (`LogExporter.swift`) reads `OSLogStore(scope: .currentProcessIdentifier)` for the last 60 minutes, filters to the `one.ifelse.easykey` subsystem and the three safe categories `app`, `keyboard`, `settings`, and caps at 2000 entries. Each line is `[timestamp] [category] message`; the file header records subsystem, export time, and lookback seconds. Three credential patterns are redacted to `[REDACTED]` before writing — `sk-...` API keys, `AIzaSy...` Google keys, and `x-api-key: ...` headers. The output goes to the system temporary directory as `EasyKeyLogs/easykey-<yyyyMMdd-HHmmss>.log` with POSIX permissions `0600`, then is revealed in Finder. On failure the app logs "Log export failed: …" through `AppLog.error(.app, ...)` and presents a localized NSAlert ("Couldn't export logs" / "Try again.") unless running under UI tests.

## Status and health

`KeyboardService.Health` is a five-state machine — `stopped`, `requestingPermission`, `active`, `degraded`, `failed` — updated by the service and surfaced in three places: the menu-bar status item (`StatusItemController` renders a colored icon per state), the onboarding `HealthPill`, and the Settings `SystemHealthCard`, which also offers action buttons (grant permission, resume, restart) per state. Lifecycle events move the state and log notices: system sleep tears down the event tap and marks `degraded`; wake refreshes the input source and re-checks Accessibility permission. The diagnostics ring buffer (capacity 128, enabled by default) backs `medianCallbackLatencyNanoseconds`, which returns the middle value of the sorted callback durations — or `nil` when empty — and is what the health card renders as milliseconds.

## Correlation

There is no request ID or trace — there are no requests. Moving from symptom to cause uses category + timestamp on the local machine:

1. Symptom "typing is not transformed" → look at the menu-bar icon or the Settings health card first: `degraded`/`failed` vs `active`, plus whether the service is paused (`keyboardPaused` surfaces a Resume button).
2. Health → log: filter the unified log to the subsystem and the `keyboard`/`app` categories for the incident window:

```bash
log show --predicate 'subsystem == "one.ifelse.easykey"' --last 1h --info --debug
```

3. For a user-supplied report, have the user run Show Logs: the export covers the same subsystem for the last 60 minutes, restricted to `app`/`keyboard`/`settings`, redacted, timestamps per line — the header tells you when it was taken and the lookback used.
4. Latency triage: the in-memory diagnostics snapshot holds per-event disposition and callback duration for the last 128 events; the health card's millisecond figure is its median. A `bypassed`/`suppressed` cluster points at per-app compatibility rules rather than a broken tap.

## Blind spots

- **Crash reporting: none.** The repository has no crash reporter and no symbolication pipeline; crashes are invisible until reproduced locally. [data-handling.md](../security/data-handling.md) and [product overview](../product/overview.md) promise "no analytics or telemetry" — that is a product guarantee and simultaneously the main observability limit: usage, feature adoption, and error rates across the user base are unknown.
- **Saturation is unobserved.** No CPU, memory, or energy instrumentation exists; performance problems surface only as callback-latency medians while the settings window happens to be open.
- **The ring buffer is ephemeral and bounded.** 128 events, in memory only — lost on quit, never persisted, never exported (bundle identifiers of frontmost apps at event time stay local by design).
- **Exports exclude six categories.** Show Logs covers only `app`, `keyboard`, `settings`; engine, synth, smartSwitch, update, loginItem, and translation entries are invisible to exports (still present in the unified log).
- **No remote diagnostics.** Support reproduces issues from exports the user runs manually; there is no device report, no crash upload, no heartbeat.
- **No alert thresholds.** Nothing monitors the logs; the health card is the only "alert" and it exists only when the settings window is open.
