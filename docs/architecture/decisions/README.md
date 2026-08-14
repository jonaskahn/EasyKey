---
id: "decisions_index"
title: "Decision log"
description: "What decision records are, the status lifecycle, and the reader question each record answers"
docforge_provenance:
  schema: "2.0"
  doc_id: "decisions_index"
  path: "docs/architecture/decisions/README.md"
  generated_at: "2026-08-14T00:00:00Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "router"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "decision-log"
      sources:
        - path: "docs/architecture/README.md"
          role: "doc"
          git_blob: "620a661337c9a4371fd2c8869d87d7c2a9565886"
          git_blob_normalized: "620a661337c9a4371fd2c8869d87d7c2a9565886"
      unresolved: []
    - id: "how-to-read"
      sources:
        - path: "docs/architecture/decisions/cgevent-tap-input.md"
          role: "doc"
          git_blob: "240359fc1e8aeac4f3346f4a77de1b210e5e5105"
          git_blob_normalized: "240359fc1e8aeac4f3346f4a77de1b210e5e5105"
        - path: "docs/architecture/decisions/sparkle-updates.md"
          role: "doc"
          git_blob: "b20ed0a33378c98d90fa71fbd3fa68a96bddb003"
          git_blob_normalized: "b20ed0a33378c98d90fa71fbd3fa68a96bddb003"
      unresolved: []
    - id: "records"
      sources:
        - path: "docs/architecture/decisions/cgevent-tap-input.md"
          role: "doc"
          git_blob: "240359fc1e8aeac4f3346f4a77de1b210e5e5105"
          git_blob_normalized: "240359fc1e8aeac4f3346f4a77de1b210e5e5105"
        - path: "docs/architecture/decisions/encrypted-clipboard.md"
          role: "doc"
          git_blob: "5b7c351ac7247cb3fe68cd9d8e5302fe20062ea1"
          git_blob_normalized: "5b7c351ac7247cb3fe68cd9d8e5302fe20062ea1"
        - path: "docs/architecture/decisions/log-redaction.md"
          role: "doc"
          git_blob: "d5256639e266d3fb08127d5e9860798dfb8d43b4"
          git_blob_normalized: "d5256639e266d3fb08127d5e9860798dfb8d43b4"
        - path: "docs/architecture/decisions/settings-delta.md"
          role: "doc"
          git_blob: "80241b21b40737cde1e3c4282f7705ccae700fb3"
        - path: "docs/architecture/decisions/single-instance.md"
          role: "doc"
          git_blob: "6d15a2316cef40fbb0725acf925031b080c3c527"
        - path: "docs/architecture/decisions/sparkle-updates.md"
          role: "doc"
          git_blob: "b20ed0a33378c98d90fa71fbd3fa68a96bddb003"
          git_blob_normalized: "b20ed0a33378c98d90fa71fbd3fa68a96bddb003"
      unresolved: []
    - id: "related-sections"
      sources:
        - path: "docs/architecture/README.md"
          role: "doc"
          git_blob: "620a661337c9a4371fd2c8869d87d7c2a9565886"
          git_blob_normalized: "620a661337c9a4371fd2c8869d87d7c2a9565886"
        - path: "docs/README.md"
          role: "doc"
          git_blob: "c26bf46583357c8db29f627fbc0deb41cd7df290"
          git_blob_normalized: "c26bf46583357c8db29f627fbc0deb41cd7df290"
      unresolved: []
---
# Decision log

_Last reviewed: 2026-08-14_

This log records the architecture decisions EasyKey has made, each in its own record with context, decision, and consequences. Decisions are recorded so a future reader can tell why the code is the way it is without reconstructing history; rationale and tradeoffs live in each record, not here. The status lifecycle is `accepted` → `superseded`/`deprecated`: a decision starts accepted, and when a later record changes it, the old record is preserved and marked superseded rather than edited.

## How to read

| Status | Meaning |
|---|---|
| accepted | The decision is in effect; its consequences are implemented and tested |
| superseded | A later record replaced this one — read the newer record for the current commitment |
| deprecated | No longer in effect; kept for history |

## Records

<!-- docforge-children:start -->
| # | Title | Status | Date | Topic |
|---|---|---|---|---|
| 1 | [Use a CGEvent tap with the macOS Accessibility API for input interception](cgevent-tap-input.md) | accepted | 2026-07-18 | input interception |
| 2 | [Encrypt persisted clipboard history with AES-GCM and a device-only Keychain key](encrypted-clipboard.md) | accepted | 2026-07-18 | clipboard security |
| 3 | [Redact credential patterns in log exports and restrict export file permissions](log-redaction.md) | accepted | 2026-07-23 | log security |
| 4 | [Gate keyboard service reconfiguration on a SettingsDelta diff](settings-delta.md) | accepted | 2026-07-23 | runtime behavior |
| 5 | [Terminate at launch when another instance is already running for the current user](single-instance.md) | accepted | 2026-07-23 | app lifecycle |
| 6 | [Deliver signed updates via Sparkle 2 with a release-gated appcast](sparkle-updates.md) | accepted | 2026-07-23 | update distribution |
<!-- docforge-children:end -->

## Related sections

- Parent index: [Architecture](../README.md)
- Repository docs index: [docs](../../README.md)
