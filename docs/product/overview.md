---
id: "product_overview"
title: "Product Overview"
docforge_provenance:
  schema: "2.0"
  doc_id: "product_overview"
  path: "docs/product/overview.md"
  generated_at: "2026-08-03T08:43:54Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "orientation"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "what-easykey-does"
      sources:
        - path: "README.md"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
          role: "doc"
        - path: "docs/_archive/TELEX.md"
          git_blob: "7a6c47e94add2cf0a95722716c29874a29c7d37b"
          role: "doc"
        - path: "EasyEngineCore/Settings/InputSettings.swift"
          git_blob: "55a05f33b0b86e23f3fbce6c956f8a2c4921e6ab"
          role: "code"
      unresolved: []
    - id: "who-its-for"
      sources:
        - path: "README.md"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
          role: "doc"
      unresolved: []
    - id: "capabilities"
      sources:
        - path: "README.md"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
          role: "doc"
        - path: "EasyEngineCore/Translation/TranslationProviderID.swift"
          git_blob: "d494c06ab4bc4fba8eaafdc2b51430f0e9cbc33d"
          role: "code"
        - path: "EasyEngineCore/Clipboard/ClipboardOptions.swift"
          git_blob: "f1409bbfebea82ad1d8e76ec6d75612f0b1b7a93"
          role: "code"
        - path: "EasyEngineCore/SmartSwitch/SmartSwitchOptions.swift"
          git_blob: "651f4dde5a9df0f03466c3185d904aa63c72f1af"
          role: "code"
        - path: "EasyEngineCore/Macros/MacroStore.swift"
          git_blob: "b8a7256fcac4629b3824c752dd654f849170de08"
          role: "code"
        - path: "EasyEngineCore/Engine/EncodingTable.swift"
          git_blob: "5b5b5b8b5a8f1e2d400d096e819deafb07e16588"
          role: "code"
      unresolved: []
    - id: "boundaries-and-non-goals"
      sources:
        - path: "README.md"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
          role: "doc"
        - path: "docs/_archive/PRIVACY.md"
          git_blob: "4fab52de09cef3d41e3f25c500a4ab0df475a2b1"
          role: "doc"
        - path: "EasyKeyApp/Features/Translation/TranslationCredentialStore.swift"
          git_blob: "768aab956a8d02978101105e7a896b6d55c75376"
          role: "code"
        - path: "docs/_archive/PROBLEMS.md"
          git_blob: "acb0eac12772c9857d236b931083ae0de175c6fe"
          role: "doc"
      unresolved: []
    - id: "where-to-go-next"
      sources:
        - path: "docs/flows/README.md"
          git_blob: "83492bedf226fa49c62e8290fd14fd6fe6b62f89"
          role: "doc"
        - path: "docs/reference/README.md"
          git_blob: "9f1b4e19d4bea1b2eaaa8bec65db8b75f160b7be"
          role: "doc"
      unresolved: []
---
# Product Overview

_Last reviewed: 2026-08-03_

EasyKey is a menu-bar utility that turns your Mac into a fast, private Vietnamese typing machine. Type `vieejt nam` in any application and it appears as *việt nam*. Keyboard transformation happens entirely on your Mac: EasyKey collects no analytics or telemetry, and cloud translation is strictly opt-in.

## What EasyKey does

When you need to type Vietnamese — in mail, chat, documents, or code — EasyKey lets you use familiar Telex, VNI, or Simple Telex rules instead of hunting for diacritics. It observes your keyboard through the macOS Accessibility API (the one permission it requires) and rewrites keystrokes into correctly marked Vietnamese text, app by app.

Three global shortcuts give you the core product, and all of them are configurable in Settings:

| Shortcut | Action |
|---|---|
| `⌥` + `V` | Open the clipboard manager |
| `⌥` + `C` | Open the translate panel |
| `⌥` + `Z` | Switch input language |

## Who it's for

Anyone who types Vietnamese on a Mac and wants it to "just work" in every application, plus translators and power users who also want a private clipboard history and on-demand translation without a web tab. It is a clean-room implementation of public Vietnamese typing conventions (see the [Telex rule set](../flows/keyboard-typing.md)), not an input-method framework.

## Capabilities

- **Typing that matches your habits** — Telex, VNI, and Simple Telex rules, with tone-style, quick-Telex, and restore options.
- **Legacy encoding support** — convert between Unicode, Unicode Combining, TCVN3, VNI-Windows, and CP1258 so documents round-trip with older systems.
- **Text expansion** — trigger-based macros with import/export of your definitions.
- **Per-application memory** — Smart Switch remembers the language (and encoding) you chose for each application, and compatibility/ignore lists let you opt specific apps out.
- **A private clipboard manager** — off by default; keeps recent copies local, and optionally persists an AES-GCM-encrypted history that stays on this device.
- **Translation when you want it** — on-device Apple Translation on macOS 15 or later, or opt-in cloud providers (DeepL, Google, OpenAI, Anthropic, Gemini, OpenRouter, Groq, plus OpenAI- and Anthropic-compatible endpoints). Each cloud provider must be disclosed and accepted before its first request.
- **Localization** — the interface ships in English and Vietnamese.

## Boundaries and non-goals

- No cloud service, proxy, or telemetry: requests are sent directly from your Mac to the provider you picked, only from EasyKey's translation surfaces.
- No history, prompts, or translated text are persisted — and cloud credentials live in device-only, non-synchronizing Keychain items.
- The clipboard manager is not a security boundary: ignored-application filtering is best effort because macOS cannot always identify the source of a clipboard change.
- macOS 14.0 or later only; typing is unavailable until Accessibility access is granted, and a known macOS detection-timing issue can make typing look briefly broken in Spotlight ([known platform problems](../reference/limitations.md)).
- Not a dictionary or grammar product, and not an input method that runs inside other apps' extension hosts — EasyKey is a system-wide keyboard service.

## Where to go next

- [README](../README.md) — install, build, and default shortcuts
- [Flows](../flows/README.md) — how keyboard typing, clipboard history, and translation actually behave
- [Reference](../reference/README.md) — compatibility, limitations, and configuration detail
- [Privacy](../security/data-handling.md) — data flows and provider handling
