---
id: "decisions_index"
title: "Decision log"
description: "What decision records are, the status lifecycle, and the reader question each record answers"
docforge_provenance:
  schema: "2.0"
  doc_id: "decisions_index"
  path: "docs/architecture/decisions/README.md"
  generated_at: "2026-08-13T12:05:04Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "router"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "how-to-read"
      sources:
        - path: "docs/architecture/decisions/cgevent-tap-input.md"
          role: "doc"
          git_blob: "ac1023240f0b8125e506db14e142563f83acd5a3"
        - path: "docs/architecture/decisions/sparkle-updates.md"
          role: "doc"
          git_blob: "3af37ac1be4c6c854fb7d0f0fd19e72d10b8061a"
      unresolved: []
    - id: "records"
      sources:
        - path: "docs/architecture/decisions/cgevent-tap-input.md"
          role: "doc"
          git_blob: "ac1023240f0b8125e506db14e142563f83acd5a3"
        - path: "docs/architecture/decisions/encrypted-clipboard.md"
          role: "doc"
          git_blob: "21202f7d19fbd1f1ca21642febc217c3223af140"
        - path: "docs/architecture/decisions/log-redaction.md"
          role: "doc"
          git_blob: "818ad21ea70d23d8b5b1d9ea20b12ec37c4e5569"
        - path: "docs/architecture/decisions/settings-delta.md"
          role: "doc"
          git_blob: "80241b21b40737cde1e3c4282f7705ccae700fb3"
        - path: "docs/architecture/decisions/single-instance.md"
          role: "doc"
          git_blob: "6d15a2316cef40fbb0725acf925031b080c3c527"
        - path: "docs/architecture/decisions/sparkle-updates.md"
          role: "doc"
          git_blob: "3af37ac1be4c6c854fb7d0f0fd19e72d10b8061a"
      unresolved: []
    - id: "related-sections"
      sources:
        - path: "docs/architecture/README.md"
          role: "doc"
          git_blob: "95d57cee5559b85c1ece0674766ce33232b71358"
      unresolved: []
---
# Decision log

_Last reviewed: 2026-08-13_

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
