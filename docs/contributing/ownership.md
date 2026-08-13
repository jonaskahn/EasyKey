---
id: "ownership"
title: "Ownership"
docforge_provenance:
  schema: "2.0"
  doc_id: "ownership"
  path: "docs/contributing/ownership.md"
  generated_at: "2026-08-03T09:24:12Z"
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
          role: "doc"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
        - path: "docs/_archive/CONVENTIONS.md"
          role: "doc"
          git_blob: "878c15dcb2e9f1fd811a7432688b8b20c6b72512"
        - path: "EasyKeyApp/AppDelegate.swift"
          role: "doc"
          git_blob: "8ecc5922afe0e99166cbcf3425afd2514b887ae2"
        - path: "EasyKeyKit/KeyboardService.swift"
          role: "doc"
          git_blob: "3d2db069ec81fb639d6eb9a6fc69121580854d31"
        - path: "EasyEngineCore/Settings/EasyKeySettings.swift"
          role: "doc"
          git_blob: "b42c58c6e3f1eba416bca3c809ba579441fe87cc"
      unresolved: []
    - id: "owned-areas"
      sources:
        - path: "docs/_archive/CONVENTIONS.md"
          role: "doc"
          git_blob: "878c15dcb2e9f1fd811a7432688b8b20c6b72512"
      unresolved: []
    - id: "related-sections"
      sources:
        - path: "docs/_archive/CONVENTIONS.md"
          role: "doc"
          git_blob: "878c15dcb2e9f1fd811a7432688b8b20c6b72512"
      unresolved: []
---
# Ownership

_Last reviewed: 2026-08-03_

This document records who owns each area of the EasyKey repository — what each area covers, what owning it means, and where to escalate. EasyKey is maintained by a single primary developer: every commit on the main branch (107 in total) is authored by the same identity (jonaskahn / Jonas), under two email spellings: `tuyendev@gmail.com` (9 commits) and `tuyendev@gmai.com` (98 commits — a typo variant of the same mailbox). Ownership here therefore means *where the authority for an area lives*, not distinct people, and the escalation route for every area is the same: open an issue on the repository, which the primary developer routes.

## How ownership is determined

There is no automated owner-declaration file — no Code Owners file exists anywhere in the repository — so ownership is established from repository evidence rather than a declared map:

- **Commit history** — `git shortlog -sne` on the main branch shows a single author identity across all 107 commits (the `gh-pages` branch adds bot-authored commits and is excluded). Per-directory commit volume (`git log --oneline -- <dir> | wc -l`) indicates where work concentrates: `EasyKeyApp` 58, `EasyKeyTests` 51, `EasyEngineCore` 30, `EasyKey.xcodeproj` 22, `EasyKeyKit` 18, `EasyKeyUITests` 16, `docs` 11, `Scripts` 6, `EasyKeyLoginHelper` 3, `Fixtures` 2. Volume is evidence of activity, not of distinct owners.
- **Documentation authority** — the repository README and the documents under `docs/` (per-section indexes plus the detail documents) are the stated home for design, decisions, and conventions. [Engineering conventions](../engineering/conventions.md) define how code is written and reviewed but make no area-ownership statements; the authority for each area's decisions lives in the READMEs and documents that cover it.

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
