---
id: "glossary"
title: "Glossary"
description: "Repository terms, precise definitions, owning document links."
docforge_provenance:
  schema: "2.0"
  doc_id: "glossary"
  path: "docs/reference/glossary.md"
  generated_at: "2026-08-13T11:10:54Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "reference"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "glossary"
      sources:
        - path: "docs/flows/telex.md"
          role: "doc"
          git_blob: "2e5946ef5f8d1ae23d270399677595fef840f8f0"
          git_blob_normalized: "2e5946ef5f8d1ae23d270399677595fef840f8f0"
        - path: "EasyEngineCore/Engine/EncodingTable.swift"
          role: "code"
          git_blob: "5b5b5b8b5a8f1e2d400d096e819deafb07e16588"
          git_blob_normalized: "5b5b5b8b5a8f1e2d400d096e819deafb07e16588"
        - path: "EasyEngineCore/Engine/VietnameseEngine.swift"
          role: "code"
          git_blob: "35a0190749c2ea1c5c37e5bd2c3bfed96f69fc03"
          git_blob_normalized: "35a0190749c2ea1c5c37e5bd2c3bfed96f69fc03"
        - path: "EasyEngineCore/Converter/Converter.swift"
          role: "code"
          git_blob: "0b990e8ce2106458e1816fd16ebb3613049cac21"
          git_blob_normalized: "0b990e8ce2106458e1816fd16ebb3613049cac21"
        - path: "EasyEngineCore/SmartSwitch/SmartSwitchStore.swift"
          role: "code"
          git_blob: "694b512e15a06e34e7df216ba74a4fc133e27f69"
          git_blob_normalized: "694b512e15a06e34e7df216ba74a4fc133e27f69"
        - path: "EasyEngineCore/Macros/MacroStore.swift"
          role: "code"
          git_blob: "a5909fcd5e5e13b871c24d359a2e89f002ae239a"
          git_blob_normalized: "a5909fcd5e5e13b871c24d359a2e89f002ae239a"
        - path: "EasyKeyApp/Features/Clipboard/PasteboardClassifier.swift"
          role: "code"
          git_blob: "c69905a6edc47571188e5d81a8de6c1f117bbcaf"
          git_blob_normalized: "c69905a6edc47571188e5d81a8de6c1f117bbcaf"
        - path: "EasyKeyApp/Features/Clipboard/ClipboardPersistence.swift"
          role: "code"
          git_blob: "2f2f6e1c7c03071c95010c565309b55a06b15c34"
          git_blob_normalized: "2f2f6e1c7c03071c95010c565309b55a06b15c34"
        - path: "EasyKeyApp/Coordination/UpdateService.swift"
          role: "code"
          git_blob: "186960351c6c963cfee981caef34e7aa8a544457"
          git_blob_normalized: "186960351c6c963cfee981caef34e7aa8a544457"
        - path: "docs/engineering/release.md"
          role: "doc"
          git_blob: "08e857f3de258116f1a988f7b9f6b0ed96dd189e"
          git_blob_normalized: "08e857f3de258116f1a988f7b9f6b0ed96dd189e"
        - path: "EasyKeyApp/AppDelegate.swift"
          role: "code"
          git_blob: "a0ba11e8c1cc4bd2a48d1cd346edfade871c67b8"
          git_blob_normalized: "a0ba11e8c1cc4bd2a48d1cd346edfade871c67b8"
        - path: "EasyKeyApp/Info.plist"
          role: "config"
          git_blob: "f4603871fa675111bd6db1472dfb04936ff3f645"
          git_blob_normalized: "f4603871fa675111bd6db1472dfb04936ff3f645"
        - path: "EasyKeyKit/Keyboard/KeyboardService.swift"
          role: "code"
          git_blob: "3246c7e678b841077f3006877c3b2ead836e912b"
          git_blob_normalized: "3246c7e678b841077f3006877c3b2ead836e912b"
        - path: "EasyEngineCore/Translation/TranslationOptions.swift"
          role: "code"
          git_blob: "ac20f144cfffb6a896dfc2fe27c2b6651e48456c"
          git_blob_normalized: "ac20f144cfffb6a896dfc2fe27c2b6651e48456c"
        - path: "EasyKeyApp/Features/Translation/TranslationModel.swift"
          role: "code"
          git_blob: "cbff7d5a4ea3f0690ff7b7962acafec1e9c88a0c"
          git_blob_normalized: "cbff7d5a4ea3f0690ff7b7962acafec1e9c88a0c"
        - path: "docs/security/data-handling.md"
          role: "doc"
          git_blob: "3776d80197dd7c1eace62a995c60c8f37d7731b2"
          git_blob_normalized: "3776d80197dd7c1eace62a995c60c8f37d7731b2"
      unresolved: []
---
# Glossary

_Last reviewed: 2026-08-13_

Terms are defined as the code and the owning documents use them. When casual
usage differs, the code meaning is authoritative and the discrepancy is noted.

| Term | Definition | Owning document |
|---|---|---|
| Telex | A Vietnamese input convention in which plain ASCII letters encode diacritics: repeated vowels (`aa` → `â`), `w` after vowels (`uw` → `ư`), `dd` → `đ`, and tone keys `s`/`f`/`r`/`x`/`j`/`z` applied position-free. EasyKey's exact rules live in the Telex rule set. | [telex.md](../flows/telex.md) |
| VNI | A Vietnamese input convention using digits for tones and diacritics (e.g. `to1i` for `tôi`) instead of Telex letters. Implemented as an `InputMethod` option in the engine. | `InputMethod.swift` (EasyEngineCore), [telex.md](../flows/telex.md) |
| Simple Telex | EasyKey's second Telex profile: full Telex without the standalone-`w` → `ư` and bracket (`[` `]` `{` `}`) extensions. Not a tones-only mode — `aw`, `ow`, `uw`, `uow` still compose because `w` remains a vowel modifier. | [telex.md](../flows/telex.md) |
| Tone placement | The rule governing where the tone mark lands on a composed Vietnamese syllable (e.g. `tá` vs `tà`), plus which finals accept which tones. EasyKey implements position-free marks and tones; `toneStyle` selects the canonical style. | [telex.md](../flows/telex.md), `ToneStyle.swift` |
| TCVN3 | A legacy Vietnamese encoding standard (TCVN 5712) using the Latin-1 code space, represented by the `EncodingTable.tcvn3` case and `TCVN3Encoding`. | `EncodingTable.swift` (EasyEngineCore) |
| VNI-Windows | The VNI/Windows-1258-era legacy encoding family for Vietnamese, represented by `EncodingTable.vniWindows` and `VNIWindowsEncoding`. | `EncodingTable.swift` (EasyEngineCore) |
| CP1258 | The Windows-1258 code page, an 8-bit Vietnamese encoding represented by `EncodingTable.cp1258` and `CP1258Encoding`. | `EncodingTable.swift` (EasyEngineCore) |
| Unicode Combining | Vietnamese encoded as base Latin letters plus combining diacritical marks, rather than precomposed codepoints. One of the five `EncodingTable` cases; `EncodingTable.unicode` is precomposed. | `EncodingTable.swift` (EasyEngineCore) |
| Smart Switch | The per-application input-memory feature: when enabled, EasyKey records the language (and optionally encoding) choice per application via `SmartSwitchStore.handleAppFocus` and reapplies it when that application comes to the front. "Smart Switch preferences" in casual usage means the `SmartSwitchPreference` records the store keeps. | `SmartSwitchStore.swift` |
| Macro trigger | The typed abbreviation (`Macro.trigger`) that, when completed and recognized, expands to `Macro.expansion` text. Limits: 128 characters per trigger, 16384 per expansion. | `MacroStore.swift` |
| Clipboard fingerprint | A stable SHA-256 digest computed over canonical ordered representations of a copy event (`PasteboardClassifier.fingerprint(of:)`), used to deduplicate history entries. | `PasteboardClassifier.swift` |
| AES-GCM sealed | Clipboard history persisted in encrypted form using `CryptoKit` AES-GCM with a 256-bit key stored in a device-only, non-synchronizing Keychain item. "Sealed" means the combined nonce+ciphertext+tag output of `AES.GCM.seal`. | `ClipboardPersistence.swift`, [data-handling.md](../security/data-handling.md) |
| Appcast | A Sparkle-format RSS feed (`appcast.xml`) listing release items with signed enclosure URLs. `UpdateService` configures Sparkle's `SPUStandardUpdaterController`, which fetches the feed over HTTPS and verifies every update with the appcast's EdDSA signature before installation; entries are appended by `Scripts/generate-appcast.py`. | [release.md](../engineering/release.md), `UpdateService.swift` |
| Accessory app | A macOS application with `LSUIElement` set (activation policy `.accessory`): no Dock icon, no Cmd-Tab entry, menu-bar resident. EasyKey runs this way; its windows cannot normally become key and it installs its own Edit-menu commands because accessory apps lack the system Edit menu. | [Info.plist](../../EasyKeyApp/Info.plist), `AppDelegate.swift` |
| Accessibility permission | The macOS Accessibility (AX) authorization EasyKey requires to observe and transform keyboard events system-wide via the Accessibility API and a `CGEvent` tap. Requested through `KeyboardService.requestAccessibilityPermission`; typing stays unavailable until granted. | `KeyboardService.swift`, [product overview](../product/overview.md) |
| Auto-translate delay | The idle delay (`TranslationOptions.autoTranslateDelayMs`, presets 250–1500 ms, default 500) after which the translation model automatically submits the current source text; every edit resets the timer (`scheduleAutoTranslate`). | `TranslationOptions.swift`, `TranslationModel.swift` |
| Disclosure prompt | The first-use prompt shown before a cloud translation request, naming the provider and explaining that source text is transferred to it. Declining cancels the request; acknowledgement is tracked per provider in `acknowledgedCloudDisclosureProviders` and can be reset in settings. | [data-handling.md](../security/data-handling.md), `TranslationModel.swift` |
| Encoding conversion | The standalone converter feature (`Converter`) that rewrites text between the supported encodings (`ConverterTransform`, `EncodingCodec`/`EncodingFactory`), independent of typing output encoding. | `Converter.swift` |
