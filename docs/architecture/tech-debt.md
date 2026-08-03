---
id: "tech_debt"
title: "Tech Debt"
docforge_provenance:
  schema: "2.0"
  doc_id: "tech_debt"
  path: "docs/architecture/tech-debt.md"
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
    - id: "technical-debt"
      sources:
        - path: "README.md"
          role: "doc"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
      unresolved: []
    - id: "register"
      sources:
        - path: "EasyKeyLoginHelper/main.swift"
          role: "code"
          git_blob: "f0f724c4c8a6644555990bff4e08325f80625a66"
        - path: "Makefile"
          role: "config"
          git_blob: "b8fa0059c061eef05cb083ae69e8e7d46336aa64"
        - path: "README.md"
          role: "doc"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
        - path: "EasyEngineCore/Settings/SettingsRepository.swift"
          role: "code"
          git_blob: "f718fcf9ea3a84f0aa770650c15c8c059e450a19"
        - path: "EasyKeyApp/Features/Settings/Shared/PasteableSecureField.swift"
          role: "code"
          git_blob: "1b40356da8975741f6088f4ab9ea12f976c9e982"
      unresolved: []
    - id: "notes"
      sources:
        - path: "README.md"
          role: "doc"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
        - path: "EasyKeyApp/Features/Clipboard/ClipboardPersistence.swift"
          role: "code"
          git_blob: "2f2f6e1c7c03071c95010c565309b55a06b15c34"
      unresolved: []
---
# Technical debt

_Last reviewed: 2026-08-03_

Known shortcuts and deferred work, recorded honestly. Debt hidden reads as evasion under scrutiny; debt named with a remediation path reads as competence. Describe the shortcut and its cost in behavioural terms — do not paste the offending code.

## Register

_Ordered by the cost each item imposes if left untouched — not alphabetically, not by discovery date._

| Item | Shortcut taken | Why | Evidence | Cost it imposes | Remediation | Tracking |
|---|---|---|---|---|---|---|
| Login-helper team-ID stub | The helper validates its code-signing team identifier against a hardcoded placeholder `"TEAMID12345"` instead of a build-provided value | Inadvertent — the check was written before real signing existed, so the placeholder silently passes for ad-hoc-signed builds | `EasyKeyLoginHelper/main.swift` | The moment real Developer ID signing lands, every launch of the helper self-terminates (team ID non-empty and unequal), breaking launch-at-login with a silent failure | Inject the team identifier via a build setting (same pattern as `SPARKLE_PUBLIC_ED_KEY`) or gate validation on a signed-build flag | none — pay down before enabling notarization |
| CI interaction tests never block merge | A whole shard of click-then-verify UI tests (`ui-known-broken-on-hosted-runner`) runs with `continue-on-error` because hosted runners cannot reliably make AppKit windows key | Deliberate-and-prudent — kept running for coverage and visibility rather than deleted, documented in the CI matrix and the Makefile shard note | `Makefile` (shard comments), UI test suites under `EasyKeyUITests/` | Real end-to-end interaction coverage is advisory only: regressions in onboarding/settings click paths can reach users unreviewed; the shipped UI-test story overstates its gate | Run those tests on a self-hosted runner with a logged-in GUI session, then remove `continue-on-error` and the skip lists | none |
| Release builds not Developer-ID notarized | The release pipeline builds unsigned local DMGs (signing/notarization steps commented out pending an Apple certificate) | Deliberate-and-prudent — the certificate does not exist yet; the build path and tag/version validation are already wired | [README.md](../README.md) (install section: "ad-hoc signed, but not Developer ID notarized", Control-click-to-open instructions) | Every new user hits Gatekeeper friction (right-click/Open-Anyway), and macOS may warn more aggressively over time; also blocks the helper team-ID path above | Obtain a Developer ID certificate, re-enable the signing + notarization + staple steps, verify with `Scripts/verify-*.sh` | none |
| Debounced settings write window | `SettingsRepository.scheduleSave` cancels the pending write and re-schedules 300 ms later; a hard kill inside the window loses the last change | Inadvertent — introduced for write coalescing; the loss window is bounded but real | `EasyEngineCore/Settings/SettingsRepository.swift` | Users can lose the most recent settings change (e.g. a language switch) on a crash/power cut; the termination path mitigates but cannot cover hard kills | Persist critical deltas synchronously or shorten/replay the debounce; crash-safe write ordering (write-ahead) | partially remediated: `applicationShouldTerminate` awaits `saveNow()` |
| Bespoke `NSSecureTextField` wrapper | SwiftUI `SecureField` paste handling lags in accessory apps, so a custom `NSViewRepresentable` overrides `performKeyEquivalent` for Cmd+V/C/X/A | Deliberate-and-prudent — a documented workaround with an explicit reason in the file header | `EasyKeyApp/Features/Settings/Shared/PasteableSecureField.swift` | Custom AppKit code to maintain (coordinator, binding sync, accessibility plumbing) with no covering tests; a SwiftUI change could obsolete it | Re-evaluate on each SDK bump; add a UI test covering paste-into-field if the wrapper stays | none |
| Single-file settings JSON with migrations | Settings, macros, and smart-switch preferences are three separate JSON files under Application Support, each with its own schema-version story | Deliberate-and-prudent — schema versioning + `SettingsMigration` exists; a unified store is not warranted yet | `EasyEngineCore/Settings/SettingsRepository.swift` (migrate/decode chain) | Migration bugs need per-format test coverage; adding fields touches three code paths | Keep as-is until a fourth persisted domain appears, then evaluate one document registry | none |

## Notes

Debt that is deliberate and acceptable for now, distinguished from debt that should be paid down soon:

- **Acceptable for now:** the `PasteableSecureField` workaround (SDK-dependent, low blast radius) and the separate JSON stores (each is small and versioned).
- **Pay down soon:** the login-helper team-ID stub — it is a latent self-termination landmine for the signing work that is already queued — and the notarization gap, whose user-facing cost (Gatekeeper friction) grows with every release.
- **Not debt:** the Spotlight typing workaround and the clipboard ignore-list caveat ("best effort, not a security boundary") are platform/user-visible limitations, tracked in [PROBLEMS.md](../reference/limitations.md) and [limitations](../reference/limitations.md), not here.

_Distinct from [constraints.md](constraints.md) (hard limits by design) and [limitations](../reference/limitations.md) (feature gaps a user hits). Cross-link; do not duplicate._
