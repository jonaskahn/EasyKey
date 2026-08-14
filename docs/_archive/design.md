---
id: "existing-design"
title: "Design Notes"
docforge_provenance:
  schema: "2.0"
  doc_id: "existing-design"
  path: "docs/_archive/design.md"
  generated_at: "2026-08-03T10:28:33+00:00"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "spine"
  target_depth: "reference"
  graph:
    provider: "codegraph"
    flow: "none"
  sections: []
---
|---|---|
| Primary text | `.primary` / `label` | headings, body |
| Secondary text | `.secondary` / `secondaryLabel` | captions, subtitles |
| Accent | `.tint` / `Color.accentColor` | selected state, primary buttons, drop-target border |
| Surface fill | `.quaternary` | inset text fields, shortcut chips |
| Active state | `.green` | keyboard health = active |
| Paused state | `.orange` | keyboard paused |
| Error/degraded state | `.red` | keyboard health = failed/degraded |

State-color mapping lives in `MenuPopoverView.stateColor`/`stateSymbol`
(`EasyKeyApp/Coordination/MenuPopoverView.swift:167-179`):

- Paused → `pause.circle.fill`, `.orange`
- Active → `checkmark.circle.fill`, `.green`
- Otherwise (failed/degraded) → `exclamationmark.triangle.fill`, `.red`

The same three-state palette drives `SystemHealthCard`.

## 4. Typography

SF Pro via macOS system text styles — no custom fonts, no Dynamic Type
(macOS does not scale type the way iOS does). Styles in use:

- `.largeTitle` — onboarding page titles
- `.title2` — popover status symbol/title, health-card title, macro-editor title
- `.headline` — card/section titles, popover status title
- `.subheadline` / `.body` — form content, descriptions (`.body.monospaced()`
  for encoding preview fields)
- `.callout` — health pill, macro list rows
- `.footnote` / `.caption` — hints, secondary metadata
- `.caption.monospaced()` — app-name/status line in the popover, version
  strings in update dialogs

The one exception to the semantic-style rule is a fixed `.system(size: 32)`
for the large glyphs in the update dialogs (`UpdateViews.swift:17,82,120`) and
the onboarding icon (`OnboardingView.swift:71`).

## 5. Spacing & layout

8pt base grid, 4pt for tight/inline spacing (icon-to-label, compact rows).
Structure:

- **Settings window**: `NavigationSplitView` — sidebar column fixed at 192pt
  (`.frame(width: 192)` + `.navigationSplitViewColumnWidth(192)`), detail column
  fills remaining width. Window width is locked at 700; height ranges 440–520
  (`contentMinSize 700×440`, `contentMaxSize 700×520`, `ContentView` `minWidth 700,
  minHeight 440`) — `SettingsWindowPresenter.swift:34-35`, `ContentView.swift:24`.
- **Menu popover**: fixed-width `NSPopover`, 380pt (`MenuPopoverView.swift:131`),
  `VStack` content (no `Form`) with 16pt outer padding; picker rows use 12pt
  horizontal / 8pt vertical padding.
- **Onboarding**: full-window paged flow, 16pt inter-section spacing.

## 6. Shape & corner radius

Two-step scale, defined in `EasyKeyApp/Features/Shared/DesignScale.swift`:

- `DesignScale.radiusSM = 6` — inset controls: text editors, shortcut
  recorder chips, macro expansion fields, drop-target outline.
- `DesignScale.radiusMD = 8` — cards and icons: popover status card, system
  health card, app-icon frames (About, onboarding).

**Concentricity**: when a token-radius shape sits inside a system container
(sidebar row, toolbar, window corner), its radius should stay smaller than
the container's effective corner radius minus the container's padding, so
corners nest rather than collide. On macOS 26 the settings window's own
corner radius is toolbar-dependent (see §7) and larger than either token —
no app code needs to match it explicitly.

## 7. Elevation, depth & materials

**Materials policy: native-only.** No `.ultraThinMaterial`, no
`NSVisualEffectView`, anywhere in the content layer. Glass and vibrancy exist
only where the OS puts them natively:

- `NSPopover` — system-drawn chrome, vibrant/glass on macOS 26 automatically.
- Settings `NSWindow` — `NSHostingController` is set as `contentViewController`
  so SwiftUI installs and owns the window toolbar. The toolbar content is a
  single `.toolbar { ToolbarItem(placement: .primaryAction) }` sidebar-toggle
  button (`systemImage: "sidebar.left"`, id `SettingsSidebarToggle`) in
  `SettingsShell.swift:44-55`; the sidebar suppresses the system toggle with
  `.toolbar(removing: .sidebarToggle)`. The section title is **not** a toolbar
  item — it comes from `.navigationTitle(...)` on the detail column
  (`SettingsShell.swift:41`). The presenter styles rendering via
  `titlebarAppearsTransparent = true` + `toolbarStyle = .unified` but does
  **not** assign `window.toolbar` manually (and strips any injected
  `splitViewSeparator` item, `SettingsWindowPresenter.swift:53-61`). The
  presence of a SwiftUI toolbar plus these two window flags unlocks the Tahoe
  unified glass titlebar and floating sidebar on 26; on 14/15 it renders
  standard titlebar/sidebar styling. `List(.sidebar)` in `SettingsShell.swift`
  makes the sidebar float with glass on 26.

**Do not** reintroduce a manual glass/material layer in content views (cards,
forms, popovers' inner content) — that duplicates what the navigation chrome
already provides and risks stacking glass on glass, which reads muddy and
fights the OS's own compositing.

## 8. Components

| Component | Token/API | Notes |
|---|---|---|
| Primary button | `.buttonStyle(.borderedProminent)` | default action, `.keyboardShortcut(.defaultAction)` |
| Secondary button | `.buttonStyle(.bordered)` | cancel/dismiss, `.keyboardShortcut(.cancelAction)` |
| Sidebar | `NavigationSplitView` + `List(SettingsSection.allCases).listStyle(.sidebar)`, fixed 192pt | rows use explicit `.tag(section)` because `SettingsSection.ID` is `String` while selection stores `SettingsSection`; floating glass on 26 |
| Toolbar | SwiftUI-managed (installed by `NSHostingController`); one `ToolbarItem(.primaryAction)` sidebar-toggle button; AppKit `toolbarStyle = .unified` + `titlebarAppearsTransparent = true` style rendering | section title comes from `.navigationTitle`, not the toolbar |
| Popover | `NSPopover`, 380pt wide | system chrome, no custom material |
| Sheet | `MacroEditorSheet` | standard `.sheet` presentation |
| Status card | `RoundedRectangle(cornerRadius: DesignScale.radiusMD)` + `stateColor.opacity(0.08)` fill | intentional tinted fill, not a material |
| Health card | `SystemHealthCard`, same radius/opacity pattern as status card | |
| Inset field | `.background(.quaternary, in: RoundedRectangle(cornerRadius: DesignScale.radiusSM))` | text editors, shortcut chips |
| Picker | popover uses `BorderlessPickerMenu` (custom borderless `Menu`); settings use stock `Picker` / `InterfaceLanguageMenu` (borderless menu variant) | |

States (hover/pressed/disabled) are entirely system-provided by the stock
control styles above — no custom state handling in app code.

## 9. Iconography

SF Symbols, no custom icon assets except the app icon itself. Section
symbols (`SettingsSection.symbol`, `SettingsSection.swift:13-23`):

| Section | Symbol |
|---|---|
| Typing | `keyboard` |
| Encoding | `character.book.closed` |
| Macros | `text.badge.plus` |
| Smart Switch | `arrow.triangle.2.circlepath` |
| Behavior | `slider.horizontal.3` |
| System | `desktopcomputer` |
| About | `info.circle` |

Popover status uses `checkmark.circle.fill` / `pause.circle.fill` /
`exclamationmark.triangle.fill` (§3). All symbols render at default
(monochrome) mode — no hierarchical/palette/multicolor rendering, no symbol
animation (no Draw/Bounce/Pulse effects) anywhere in the app.

## 10. Motion & animation

Functional only — no decorative motion. The one notable transition is the
popover-to-settings-window handoff (`SettingsWindowPresenter.present`),
which is an instant window activation, not an animated transform. Onboarding
page changes and section switches use default SwiftUI/AppKit transitions;
no custom `Animation` values are defined in the codebase.

## 11. Accessibility

- Honor system Reduce Transparency / Reduce Motion / Increase Contrast
  automatically — since the app introduces no custom materials or motion,
  there is nothing app-specific to gate. The content layer is opaque by
  default, which sidesteps macOS Tahoe's own Reduce Transparency rendering
  bug (fixed in 26.3) without any special-casing.
- Existing accessibility identifiers (UI-test contract — must not change):
  - Settings shell (`SettingsShell.swift:32,37,42,53`): `"SettingsSidebar"`,
    `"SettingsDetail"`, `"SettingsSidebarToggle"`, and per-row
    `"SettingsSection-<rawValue>"` (e.g. `SettingsSection-typing`).
  - `"InterfaceLanguagePicker"`.
  - Onboarding: `onboardingTitleIdentifier` (dynamic per page:
    `"Welcome"`, `"Accessibility"`, `"Typing method"`, `"Ready"`), `"Back"`,
    `"OnboardingPrimary"`, `"Grant Accessibility Access"`.
- Popover status uses `.accessibilityElement(children: .combine)` with a
  composed `.accessibilityLabel` describing state, app name, and Smart
  Switch status together, rather than exposing each subview separately.

## 12. Do's & Don'ts

**Do:**
- Reserve glass/vibrancy for navigation chrome (sidebar, titlebar, popover)
  — let the OS provide it, don't build it.
- Use system semantic colors (`.primary`, `.secondary`, `.tint`,
  `.quaternary`) exclusively; never introduce hex or custom `Color` assets.
- Use `DesignScale.radiusSM`/`radiusMD` for any new rounded shape instead of
  a literal.
- Keep content-layer backgrounds opaque; reserve translucency for chrome.
- Capitalization context: sentence-start capitalization is set by sentence terminators (`.`, `!`, `?`, `\n`) and cleared when a character is typed, when backspace empties the composition, or when arrow keys/resets move focus away.

**Don't:**
- Don't add `.ultraThinMaterial`, `NSVisualEffectView`, `.glassEffect()`, or
  `GlassEffectContainer` to content views.
- Don't stack glass on glass (e.g., a translucent card inside an already
  glass sidebar).
- Don't hard-code control heights or corner radii — use the token scale.
- Don't tint everything — accent color marks selection/primary action only,
  not decoration.
