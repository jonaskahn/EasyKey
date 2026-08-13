---
id: "localization"
title: "Localization"
description: "Supported behavior, resources/semantics, fallback, verification, known limits"
docforge_provenance:
  schema: "2.0"
  doc_id: "localization"
  path: "docs/product/localization.md"
  generated_at: "2026-08-13T11:09:28Z"
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
          git_blob: "d6fabb5d84a934d490a2bc9b67f643caf6e3d44f"
          git_blob_normalized: "d6fabb5d84a934d490a2bc9b67f643caf6e3d44f"
          role: "config"
        - path: "EasyKeyApp/Localization/AppLanguage.swift"
          git_blob: "2add0345da3e50e736e3f18c12f4db48f21b6793"
          git_blob_normalized: "2add0345da3e50e736e3f18c12f4db48f21b6793"
          role: "code"
      unresolved: []
    - id: "known-limits"
      sources:
        - path: "EasyKeyApp/Localization/LocalizationStore.swift"
          git_blob: "e5f835840227d9850828061a66dd34534de6dafb"
          git_blob_normalized: "e5f835840227d9850828061a66dd34534de6dafb"
          role: "code"
        - path: "EasyEngineCore/Translation/SupportedLanguages.swift"
          git_blob: "0091dea40cb4db68095afd1afe3127b319402260"
          git_blob_normalized: "0091dea40cb4db68095afd1afe3127b319402260"
          role: "code"
      unresolved: []
---
# Localization

_Last reviewed: 2026-08-13_

**Resource format:** String Catalog — `EasyKeyApp/Localizable.xcstrings` (source language English, schema version 1.0). It compiles into per-language `Localizable.strings` bundles (`en.lproj`, `vi.lproj`), which the runtime loads through `LocalizationStore` (`EasyKeyApp/Localization/LocalizationStore.swift`); adding a locale means adding the localization in the catalog and a matching case in `AppLanguage` (`EasyKeyApp/Localization/AppLanguage.swift`).

## Supported locales

| Locale | Coverage | Fallback |
|---|---|---|
| `en` (English) | Full — source language of the catalog; all 430 keys | None (source) |
| `vi` (Vietnamese) | Full — every one of the 430 keys carries a Vietnamese translation | English |

Coverage was verified by enumerating the catalog: 430 of 430 keys have both `en` and `vi` entries (0 keys missing either locale). The interface language can be `system`, `en`, or `vi`, persisted under the UserDefaults key `interfaceLanguage`; `system` resolves to Vietnamese when the user's preferred language is Vietnamese, otherwise English. When a specific translation is missing at runtime, lookup falls back to English, then the compiled `.lproj` bundle, then `String(localized:)` — so a missing `vi` string degrades to English, never to a raw key.

## Known limits

- Only two interface locales are shipped; nothing else is claimed as supported.
- The translation **language pickers** are a separate surface: the 20 curated translation languages in `SupportedLanguages` are provider-facing label entries (e.g. `fr`, `zh-Hans`) rendered through the user's system locale, not shipped translations of the interface.
- Catalog presence was verified programmatically (key enumeration); rendered-string quality in context (truncation, layout in Vietnamese) was not machine-verified.
