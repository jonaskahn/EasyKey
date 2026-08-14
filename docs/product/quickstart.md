---
id: "quickstart"
title: "Quickstart"
description: "Shortest verified path to first useful result, prerequisites, expected output, next links"
docforge_provenance:
  schema: "2.0"
  doc_id: "quickstart"
  path: "docs/product/quickstart.md"
  generated_at: "2026-08-13T11:09:28Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "spine"
  target_depth: "deep-dive"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "getting-to-your-first-result"
      sources:
        - path: "README.md"
          git_blob: "8fc7891befa21173acaaaf1b19c8c30ad6bb3f97"
          git_blob_normalized: "8fc7891befa21173acaaaf1b19c8c30ad6bb3f97"
          role: "doc"
        - path: "docs/engineering/setup.md"
          git_blob: "31e235c41a5764c7e56e98f62e7df4ba9e120b9e"
          git_blob_normalized: "31e235c41a5764c7e56e98f62e7df4ba9e120b9e"
          role: "doc"
        - path: "Fixtures/sample-telex.json"
          git_blob: "a904b2094b8299dee38b8667525a24a75e759017"
          git_blob_normalized: "a904b2094b8299dee38b8667525a24a75e759017"
          role: "test"
        - path: "docs/_archive/telex.md"
          git_blob: "a5f49cdcc22cc2c33b9d345943c2105faab07967"
          git_blob_normalized: "a5f49cdcc22cc2c33b9d345943c2105faab07967"
          role: "doc"
      unresolved: []
    - id: "what-next"
      sources:
        - path: "README.md"
          git_blob: "8fc7891befa21173acaaaf1b19c8c30ad6bb3f97"
          git_blob_normalized: "8fc7891befa21173acaaaf1b19c8c30ad6bb3f97"
          role: "doc"
        - path: "docs/engineering/setup.md"
          git_blob: "31e235c41a5764c7e56e98f62e7df4ba9e120b9e"
          git_blob_normalized: "31e235c41a5764c7e56e98f62e7df4ba9e120b9e"
          role: "doc"
      unresolved: []
---
# Quickstart

_Last reviewed: 2026-08-13_

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

**Expected output:** the text transforms live into **việt nam** while you type, and the menu-bar icon shows the keyboard as active. The transform `vieejt nam → việt nam` is the engine's documented behavior (README, the archived Telex rule set) and is exercised by the engine's fixture tests (`Fixtures/sample-telex.json`, e.g. `v i e t s → viết`); this quickstart's GUI steps were written from those sources and were not re-executed on a Mac in this session.

The app is not Developer ID notarized yet, so on the very first launch macOS may ask you to control-click EasyKey and choose **Open**; full install notes and troubleshooting live in the README, and build-from-source commands (`make build`, `make test`) live in the [setup guide](../engineering/setup.md).

## What next

- Full setup and build from source: [Setup guide](../engineering/setup.md)
- What this does: [Product Overview](overview.md)
- Typing rules in depth: the archived Telex rule set
