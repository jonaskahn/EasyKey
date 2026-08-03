---
id: "adr-log-redaction"
title: "Adr Log Redaction"
docforge_provenance:
  schema: "2.0"
  doc_id: "adr-log-redaction"
  path: "docs/architecture/decisions/log-redaction.md"
  generated_at: "2026-08-03T08:44:33Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "reference"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "context-and-problem-statement"
      sources:
        - path: "EasyKeyApp/Coordination/LogExporter.swift"
          git_blob: "3d1a645db3bcb360f93a997575bcae4bb88071c9"
          role: "code"
        - path: "EasyKeyApp/Coordination/LogExporter.swift"
          git_blob: "3d1a645db3bcb360f93a997575bcae4bb88071c9"
          role: "history"
      unresolved: []
    - id: "decision"
      sources:
        - path: "EasyKeyApp/Coordination/LogExporter.swift"
          git_blob: "3d1a645db3bcb360f93a997575bcae4bb88071c9"
          role: "code"
        - path: "docs/_archive/PRIVACY.md"
          git_blob: "4fab52de09cef3d41e3f25c500a4ab0df475a2b1"
          role: "doc"
        - path: "docs/_archive/PRIVACY.md"
          git_blob: "4fab52de09cef3d41e3f25c500a4ab0df475a2b1"
          role: "history"
      unresolved: []
    - id: "consequences"
      sources:
        - path: "EasyKeyApp/Coordination/LogExporter.swift"
          git_blob: "3d1a645db3bcb360f93a997575bcae4bb88071c9"
          role: "code"
        - path: "docs/_archive/PRIVACY.md"
          git_blob: "4fab52de09cef3d41e3f25c500a4ab0df475a2b1"
          role: "doc"
      unresolved: []
    - id: "confirmation"
      sources:
        - path: "EasyKeyTests/LogExporterTests.swift"
          git_blob: "bff153b766b934917dc91a10e680c42b811a23f3"
          role: "test"
      unresolved: []
---
# 3. Redact credential patterns in log exports and restrict export file permissions

- **Status:** accepted
- **Date:** 2026-07-23
- **Deciders:** project maintainer

## Context and problem statement

"Show Logs" exports recent OSLog entries to a temporary file and reveals it in Finder so users can attach diagnostics to bug reports. Log lines can legitimately carry content that includes provider credential strings — for example API keys captured inside composed log messages. The export previously wrote messages verbatim with default file permissions, and the privacy documentation did not describe export-time protection. Commit fd10a18 ("fix(security): redact sensitive keys and restrict log export permissions") closed the gap: redact before writing and restrict output permissions.

## Considered options

- **Pattern redaction at export time plus restricted permissions** — chosen.
- **Never log anything sensitive at the source** — attractive but not enforceable as a contract across every log call.
- **Restrict export to safe categories only** — already in place (`.app`, `.keyboard`, `.settings`) but not sufficient by itself.
- **Encrypt exported log files** — user-hostile for a diagnostic file meant to be read and attached.

## Decision

We chose **export-time pattern redaction with `0600` output permissions**. `LogExporter.redact(_:)` replaces common credential shapes — OpenAI-style `sk-…` keys, Google `AIzaSy…` keys, and `x-api-key:` headers — with `[REDACTED]`, applied to every OSLog entry message before it is written; `writeExport` then sets POSIX permissions `0600` on the output file. Category filtering to `.app`, `.keyboard`, `.settings` remains the first gate, and [docs/PRIVACY.md](../../security/data-handling.md) was updated in the same commit to state that diagnostic log exports perform pattern redaction on credentials and restrict output permissions to 0600.

## Decision drivers

- Exported logs are user-facing artifacts, so protection belongs at the export boundary, not only in individual log statements.
- The redaction patterns cover the credential formats the app actually handles (cloud-provider API keys).
- `0600` keeps the exported file unreadable by other local users while remaining convenient for the owner to open.

## Option comparison

| Option | Good | Neutral | Bad |
|---|---|---|---|
| Export-time redaction + 0600 | one enforcement point; covers future log statements automatically | regex coverage must be extended when new key formats appear | redaction runs on every export; pattern list must be maintained |
| Source-level never-log | protects everywhere, not just exports | — | discipline-dependent; no single enforcement point |
| Category filtering only | simple | already the first gate | credential strings could still appear inside allowed categories |
| Encrypted export | strong at rest | — | unusable as a shareable diagnostic file |

## Consequences

**Positive:** API-key material no longer leaves the machine via exported logs; the export file is unreadable by other users; the behavior is documented in the privacy notes, so the promise is stated and testable.

**Negative:** redaction is pattern-based — a credential format not covered by the three patterns would pass through; the on-disk OSLog store still holds raw messages (redaction applies to the export, not the store).

**Neutral:** export behavior is otherwise unchanged — same categories, same 60-minute lookback window and 2000-entry cap.

## Revisit if

- New cloud providers introduce credential formats the patterns do not match (extend `redact`).
- Apple's OSLog privacy masking becomes the preferred mechanism for message content.
- The export format adds structured fields (for example JSON attachments) that bypass line-based redaction.

## Confirmation

`LogExporterTests` pins the redaction behavior and the permission attribute on the output file, and the [docs/PRIVACY.md](../../security/data-handling.md) statement keeps the promise visible. Tests run under `make test`; the 90% line-coverage gate is enforced by `make coverage` and CI.
