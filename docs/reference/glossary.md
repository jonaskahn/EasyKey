---
id: "glossary"
title: "Glossary"
docforge_provenance:
  schema: "2.0"
  doc_id: "glossary"
  path: "docs/reference/glossary.md"
  generated_at: "2026-08-03T08:48:15Z"
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
        - path: "docs/_archive/TELEX.md"
          role: "doc"
          git_blob: "7a6c47e94add2cf0a95722716c29874a29c7d37b"
        - path: "EasyEngineCore/Engine/EncodingTable.swift"
          role: "code"
          git_blob: "5b5b5b8b5a8f1e2d400d096e819deafb07e16588"
        - path: "EasyEngineCore/Engine/VietnameseEngine.swift"
          role: "code"
          git_blob: "ce4d89e4d4d777c094e6bb2db46da198fae68c52"
        - path: "EasyEngineCore/Converter/Converter.swift"
          role: "code"
          git_blob: "bbc951650e27a7e9f4d364fec0d1cd16dc9f4be3"
        - path: "EasyEngineCore/SmartSwitch/SmartSwitchStore.swift"
          role: "code"
          git_blob: "694b512e15a06e34e7df216ba74a4fc133e27f69"
        - path: "EasyEngineCore/Macros/MacroStore.swift"
          role: "code"
          git_blob: "b8a7256fcac4629b3824c752dd654f849170de08"
        - path: "EasyKeyApp/Features/Clipboard/PasteboardClassifier.swift"
          role: "code"
          git_blob: "bc617726039dace9295116be51b3bd4ce96a73de"
        - path: "EasyKeyApp/Features/Clipboard/ClipboardPersistence.swift"
          role: "code"
          git_blob: "2f2f6e1c7c03071c95010c565309b55a06b15c34"
        - path: "EasyKeyApp/UpdateService.swift"
          role: "code"
          git_blob: "27386d368017c0c64f38e75fbd5e23e62c7a4dd6"
        - path: "docs/_archive/RELEASE.md"
          role: "doc"
          git_blob: "c749b17a004e3cf47af6af61e82db4aa9d40494d"
        - path: "EasyKeyApp/AppDelegate.swift"
          role: "code"
          git_blob: "8ecc5922afe0e99166cbcf3425afd2514b887ae2"
        - path: "EasyKeyApp/Info.plist"
          role: "config"
          git_blob: "f4603871fa675111bd6db1472dfb04936ff3f645"
        - path: "EasyKeyKit/KeyboardService.swift"
          role: "code"
          git_blob: "3d2db069ec81fb639d6eb9a6fc69121580854d31"
        - path: "EasyEngineCore/Translation/TranslationOptions.swift"
          role: "code"
          git_blob: "1c0c39a3d9bc405c47c447ac21c90b0d9545d89f"
        - path: "EasyKeyApp/Features/Translation/TranslationModel.swift"
          role: "code"
          git_blob: "dbeb3c07bd87de658d4a81c926b44de2dd18b405"
        - path: "docs/_archive/PRIVACY.md"
          role: "doc"
          git_blob: "4fab52de09cef3d41e3f25c500a4ab0df475a2b1"
      unresolved: []
---
# Glossary

_Last reviewed: 2026-08-03_

Terms are defined as the code and the owning documents use them. When casual
usage differs, the code meaning is authoritative and the discrepancy is noted.

| Term | Definition | Owning document |
|---|---|---|
| Telex | A Vietnamese input convention in which plain ASCII letters encode diacritics: repeated vowels (`aa` → `â`), `w` after vowels (`uw` → `ư`), `dd` → `đ`, and tone keys `s`/`f`/`r`/`x`/`j`/`z` applied position-free. EasyKey's exact rules live in the Telex rule set. | [TELEX.md](../flows/keyboard-typing.md) |
| VNI | A Vietnamese input convention using digits for tones and diacritics (e.g. `to1i` for `tôi`) instead of Telex letters. Implemented as an `InputMethod` option in the engine. | `InputMethod.swift` (EasyEngineCore), [TELEX.md](../flows/keyboard-typing.md) |
| Simple Telex | EasyKey's second Telex profile: full Telex without the standalone-`w` → `ư` and bracket (`[` `]` `{` `}`) extensions. Not a tones-only mode — `aw`, `ow`, `uw`, `uow` still compose because `w` remains a vowel modifier. | [TELEX.md](../flows/keyboard-typing.md) |
| Tone placement | The rule governing where the tone mark lands on a composed Vietnamese syllable (e.g. `tá` vs `tà`), plus which finals accept which tones. EasyKey implements position-free marks and tones; `toneStyle` selects the canonical style. | [TELEX.md](../flows/keyboard-typing.md), `ToneStyle.swift` |
| TCVN3 | A legacy Vietnamese encoding standard (TCVN 5712) using the Latin-1 code space, represented by the `EncodingTable.tcvn3` case and `TCVN3Encoding`. | `EncodingTable.swift` (EasyEngineCore) |
| VNI-Windows | The VNI/Windows-1258-era legacy encoding family for Vietnamese, represented by `EncodingTable.vniWindows` and `VNIWindowsEncoding`. | `EncodingTable.swift` (EasyEngineCore) |
| CP1258 | The Windows-1258 code page, an 8-bit Vietnamese encoding represented by `EncodingTable.cp1258` and `CP1258Encoding`. | `EncodingTable.swift` (EasyEngineCore) |
| Unicode Combining | Vietnamese encoded as base Latin letters plus combining diacritical marks, rather than precomposed codepoints. One of the five `EncodingTable` cases; `EncodingTable.unicode` is precomposed. | `EncodingTable.swift` (EasyEngineCore) |
| Smart Switch | The per-application input-memory feature: when enabled, EasyKey records the language (and optionally encoding) choice per application via `SmartSwitchStore.handleAppFocus` and reapplies it when that application comes to the front. "Smart Switch preferences" in casual usage means the `SmartSwitchPreference` records the store keeps. | `SmartSwitchStore.swift` |
| Macro trigger | The typed abbreviation (`Macro.trigger`) that, when completed and recognized, expands to `Macro.expansion` text. Limits: 128 characters per trigger, 16384 per expansion. | `MacroStore.swift` |
| Clipboard fingerprint | A stable SHA-256 digest computed over canonical ordered representations of a copy event (`PasteboardClassifier.fingerprint(of:)`), used to deduplicate history entries. | `PasteboardClassifier.swift` |
| AES-GCM sealed | Clipboard history persisted in encrypted form using `CryptoKit` AES-GCM with a 256-bit key stored in a device-only, non-synchronizing Keychain item. "Sealed" means the combined nonce+ciphertext+tag output of `AES.GCM.seal`. | `ClipboardPersistence.swift`, [PRIVACY.md](../security/data-handling.md) |
| Appcast | A Sparkle-format RSS feed (`appcast.xml`) listing release items with signed enclosure URLs. `UpdateService` fetches it over HTTPS and verifies every update with Sparkle's EdDSA signature before installation; entries are appended by `Scripts/generate-appcast.py`. | [RELEASE.md](../engineering/release.md), `UpdateService.swift` |
| Accessory app | A macOS application with `LSUIElement` set (activation policy `.accessory`): no Dock icon, no Cmd-Tab entry, menu-bar resident. EasyKey runs this way; its windows cannot normally become key and it installs its own Edit-menu commands because accessory apps lack the system Edit menu. | [Info.plist](../../EasyKeyApp/Info.plist), `AppDelegate.swift` |
| Accessibility permission | The macOS Accessibility (AX) authorization EasyKey requires to observe and transform keyboard events system-wide via the Accessibility API and a `CGEvent` tap. Requested through `KeyboardService.requestAccessibilityPermission`; typing stays unavailable until granted. | `KeyboardService.swift`, [product overview](../product/overview.md) |
| Auto-translate delay | The idle delay (`TranslationOptions.autoTranslateDelayMs`, presets 250–1500 ms, default 500) after which the translation model automatically submits the current source text; every edit resets the timer (`scheduleAutoTranslate`). | `TranslationOptions.swift`, `TranslationModel.swift` |
| Disclosure prompt | The first-use prompt shown before a cloud translation request, naming the provider and explaining that source text is transferred to it. Declining cancels the request; acknowledgement is tracked per provider in `acknowledgedCloudDisclosureProviders` and can be reset in settings. | [PRIVACY.md](../security/data-handling.md), `TranslationModel.swift` |
| Encoding conversion | The standalone converter feature (`Converter`) that rewrites text between the supported encodings (`ConverterTransform`, `EncodingCodec`/`EncodingFactory`), independent of typing output encoding. | `Converter.swift` |
