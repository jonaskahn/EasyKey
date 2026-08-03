---
id: "localization"
title: "Localization"
docforge_provenance:
  schema: "2.0"
  doc_id: "localization"
  path: "docs/product/localization.md"
  generated_at: "2026-08-03T08:43:54Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "reference"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "supported-locales"
      sources:
        - path: "EasyKeyApp/Localizable.xcstrings"
          git_blob: "1ac8944c5549c991cf345e400116c318cc3e7e07"
          role: "config"
        - path: "EasyKeyApp/Localization/AppLanguage.swift"
          git_blob: "1051771cdc25ef48d1f98e213e03a7f651f4196e"
          role: "code"
      unresolved: []
    - id: "known-limits"
      sources:
        - path: "EasyKeyApp/Localization/LocalizationStore.swift"
          git_blob: "7e659d361a05aca33801c79685d51be20fb113c0"
          role: "code"
        - path: "EasyEngineCore/Translation/SupportedLanguages.swift"
          git_blob: "0091dea40cb4db68095afd1afe3127b319402260"
          role: "code"
      unresolved: []
---
# Localization

_Last reviewed: 2026-08-03_

**Resource format:** String Catalog — `EasyKeyApp/Localizable.xcstrings` (source language English, schema version 1.0). It compiles into per-language `Localizable.strings` bundles (`en.lproj`, `vi.lproj`), which the runtime loads through `LocalizationStore` (`EasyKeyApp/Localization/LocalizationStore.swift`); adding a locale means adding the localization in the catalog and a matching case in `AppLanguage` (`EasyKeyApp/Localization/AppLanguage.swift`).

## Supported locales

| Locale | Coverage | Fallback |
|---|---|---|
| `en` (English) | Full — source language of the catalog; all 418 keys | None (source) |
| `vi` (Vietnamese) | Full — every one of the 418 keys carries a Vietnamese translation | English |

Coverage was verified by enumerating the catalog: 418 of 418 keys have both `en` and `vi` entries (0 keys missing either locale). The interface language can be `system`, `en`, or `vi`, persisted under the UserDefaults key `interfaceLanguage`; `system` resolves to Vietnamese when the user's preferred language is Vietnamese, otherwise English. When a specific translation is missing at runtime, lookup falls back to English, then the compiled `.lproj` bundle, then `String(localized:)` — so a missing `vi` string degrades to English, never to a raw key.

## Known limits

- Only two interface locales are shipped; nothing else is claimed as supported.
- The translation **language pickers** are a separate surface: the 20 curated translation languages in `SupportedLanguages` are provider-facing label entries (e.g. `fr`, `zh-Hans`) rendered through the user's system locale, not shipped translations of the interface.
- Catalog presence was verified programmatically (key enumeration); rendered-string quality in context (truncation, layout in Vietnamese) was not machine-verified.
