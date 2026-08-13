---
id: "ownership"
title: "Ownership"
description: "Owned areas, responsibility boundaries, escalation tokens"
docforge_provenance:
  schema: "2.0"
  doc_id: "ownership"
  path: "docs/contributing/ownership.md"
  generated_at: "2026-08-13T11:23:14Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "reference"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "how-ownership-is-determined"
      sources:
        - path: "README.md"
          git_blob: "adbd4f30d3c2f11bb855e6645195493a6c6a34f7"
          git_blob_normalized: "adbd4f30d3c2f11bb855e6645195493a6c6a34f7"
          role: "doc"
        - path: "docs/engineering/rulebook.md"
          git_blob: "dba86c139b41f2fe59027bab1f0e9982fd8d0e00"
          git_blob_normalized: "dba86c139b41f2fe59027bab1f0e9982fd8d0e00"
          role: "doc"
        - path: "EasyKeyApp/AppDelegate.swift"
          git_blob: "a0ba11e8c1cc4bd2a48d1cd346edfade871c67b8"
          git_blob_normalized: "a0ba11e8c1cc4bd2a48d1cd346edfade871c67b8"
          role: "code"
        - path: "EasyKeyKit/Keyboard/KeyboardService.swift"
          git_blob: "3246c7e678b841077f3006877c3b2ead836e912b"
          git_blob_normalized: "3246c7e678b841077f3006877c3b2ead836e912b"
          role: "code"
        - path: "EasyEngineCore/Settings/EasyKeySettings.swift"
          git_blob: "aa8e22b824f59fd7a437d6af597ce6431ef10d57"
          git_blob_normalized: "aa8e22b824f59fd7a437d6af597ce6431ef10d57"
          role: "code"
      unresolved: []
    - id: "owned-areas"
      sources:
        - path: "docs/engineering/rulebook.md"
          git_blob: "dba86c139b41f2fe59027bab1f0e9982fd8d0e00"
          git_blob_normalized: "dba86c139b41f2fe59027bab1f0e9982fd8d0e00"
          role: "doc"
      unresolved: []
    - id: "related-sections"
      sources:
        - path: "docs/contributing/README.md"
          git_blob: "16b33f4a8f3fe2c3f3db4120cfe2725a5c3de606"
          git_blob_normalized: "16b33f4a8f3fe2c3f3db4120cfe2725a5c3de606"
          role: "doc"
        - path: "docs/README.md"
          git_blob: "9a4dbfbe7042df6537e860182440b00397f0fcd7"
          git_blob_normalized: "9a4dbfbe7042df6537e860182440b00397f0fcd7"
          role: "doc"
        - path: "CONTRIBUTING.md"
          git_blob: "1260b44b0820fc338baaf80d94f1715e90d5affc"
          git_blob_normalized: "1260b44b0820fc338baaf80d94f1715e90d5affc"
          role: "doc"
      unresolved: []
---
# Ownership

_Last reviewed: 2026-08-13_

This document records who owns each area of the EasyKey repository — what each area covers, what owning it means, and where to escalate. EasyKey is maintained by a single primary developer: every commit on the main branch (128 in total) is authored by one person under two author-name spellings (`jonaskahn` / `Jonas`) and two email spellings of the same mailbox: `tuyendev@gmail.com` (30 commits) and `tuyendev@gmai.com` (98 commits — a typo variant of the same mailbox). Ownership here therefore means *where the authority for an area lives*, not distinct people, and the escalation route for every area is the same: open an issue on the repository, which the primary developer routes.

## How ownership is determined

There is no automated owner-declaration file — no Code Owners file exists anywhere in the repository — so ownership is established from repository evidence rather than a declared map:

- **Commit history** — `git shortlog -sne` on the main branch shows a single developer across all 128 commits (the `gh-pages` branch adds bot-authored commits and is excluded). Per-directory commit volume (`git log --oneline -- <dir> | wc -l`) indicates where work concentrates: `EasyKeyApp` 73, `EasyKeyTests` 66, `EasyEngineCore` 41, `EasyKey.xcodeproj` 28, `EasyKeyKit` 28, `EasyKeyUITests` 18, `docs` 17, `Scripts` 9, `EasyKeyLoginHelper` 3, `Fixtures` 2. Volume is evidence of activity, not of distinct owners.
- **Documentation authority** — the repository README and the documents under `docs/` (per-section indexes plus the detail documents) are the stated home for design, decisions, and conventions. [Engineering conventions](../engineering/rulebook.md) define how code is written and reviewed but make no area-ownership statements; the authority for each area's decisions lives in the READMEs and documents that cover it.

## Owned areas

| Area | Responsibility boundary | Escalation |
|---|---|---|
| `docs/` | All documentation: architecture, operations, product, security, contributing. Review authority over documentation changes lives with the section READMEs and this ownership map; conventions apply per [rulebook.md](../engineering/rulebook.md) | Open an issue on the repository → primary developer |
| `EasyKeyApp/` | The macOS app shell: app lifecycle, menu-bar status item, window coordination, features (clipboard, settings, onboarding), and update service. Owns user-facing behavior and feature integration | Open an issue on the repository → primary developer |
| `EasyEngineCore/` | The engine and shared domain layer: Telex/VNI input engine, settings model and storage, diagnostics and logging primitives. Owns core behavior and its tests | Open an issue on the repository → primary developer |
| `EasyKeyKit/` | The keyboard pipeline: CGEvent tap, keyboard service, hotkeys, permission handling. Owns the input path and its availability states | Open an issue on the repository → primary developer |
| `EasyKeyLoginHelper/` | The login-helper executable that enables launching at login. Small, rarely touched surface | Open an issue on the repository → primary developer |
| `EasyKeyTests/` | Unit and integration tests. Changes alongside every behavior change (the busiest directory in history after the app itself); owning it means keeping the suite green and representative | Open an issue on the repository → primary developer |
| `EasyKeyUITests/` | UI test suite driving the app end-to-end | Open an issue on the repository → primary developer |
| `Scripts/` | Release automation: archive, DMG creation, notarization, stapling, appcast generation, QA gates, and verification scripts. Owns the release pipeline end-to-end | Open an issue on the repository → primary developer |
| `EasyKey.xcodeproj/`, `Fixtures/` | Build configuration, target wiring, signing settings, and test fixtures. Changes only when the project shape changes | Open an issue on the repository → primary developer |

Every area is owned by the same single primary developer, so no area is unowned or undetermined; the table above records what each area *is*, so a contributor touching it knows what is expected to change together and which documents hold the authority.

## Related sections

- Parent index: [Contributing](README.md)
- Repository docs index: [docs](../README.md)
- Contribution guide: [CONTRIBUTING.md](../../CONTRIBUTING.md)
