---
id: "accessibility"
title: "Accessibility"
docforge_provenance:
  schema: "2.0"
  doc_id: "accessibility"
  path: "docs/product/accessibility.md"
  generated_at: "2026-08-03T08:43:54Z"
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
        - path: "docs/_archive/DESIGN.md"
          git_blob: "2880ba6314ea9772c70f177af4af181da9177cb3"
          role: "doc"
        - path: "docs/_archive/CONVENTIONS.md"
          git_blob: "878c15dcb2e9f1fd811a7432688b8b20c6b72512"
          role: "doc"
        - path: "EasyKeyApp/Features/Onboarding/OnboardingView.swift"
          git_blob: "6607f26cd0e27f49ac6d0e77492557411063e170"
          role: "code"
        - path: "EasyKeyApp/Features/Settings/Shared/ShortcutRecorder.swift"
          git_blob: "26848c8e7b7745d4bf4955806cbb71fd179dfb43"
          role: "code"
        - path: "EasyKeyApp/Coordination/MenuPopoverView.swift"
          git_blob: "2ef75b671feaa2052671f8b6ad178bfcc673a6d4"
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
        - path: "docs/_archive/DESIGN.md"
          git_blob: "2880ba6314ea9772c70f177af4af181da9177cb3"
          role: "doc"
        - path: "docs/_archive/PROBLEMS.md"
          git_blob: "acb0eac12772c9857d236b931083ae0de175c6fe"
          role: "doc"
      unresolved: []
---
# Accessibility

_Last reviewed: 2026-08-03_

**Target conformance:** The repository declares no formal WCAG conformance level and holds no external certification. The app's stated practice targets WCAG 2.2 Level AA behaviors — semantic labels, keyboard operability, and contrast carried by system colors — and the per-area coverage below is verified by the named method, not by a certification claim.

## Verified behavior by area

| Area | Coverage | Verified by |
|---|---|---|
| Perceivable | System semantic colors and text styles only (no custom fonts or hex colors); opaque content surfaces; honors system Reduce Transparency and Increase Contrast with no app-specific gating | Manual audit of [design system](../architecture/README.md) + automated audit |
| Operable | All controls are standard AppKit/SwiftUI controls (keyboard-navigable by default); primary/secondary buttons carry `.defaultAction`/`.cancelAction` keyboard shortcuts; the shortcut recorder exposes labeled record/clear actions; onboarding and settings are completable by keyboard; all global hotkeys are configurable in Settings | Manual audit + automated audit |
| Understandable | Every user-facing string resolves through the localization store, so labels render in the chosen interface language; the popover status is one composed label ("state + app name + Smart Switch status") instead of fragmented subviews | Manual audit + automated audit |
| Robust | Stable accessibility identifiers are an enforced UI-test contract (onboarding steps, settings shell, translation settings); semantic roles and states come from native controls, not custom drawing | Automated audit + UI tests consuming the identifiers |

Key implementations: onboarding uses explicit `.accessibilityLabel` plus stable identifiers such as `"OnboardingPrimary"` and `"Grant Accessibility Access"` (`EasyKeyApp/Features/Onboarding/OnboardingView.swift`); the shortcut recorder composes localized labels for record and clear (`EasyKeyApp/Features/Settings/Shared/ShortcutRecorder.swift`); the menu popover combines its status children into one accessible element (`EasyKeyApp/Coordination/MenuPopoverView.swift`). The design system mandates standard controls, semantic colors, system text styles, and no custom materials or decorative motion — so Reduce Transparency, Reduce Motion, and Increase Contrast are honored by construction ([DESIGN.md §11](../architecture/README.md), [CONVENTIONS.md](../engineering/conventions.md)).

## Verification method

Automated: `EasyKeyUITests/SettingsAccessibilityTests.swift` runs XCUITest's `performAccessibilityAudit` against eight settings sections (Typing, Encoding, Clipboard, Macros, Smart Switch, Behavior, System, About). The audit's acceptable findings are: unnamed containers, unnamed touch-bar elements, popup-button action hints, and contrast findings — everything else fails the test. Manual: design-system review against the stated HIG practices above.

## Known gaps

- **No declared conformance level or third-party audit.** WCAG compliance is claimed neither here nor anywhere in the repository.
- **Automated contrast checks are not enforced.** The audit test explicitly accepts `.contrast` findings; contrast currently rests on system semantic colors and was not programmatically verified.
- **Translation settings and the clipboard/translation popovers are not in the automated per-section audit.** The audit covers eight settings sections; the translation settings section and the floating panels/popovers have identifiers and labels but no automated audit run.
- **No recorded assistive-technology walkthrough.** There is no logged VoiceOver (or other AT) end-to-end test session; the stable identifiers exist so such tests can be written.
- **Typing depends on the Accessibility permission.** Without it the app cannot transform keystrokes; the degraded experience is plain unmarked text, and permission can be revoked at any time.
- **No Dynamic Type scaling on macOS.** macOS does not scale type the way iOS does; the app follows system text styles, which track system preferences (see [DESIGN.md §4](../architecture/README.md)).
