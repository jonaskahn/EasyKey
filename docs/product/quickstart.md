---
id: "quickstart"
title: "Quickstart"
docforge_provenance:
  schema: "2.0"
  doc_id: "quickstart"
  path: "docs/product/quickstart.md"
  generated_at: "2026-08-03T08:43:54Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "deep-dive"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "getting-to-your-first-result"
      sources:
        - path: "README.md"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
          role: "doc"
        - path: "Fixtures/sample-telex.json"
          git_blob: "a904b2094b8299dee38b8667525a24a75e759017"
          role: "test"
        - path: "docs/_archive/TELEX.md"
          git_blob: "7a6c47e94add2cf0a95722716c29874a29c7d37b"
          role: "doc"
      unresolved: []
    - id: "what-next"
      sources:
        - path: "README.md"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
          role: "doc"
      unresolved: []
---
# Quickstart

_Last reviewed: 2026-08-03_

**Prerequisites:** macOS 14.0 or later (Apple silicon or Intel). Typing stays off until you grant Accessibility access — EasyKey asks for it on first launch, and you can review it later in **System Settings → Privacy & Security → Accessibility**.

## Getting to your first result

1. Download the latest universal DMG (`EasyKey-<version>-universal.dmg`) from the project's releases page.
2. Open the DMG and drag **EasyKey** into **Applications**.
3. Launch EasyKey from Applications, and grant Accessibility access when prompted.

Once EasyKey is in the menu bar, verify it in any text field:

```bash
open /Applications/EasyKey.app
```

Then type this in any app (Notes, Mail, your editor):

```text
vieejt nam
```

**Expected output:** the text transforms live into **việt nam** while you type, and the menu-bar icon shows the keyboard as active. The transform `vieejt nam → việt nam` is the engine's documented behavior ([README](../README.md), [Telex rule set](../flows/keyboard-typing.md)) and is exercised by the engine's fixture tests (`Fixtures/sample-telex.json`, e.g. `v i e t s → viết`); this quickstart's GUI steps were written from those sources and were not re-executed on a Mac in this session.

The app is not Developer ID notarized yet, so on the very first launch macOS may ask you to control-click EasyKey and choose **Open**; full install notes, build-from-source commands (`make build`, `make test`), and troubleshooting live in the [README](../README.md).

## What next

- Full setup and build from source: [README](../README.md)
- What this does: [Product Overview](overview.md)
- Typing rules in depth: [Telex rule set](../flows/keyboard-typing.md)
