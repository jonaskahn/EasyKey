---
id: "accessibility"
title: "Accessibility"
description: "Supported behavior, resources/semantics, fallback, verification, known limits"
docforge_provenance:
  schema: "2.0"
  doc_id: "accessibility"
  path: "docs/product/accessibility.md"
  generated_at: "2026-08-13T11:09:28Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "deep-dive"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "verified-behavior-by-area"
      sources:
        - path: "docs/architecture/design.md"
          git_blob: "c10b8f8f25b79d2d6401c886178f2be8fa6b0e34"
          git_blob_normalized: "c10b8f8f25b79d2d6401c886178f2be8fa6b0e34"
          role: "doc"
        - path: "docs/engineering/rulebook.md"
          git_blob: "dba86c139b41f2fe59027bab1f0e9982fd8d0e00"
          git_blob_normalized: "dba86c139b41f2fe59027bab1f0e9982fd8d0e00"
          role: "doc"
        - path: "EasyKeyApp/Features/Onboarding/OnboardingView.swift"
          git_blob: "6607f26cd0e27f49ac6d0e77492557411063e170"
          git_blob_normalized: "6607f26cd0e27f49ac6d0e77492557411063e170"
          role: "code"
        - path: "EasyKeyApp/Features/Settings/Shared/ShortcutRecorder.swift"
          git_blob: "26848c8e7b7745d4bf4955806cbb71fd179dfb43"
          git_blob_normalized: "26848c8e7b7745d4bf4955806cbb71fd179dfb43"
          role: "code"
        - path: "EasyKeyApp/Coordination/MenuPopoverView.swift"
          git_blob: "2ef75b671feaa2052671f8b6ad178bfcc673a6d4"
          git_blob_normalized: "2ef75b671feaa2052671f8b6ad178bfcc673a6d4"
          role: "code"
      unresolved: []
    - id: "verification-method"
      sources:
        - path: "EasyKeyUITests/SettingsAccessibilityTests.swift"
          git_blob: "976a883c7b3279992b082f5563c5e123e757bce9"
          role: "test"
      unresolved: []
    - id: "known-gaps"
      sources:
        - path: "EasyKeyUITests/SettingsAccessibilityTests.swift"
          git_blob: "976a883c7b3279992b082f5563c5e123e757bce9"
          role: "test"
        - path: "docs/architecture/design.md"
          git_blob: "c10b8f8f25b79d2d6401c886178f2be8fa6b0e34"
          git_blob_normalized: "c10b8f8f25b79d2d6401c886178f2be8fa6b0e34"
          role: "doc"
        - path: "docs/reference/limitations.md"
          git_blob: "8e3e23bf6b098a52db5efcd4e4328dfea588b6e1"
          git_blob_normalized: "8e3e23bf6b098a52db5efcd4e4328dfea588b6e1"
          role: "doc"
      unresolved: []
---
# Accessibility

_Last reviewed: 2026-08-13_

**Target conformance:** The repository declares no formal WCAG conformance level and holds no external certification. The app's stated practice targets WCAG 2.2 Level AA behaviors — semantic labels, keyboard operability, and contrast carried by system colors — and the per-area coverage below is verified by the named method, not by a certification claim.

## Verified behavior by area

| Area | Coverage | Verified by |
|---|---|---|
| Perceivable | System semantic colors and text styles only (no custom fonts or hex colors); opaque content surfaces; honors system Reduce Transparency and Increase Contrast with no app-specific gating | Manual audit of [design system](../architecture/README.md) + automated audit |
| Operable | All controls are standard AppKit/SwiftUI controls (keyboard-navigable by default); primary/secondary buttons carry `.defaultAction`/`.cancelAction` keyboard shortcuts; the shortcut recorder exposes labeled record/clear actions; onboarding and settings are completable by keyboard; all global hotkeys are configurable in Settings | Manual audit + automated audit |
| Understandable | Every user-facing string resolves through the localization store, so labels render in the chosen interface language; the popover status is one composed label ("state + app name + Smart Switch status") instead of fragmented subviews | Manual audit + automated audit |
| Robust | Stable accessibility identifiers are an enforced UI-test contract (onboarding steps, settings shell, translation settings); semantic roles and states come from native controls, not custom drawing | Automated audit + UI tests consuming the identifiers |

Key implementations: onboarding uses explicit `.accessibilityLabel` plus stable identifiers such as `"OnboardingPrimary"` and `"Grant Accessibility Access"` (`EasyKeyApp/Features/Onboarding/OnboardingView.swift`); the shortcut recorder composes localized labels for record and clear (`EasyKeyApp/Features/Settings/Shared/ShortcutRecorder.swift`); the menu popover combines its status children into one accessible element (`EasyKeyApp/Coordination/MenuPopoverView.swift`). The project rules mandate standard controls, semantic colors, system text styles, and accessibility labels, with controls working under keyboard navigation, VoiceOver, increased text size, and reduced motion ([rulebook](../engineering/rulebook.md)); materials are native-only with no custom material layers ([design.md §7](../architecture/design.md)) — so Reduce Transparency, Reduce Motion, and Increase Contrast are honored by construction ([design.md §11](../architecture/design.md)).

## Verification method

Automated: `EasyKeyUITests/SettingsAccessibilityTests.swift` runs XCUITest's `performAccessibilityAudit` against eight settings sections (Typing, Encoding, Clipboard, Macros, Smart Switch, Behavior, System, About). The audit's acceptable findings are: unnamed containers, unnamed touch-bar elements, popup-button action hints, and contrast findings — everything else fails the test. Manual: design-system review against the stated HIG practices above.

## Known gaps

- **No declared conformance level or third-party audit.** WCAG compliance is claimed neither here nor anywhere in the repository.
- **Automated contrast checks are not enforced.** The audit test explicitly accepts `.contrast` findings; contrast currently rests on system semantic colors and was not programmatically verified.
- **Translation settings and the clipboard/translation popovers are not in the automated per-section audit.** The audit covers eight settings sections; the translation settings section and the floating panels/popovers have identifiers and labels but no automated audit run.
- **No recorded assistive-technology walkthrough.** There is no logged VoiceOver (or other AT) end-to-end test session; the stable identifiers exist so such tests can be written.
- **Typing depends on the Accessibility permission.** Without it the app cannot transform keystrokes; the degraded experience is plain unmarked text, and permission can be revoked at any time.
- **No Dynamic Type scaling on macOS.** macOS does not scale type the way iOS does; the app follows system text styles, which track system preferences (see [design.md §4](../architecture/design.md)).
