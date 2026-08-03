---
id: "decisions_index"
title: "Decision log"
docforge_provenance:
  schema: "2.0"
  doc_id: "decisions_index"
  path: "docs/architecture/decisions/README.md"
  generated_at: "2026-08-03T09:24:12Z"
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
          git_blob: "d3e6bbba80744e17534d29fa25980ccee91c2c79"
        - path: "docs/architecture/decisions/sparkle-updates.md"
          role: "doc"
          git_blob: "6c0243290e6675cc6c695a74efd072f87759d6fb"
      unresolved: []
    - id: "records"
      sources:
        - path: "docs/architecture/decisions/cgevent-tap-input.md"
          role: "doc"
          git_blob: "d3e6bbba80744e17534d29fa25980ccee91c2c79"
        - path: "docs/architecture/decisions/encrypted-clipboard.md"
          role: "doc"
          git_blob: "89816955d193b108b25fe4429c5ec99dda34bb6c"
        - path: "docs/architecture/decisions/log-redaction.md"
          role: "doc"
          git_blob: "585c2b3bcc17e603d5895a3a91a876f85f5f795b"
        - path: "docs/architecture/decisions/settings-delta.md"
          role: "doc"
          git_blob: "d0a477809d8f63947e3cb4c37eb078ec95e6b51f"
        - path: "docs/architecture/decisions/single-instance.md"
          role: "doc"
          git_blob: "1d2338d543dfdb6d05a741930ad5df6efb9b94c4"
        - path: "docs/architecture/decisions/sparkle-updates.md"
          role: "doc"
          git_blob: "6c0243290e6675cc6c695a74efd072f87759d6fb"
      unresolved: []
    - id: "related-sections"
      sources:
        - path: "docs/architecture/decisions/cgevent-tap-input.md"
          role: "doc"
          git_blob: "d3e6bbba80744e17534d29fa25980ccee91c2c79"
      unresolved: []
---
# Decision log

_Last reviewed: 2026-08-03_

This log records the architecture decisions EasyKey has made, each in its own record with context, decision, and consequences. Decisions are recorded so a future reader can tell why the code is the way it is without reconstructing history; rationale and tradeoffs live in each record, not here. The status lifecycle is `accepted` → `superseded`/`deprecated`: a decision starts accepted, and when a later record changes it, the old record is preserved and marked superseded rather than edited.

## How to read

| Status | Meaning |
|---|---|
| accepted | The decision is in effect; its consequences are implemented and tested |
| superseded | A later record replaced this one — read the newer record for the current commitment |
| deprecated | No longer in effect; kept for history |

## Records

<!-- docforge-children:start -->
| # | Decision | Status | Date | Answers |
|---|---|---|---|---|
| 1 | [CGEvent tap for input interception](cgevent-tap-input.md) | accepted | 2026-07-18 | Why does EasyKey use a CGEvent tap with the Accessibility API instead of an input method (IMK)? |
| 2 | [Encrypt persisted clipboard history](encrypted-clipboard.md) | accepted | 2026-07-18 | How is persisted clipboard history protected at rest? |
| 3 | [Redact credential patterns in log exports](log-redaction.md) | accepted | 2026-07-23 | What gets redacted from exported logs, and why? |
| 4 | [Gate keyboard reconfiguration on a settings delta](settings-delta.md) | accepted | 2026-07-23 | How do settings changes gate keyboard updates? |
| 5 | [Single-instance enforcement](single-instance.md) | accepted | 2026-07-23 | How is a second instance for the same user prevented? |
| 6 | [Signed updates via Sparkle with release-gated appcast](sparkle-updates.md) | accepted | 2026-07-23 | How is the update channel secured? |
<!-- docforge-children:end -->

## Related sections

- Parent index: [Architecture](../README.md)
