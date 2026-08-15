# Accessibility

_Last reviewed: 2026-08-15_

**Target conformance:** The repository declares no formal WCAG conformance level and holds no external certification. The app's stated practice targets WCAG 2.2 Level AA behaviors — semantic labels, keyboard operability, and contrast carried by system colors — and the per-area coverage below is verified by the named method, not by a certification claim.

## Verified behavior by area

| Area | Coverage | Verified by |
|---|---|---|
| Perceivable | System semantic colors and text styles only (no custom fonts or hex colors); opaque content surfaces; honors system Reduce Transparency and Increase Contrast with no app-specific gating | Manual audit of [design system](../architecture/README.md) + automated audit |
| Operable | All controls are standard AppKit/SwiftUI controls (keyboard-navigable by default); primary/secondary buttons carry `.defaultAction`/`.cancelAction` keyboard shortcuts; the shortcut recorder exposes labeled record/clear actions; onboarding and settings are completable by keyboard; all global hotkeys are configurable in Settings | Manual audit + automated audit |
| Understandable | Every user-facing string resolves through the localization store, so labels render in the chosen interface language; the popover status is one composed label ("state + app name + Smart Switch status") instead of fragmented subviews | Manual audit + automated audit |
| Robust | Stable accessibility identifiers are an enforced UI-test contract (onboarding steps, settings shell, translation settings); semantic roles and states come from native controls, not custom drawing | Automated audit + UI tests consuming the identifiers |

Key implementations: onboarding uses explicit `.accessibilityLabel` plus stable identifiers such as `"OnboardingPrimary"` and `"Grant Accessibility Access"` (`EasyKeyApp/Features/Onboarding/OnboardingView.swift`); the shortcut recorder composes localized labels for record and clear (`EasyKeyApp/Features/Settings/Shared/ShortcutRecorder.swift`); the menu popover combines its status children into one accessible element (`EasyKeyApp/Coordination/MenuPopoverView.swift`). The project rules mandate standard controls, semantic colors, system text styles, and accessibility labels, with controls working under keyboard navigation, VoiceOver, increased text size, and reduced motion (the engineering rulebook, notes/rulebook.md); materials are native-only with no custom material layers (the design notes, notes/design.md) — so Reduce Transparency, Reduce Motion, and Increase Contrast are honored by construction (the design notes).

## Verification method

Automated: `EasyKeyUITests/SettingsAccessibilityTests.swift` runs XCUITest's `performAccessibilityAudit` against eight settings sections (Typing, Encoding, Clipboard, Macros, Smart Switch, Behavior, System, About). The audit's acceptable findings are: unnamed containers, unnamed touch-bar elements, popup-button action hints, and contrast findings — everything else fails the test. Manual: design-system review against the stated HIG practices above.

## Known gaps

- **No declared conformance level or third-party audit.** WCAG compliance is claimed neither here nor anywhere in the repository.
- **Automated contrast checks are not enforced.** The audit test explicitly accepts `.contrast` findings; contrast currently rests on system semantic colors and was not programmatically verified.
- **Translation settings and the clipboard/translation popovers are not in the automated per-section audit.** The audit covers eight settings sections; the translation settings section and the floating panels/popovers have identifiers and labels but no automated audit run.
- **No recorded assistive-technology walkthrough.** There is no logged VoiceOver (or other AT) end-to-end test session; the stable identifiers exist so such tests can be written.
- **Typing depends on the Accessibility permission.** Without it the app cannot transform keystrokes; the degraded experience is plain unmarked text, and permission can be revoked at any time.
- **No Dynamic Type scaling on macOS.** macOS does not scale type the way iOS does; the app follows system text styles, which track system preferences (see the design notes, notes/design.md).
