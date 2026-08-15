# Product

_Last reviewed: 2026-08-15_

This file tells the product story of EasyKey: what the app is, who it is for, how a new user gets to their first result, and the quality gates the product stands behind — verified accessibility behavior and interface localization. Engineers and product-minded readers who want the "what and why" before the "how" should start here; the engineering detail behind the claims lives in the sibling sections.

## At a glance

EasyKey is a menu-bar utility for typing Vietnamese in any application with Telex, Simple Telex, or VNI rules, plus a private clipboard history and opt-in translation — all keyboard transformation happens on-device with no analytics or telemetry. The product section covers five facets: what the product is and who it serves, the install-to-first-result path, the verified accessibility behaviors, the supported interface locales, and what happens to user settings when the app upgrades. Product promises stated here are backed by the named verification methods in each child document.

## Scope and boundaries

This section owns the product's *behavior and promises*: what EasyKey does, who it is for, how to get started, accessibility conformance practice, and language support. It does not own how the system is built ([architecture](architecture.md)), the release and update mechanics ([engineering](engineering.md)), or the security posture behind the privacy promises ([security](security/README.md)). Migration records that affect user-visible settings are covered here; how the released artifact is deployed and distributed across channels lives in [operations](operations/README.md).

| You want to | Read |
|---|---|
| Learn what EasyKey is and who it is for | [Overview](#overview) below |
| Install the app and get to your first Vietnamese result | [quickstart.md](product/quickstart.md) |
| Verify accessibility behaviors before relying on them | [accessibility.md](product/accessibility.md) |
| Understand which languages the interface ships in and how lookups fall back | [localization.md](product/localization.md) |
| See what changes when the app moves between versions | [migrations/README.md](product/migrations/README.md) |

## Overview

EasyKey is a menu-bar utility that turns your Mac into a fast, private Vietnamese typing machine. Type `vieejt nam` in any application and it appears as *việt nam*. Keyboard transformation happens entirely on your Mac: EasyKey collects no analytics or telemetry, and cloud translation is strictly opt-in.

### Who it's for

Anyone who types Vietnamese on a Mac and wants it to "just work" in every application, plus translators and power users who also want a private clipboard history and on-demand translation without a web tab. It is a clean-room implementation of public Vietnamese typing conventions (see the Telex rule set at notes/telex.md), not an input-method framework.

### What EasyKey does

When you need to type Vietnamese — in mail, chat, documents, or code — EasyKey lets you use familiar Telex, VNI, or Simple Telex rules instead of hunting for diacritics. It observes your keyboard through the macOS Accessibility API (the one permission it requires) and rewrites keystrokes into correctly marked Vietnamese text, app by app.

Three global shortcuts give you the core product, and all of them are configurable in Settings:

| Shortcut | Action |
|---|---|
| `⌥` + `V` | Open the clipboard manager |
| `⌥` + `C` | Open the translate panel |
| `⌥` + `Z` | Switch input language |

### Capabilities

- **Typing that matches your habits** — Telex, VNI, and Simple Telex rules, with tone-style, quick-Telex, and restore options.
- **Legacy encoding support** — convert between Unicode, Unicode Combining, TCVN3, VNI-Windows, and CP1258 so documents round-trip with older systems.
- **Text expansion** — trigger-based macros with import/export of your definitions.
- **Per-application memory** — Smart Switch remembers the language (and encoding) you chose for each application, and compatibility/ignore lists let you opt specific apps out.
- **A private clipboard manager** — off by default; keeps recent copies local, and optionally persists an AES-GCM-encrypted history that stays on this device.
- **Translation when you want it** — on-device Apple Translation on macOS 15 or later, or opt-in cloud providers (DeepL, Google, OpenAI, Anthropic, Gemini, OpenRouter, Groq, plus OpenAI- and Anthropic-compatible endpoints). Each cloud provider must be disclosed and accepted before its first request.
- **Localization** — the interface ships in English and Vietnamese.

### Boundaries and non-goals

- No cloud service, proxy, or telemetry: requests are sent directly from your Mac to the provider you picked, only from EasyKey's translation surfaces.
- No translation history, prompts, or translated text are persisted — and cloud credentials live in device-only, non-synchronizing Keychain items.
- The clipboard manager is not a security boundary: ignored-application filtering is best effort because macOS cannot always identify the source of a clipboard change.
- macOS 14.0 or later only; without the Accessibility grant keystrokes pass through untransformed, and a known macOS detection-timing issue can make typing look briefly broken in Spotlight ([known platform problems](reference.md)).
- Not a dictionary or grammar product — the capability set above is typing, clipboard, and translation only — and not an input method that runs inside other apps' extension hosts: EasyKey is a system-wide keyboard service using a CGEvent tap plus the Accessibility API, with no IMK input source produced ([limitations](reference.md)).

## Related sections

- [Flows](flows/README.md) — how keyboard typing, clipboard history, and translation actually behave
- [Reference](reference.md) — compatibility, limitations, and configuration detail
