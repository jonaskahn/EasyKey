---
id: "product_index"
title: "Product"
description: "Section overview for product: what EasyKey is, who it is for, and the reader question each product document answers"
docforge_provenance:
  schema: "2.0"
  doc_id: "product_index"
  path: "docs/product/README.md"
  generated_at: "2026-08-13T12:08:16Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "orientation"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "product"
      sources:
        - path: "README.md"
          role: "doc"
          git_blob: "adbd4f30d3c2f11bb855e6645195493a6c6a34f7"
        - path: "docs/product/overview.md"
          role: "doc"
          git_blob: "463e7774ac299d864da913a20fcda7ee75171eb4"
        - path: "docs/product/quickstart.md"
          role: "doc"
          git_blob: "c24c73c058829b7152803d1cd971f62f065ced99"
      unresolved: []
    - id: "at-a-glance"
      sources:
        - path: "docs/product/overview.md"
          role: "doc"
          git_blob: "463e7774ac299d864da913a20fcda7ee75171eb4"
        - path: "docs/product/accessibility.md"
          role: "doc"
          git_blob: "bfcfd3172df36de0c135af9b8af1e2b8d9925735"
        - path: "docs/product/localization.md"
          role: "doc"
          git_blob: "8f329a86a3dd76c8cf0859559c5baaff55bcae03"
      unresolved: []
    - id: "scope-and-boundaries"
      sources:
        - path: "docs/product/overview.md"
          role: "doc"
          git_blob: "463e7774ac299d864da913a20fcda7ee75171eb4"
        - path: "docs/architecture/README.md"
          role: "doc"
          git_blob: "95d57cee5559b85c1ece0674766ce33232b71358"
      unresolved: []
    - id: "start-here"
      sources:
        - path: "docs/product/overview.md"
          role: "doc"
          git_blob: "463e7774ac299d864da913a20fcda7ee75171eb4"
        - path: "docs/product/quickstart.md"
          role: "doc"
          git_blob: "c24c73c058829b7152803d1cd971f62f065ced99"
        - path: "docs/product/accessibility.md"
          role: "doc"
          git_blob: "bfcfd3172df36de0c135af9b8af1e2b8d9925735"
        - path: "docs/product/localization.md"
          role: "doc"
          git_blob: "8f329a86a3dd76c8cf0859559c5baaff55bcae03"
      unresolved: []
    - id: "detailed-documentation"
      sources:
        - path: "docs/product/overview.md"
          role: "doc"
          git_blob: "463e7774ac299d864da913a20fcda7ee75171eb4"
        - path: "docs/product/quickstart.md"
          role: "doc"
          git_blob: "c24c73c058829b7152803d1cd971f62f065ced99"
        - path: "docs/product/accessibility.md"
          role: "doc"
          git_blob: "bfcfd3172df36de0c135af9b8af1e2b8d9925735"
        - path: "docs/product/localization.md"
          role: "doc"
          git_blob: "8f329a86a3dd76c8cf0859559c5baaff55bcae03"
        - path: "docs/product/migrations/README.md"
          role: "doc"
          git_blob: "fc1cd80b502eadb50322d0c9875092f6bfaeaf04"
      unresolved: []
    - id: "related-sections"
      sources:
        - path: "docs/README.md"
          role: "doc"
          git_blob: "f46130b93e8bd0bfe43446dd7d42555ae5133400"
        - path: "docs/architecture/README.md"
          role: "doc"
          git_blob: "95d57cee5559b85c1ece0674766ce33232b71358"
        - path: "docs/security/README.md"
          role: "doc"
          git_blob: "ab0ce417c4410bdd0685d53be13089243bccb2be"
      unresolved: []
---
# Product

_Last reviewed: 2026-08-13_

This section tells the product story of EasyKey: what the app is, who it is for, how a new user gets to their first result, and the quality gates the product stands behind — verified accessibility behavior and interface localization. Engineers and product-minded readers who want the "what and why" before the "how" should start here; the engineering detail behind the claims lives in the sibling sections.

## At a glance

EasyKey is a menu-bar utility for typing Vietnamese in any application with Telex, Simple Telex, or VNI rules, plus a private clipboard history and opt-in translation — all keyboard transformation happens on-device with no analytics or telemetry. The section covers four facets: what the product is and who it serves, the install-to-first-result path, the verified accessibility behaviors, and the supported interface locales (see [localization.md](localization.md)). Product promises stated here are backed by the named verification methods in each child document.

## Scope and boundaries

This section owns the product's *behavior and promises*: what EasyKey does, who it is for, how to get started, accessibility conformance practice, and language support. It does not own how the system is built ([architecture](../architecture/README.md)), the release and update mechanics ([engineering](../engineering/README.md)), or the security posture behind the privacy promises ([security](../security/README.md)). Migration records that affect user-visible settings are covered here; operational migration of released channels lives in [operations](../operations/README.md).

## Start here

| You want to | Read |
|---|---|
| Learn what EasyKey is and who it is for | [overview.md](overview.md) |
| Install the app and get to your first Vietnamese result | [quickstart.md](quickstart.md) |
| Verify accessibility behaviors before relying on them | [accessibility.md](accessibility.md) |
| Understand which languages the interface ships in and how lookups fall back | [localization.md](localization.md) |
| See what changes when the app moves between versions | [migrations/README.md](migrations/README.md) |

## Detailed documentation

<!-- docforge-children:start -->
| Document | Answers |
|---|---|
| [Product overview](overview.md) | What is EasyKey, what does it do, and who is it for? |
| [Quickstart](quickstart.md) | How do I download, install, and reach my first typed Vietnamese result? |
| [Accessibility](accessibility.md) | Which accessibility behaviors are verified, and by what method? |
| [Localization](localization.md) | Which interface locales are supported, and what happens when a string is missing at runtime? |
| [Migrations](migrations/README.md) | What happens to user settings when the app moves between versions — what is migrated, what changes, and how is it verified? |
<!-- docforge-children:end -->

## Related sections

- [Documentation home](../README.md) — the parent index of all sections.
- [Architecture](../architecture/README.md) — how the product promises are implemented.
- [Engineering](../engineering/README.md) — how the product is built, tested, and shipped.
- [Security](../security/README.md) — privacy posture and data handling behind "no telemetry".
