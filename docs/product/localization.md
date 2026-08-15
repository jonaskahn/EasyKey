# Localization

_Last reviewed: 2026-08-15_

**Resource format:** String Catalog — `EasyKeyApp/Localizable.xcstrings` (source language English, schema version 1.0). It compiles into per-language `Localizable.strings` bundles (`en.lproj`, `vi.lproj`), which the runtime loads through `LocalizationStore` (`EasyKeyApp/Localization/LocalizationStore.swift`); adding a locale means adding the localization in the catalog and a matching case in `AppLanguage` (`EasyKeyApp/Localization/AppLanguage.swift`).

## Supported locales

| Locale | Coverage | Fallback |
|---|---|---|
| `en` (English) | Full — source language of the catalog; all 443 keys | None (source) |
| `vi` (Vietnamese) | Full — every one of the 443 keys carries a Vietnamese translation | English |

Coverage was verified by enumerating the catalog: 443 of 443 keys have both `en` and `vi` entries (0 keys missing either locale). The interface language can be `system`, `en`, or `vi`, persisted under the UserDefaults key `interfaceLanguage`; `system` resolves to Vietnamese when the user's preferred language is Vietnamese, otherwise English. When a specific translation is missing at runtime, lookup falls back to English, then the compiled `.lproj` bundle, then `String(localized:)` — so a missing `vi` string degrades to English, never to a raw key.

## Known limits

- Only two interface locales are shipped; nothing else is claimed as supported.
- The translation **language pickers** are a separate surface: the 20 curated translation languages in `SupportedLanguages` are provider-facing label entries (e.g. `fr`, `zh-Hans`) rendered through the user's system locale, not shipped translations of the interface.
- Catalog presence was verified programmatically (key enumeration); rendered-string quality in context (truncation, layout in Vietnamese) was not machine-verified.
