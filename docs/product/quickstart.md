# Quickstart

_Last reviewed: 2026-08-15_

**Prerequisites:** macOS 14.0 or later (Apple silicon or Intel). Typing stays off until you grant Accessibility access — EasyKey asks for it on first launch, and you can review it later in **System Settings → Privacy & Security → Accessibility**.

Download the latest universal DMG (`EasyKey-<version>-universal.dmg`) from the project's releases page, open it, drag **EasyKey** into **Applications**, then launch it and grant Accessibility access when prompted. To reach the first result in under a minute:

```bash
open /Applications/EasyKey.app
```

Then type this in any app (Notes, Mail, your editor):

```text
vieejt nam
```

**Expected output:** the text transforms live into **việt nam** while you type. Until Accessibility is granted the menu-bar icon shows a warning triangle; once granted it shows the keyboard-style icon for the active language. The transform `vieejt nam → việt nam` is the engine's documented behavior (README, the Telex rule set at notes/telex.md) and is exercised by the engine's fixture tests (`Fixtures/sample-telex.json`, e.g. `v i e t s → viết`); this quickstart's GUI steps were written from those sources and were not re-executed on a Mac in this session.

The app is not Developer ID notarized yet, so on the very first launch macOS may ask you to control-click EasyKey and choose **Open**; full install notes and troubleshooting live in the README, and build-from-source commands (`make build`, `make test`) live in the setup guide.

## What next

- Full setup and build from source: [Setup guide](../engineering/setup.md)
- What this does: [Product Overview](overview.md)
- Typing rules in depth: the Telex rule set (notes/telex.md)
