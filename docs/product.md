# Product

_Last reviewed: 2026-08-27_

EasyKey 0.0.14 is a macOS 14+ menu-bar app for people who type Vietnamese in other apps and want clipboard history, macros, and translation without switching to a system Input Method. This file answers what ships, who it is for, what it will not do, how to get a first result, and which interface locales exist. Engineers and first-time users both start here; architecture, runtime sequences, and lookup tables live next door.

## At a glance

EasyKey sits in the menu bar and composes Vietnamese (Telex, Simple Telex, or VNI; Simple Telex by default) into whichever app is focused, after macOS Accessibility is granted. Typing, macros, and on-device Apple Translation (macOS 15+) stay on the Mac. Clipboard capture is off until enabled; encrypted persistence is a second opt-in. Cloud translation and Sparkle update checks leave the device only when those features are configured.

| You want to | Read |
|---|---|
| Decide if EasyKey is for you | [Overview](#overview) |
| Launch a Debug build and see the menu bar | [Quickstart](#quickstart) |
| See English and Vietnamese UI coverage | [Localization](#localization) |
| Find a version-to-version migration guide | [Library migrations](#library-migrations) (none published) |

## Scope and boundaries

This file owns product positioning, the first launch path, the UI locale table, and the (empty) library-migration index. It does not own deployable structure ([architecture.md](architecture.md)), ordered runtime ([flows.md](flows.md)), build/test/release ([engineering.md](engineering.md)), settings matrices and user-visible limits ([reference.md](reference.md)), CI and DMG operations ([operations.md](operations.md)), threats and data classes ([security.md](security.md)), domain vocabulary ([concepts.md](concepts.md)), decision records ([decisions.md](decisions.md)), or contributor ownership ([contributing.md](contributing.md)). There is no `docs/product/` folder of unmerged siblings in this compact tree.

| Topic | Answers |
|---|---|
| [Overview](#overview) | What does this product do for me, and is it worth a deeper look? |
| [Quickstart](#quickstart) | Can I get one useful result in under a minute of reading? |
| [Localization](#localization) | Which locales does the UI actually support, and what happens when a string is missing? |
| [Library migrations](#library-migrations) | What lives in the migration index for a library consumer? |

Parent index: [Documentation](README.md). User-visible limits (Spotlight timing, README vs network features) are owned as limits in [reference.md](reference.md), not as engineering debt.

## Overview

When you type Vietnamese in Mail, a browser, or a terminal, EasyKey lets you keep a Telex- or VNI-style composer in the menu bar instead of installing a system Input Method — after you grant Accessibility. The same accessory can expand macros, recall clipboard history, and translate selected or typed text.

**Outcomes you can hire it for**

- Type Vietnamese in other apps using Telex, Simple Telex, or VNI; remember language and encoding per app; pause or force a language in chosen apps.
- Expand a typed trigger (for example `addr`) into a saved phrase, with import/export of that list.
- Optionally capture clipboard history (text, URLs, images, file references), search or pin it, and paste — in memory by default; AES-GCM on-disk persistence and a Keychain key only if you turn persistence on.
- Translate from a shortcut or panel: Apple Translation on-device on macOS 15+; otherwise, or instead, opt-in HTTPS providers (DeepL, Google, OpenAI, Anthropic, Gemini, OpenRouter, Groq, plus OpenAI- and Anthropic-compatible endpoints) after you store credentials.
- Check for app updates over HTTPS Sparkle when the release feed URL and EdDSA public key are present in the bundle.

**Boundaries (stated as plainly as the outcomes)**

- Not a macOS Input Method Kit input source. Composition uses a session event tap and requires Accessibility; without that permission, system-wide typing does not start.
- Not “everything stays on the Mac” in the absolute sense the root README’s opening line can be read as. Sparkle contacts an HTTPS appcast (and can download a the release archive DMG). Cloud translation sends source text to the provider you enable. Both are real product behavior; treat the README’s local-first sentence as typing, macros, Apple Translation, and default clipboard — not as a no-network guarantee. That tension is a user-visible limit, not a temporary shortcut.
- Clipboard manager and persisted history are off by default. Persistence seals a manifest and payloads with AES-GCM; turning persistence off deletes that store and the Keychain key.
- Apple Translation is unavailable on macOS 14. Cloud providers are unavailable until credentials exist. Automatic preference falls back to Apple when the OS supports it, else the first configured cloud provider, else setup-required.
- Tests and UI-test launches never start a live Sparkle updater.
- Spotlight can look briefly wrong right after open, then self-correct — a platform timing limit called out in the README, not a promised typing contract.

Capability-by-feature tables and step-by-step sequences are not this page: use [flows.md](flows.md) for runtime and [reference.md](reference.md) for settings, limits, and stack.

## Quickstart

**Prerequisites:** macOS 14.0 or later; Xcode and this checkout for a source launch (or a the release archive host DMG if you are not building); Accessibility permission for typing in other apps.

```bash
make run
```

This session did not execute that target. The Makefile’s `run` rule builds Debug `EasyKey.app` and opens it. Expected: the accessory appears in the menu bar (not as a regular Dock-first app). Grant Accessibility when prompted. Default typing method is Simple Telex; `vieejt nam` should compose to `việt nam` in another app once the tap is trusted. Clipboard capture stays off until enabled in Settings.

What next: [Overview](#overview) for what you just launched; [engineering.md](engineering.md) for full setup, tests, and release — this page is only the first result.

## Localization

**Resource format:** String Catalog JSON at `EasyKeyApp/Localizable.xcstrings` (source language `en`). Lookups use the resolved interface code, then English, then compiled language bundles / system localization. Interface language is stored separately from typing language. Shipped codes are `en` and `vi`. Default stored preference when unset is Vietnamese. System preference maps the first preferred language that starts with `vi` or `en`, otherwise English.

| Locale | Coverage | Fallback |
|---|---|---|
| `en` | Fully translated (444 catalog keys, state `translated`) | Source language; last-resort system localization |
| `vi` | Fully translated (same 444 keys, state `translated`) | English catalog value, then system localization |

No other UI locales ship. Missing keys do not stay blank: lookup always tries English after the resolved code. Partial or extra locales are a [reference.md](reference.md) limit if they appear later; none are claimed here.

## Library migrations

This index would list published source-to-target migration guides for a library consumer (breaking API order, verification, rollback). EasyKey is a shipped macOS app, not a versioned public SDK with those guides. No migration child is selected in this compact product file, and no `docs/product/` migration pages exist.

Internal settings `schemaVersion` and clipboard persistence schema checks are product data format rules, not a documented library upgrade path. There is nothing to apply in order and no rollback procedure to publish here. If a future app release needs a user-facing migration, it belongs as its own selected member, not as an implied row.
