---
id: "reference_index"
title: "Reference"
description: "Section overview for reference: the exact facts about EasyKey, and the reader question each reference document answers"
docforge_provenance:
  schema: "2.0"
  doc_id: "reference_index"
  path: "docs/reference/README.md"
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
    - id: "reference"
      sources:
        - path: "README.md"
          role: "doc"
          git_blob: "adbd4f30d3c2f11bb855e6645195493a6c6a34f7"
        - path: "docs/reference/tech-stack.md"
          role: "doc"
          git_blob: "d73c28f8dd37e7d2b0d77404c798830dc4aa4485"
        - path: "docs/reference/configuration.md"
          role: "doc"
          git_blob: "d6b12bb4af284c1a30b4a363fa41686d2392d4f6"
      unresolved: []
    - id: "at-a-glance"
      sources:
        - path: "docs/reference/configuration.md"
          role: "doc"
          git_blob: "d6b12bb4af284c1a30b4a363fa41686d2392d4f6"
        - path: "docs/reference/tech-stack.md"
          role: "doc"
          git_blob: "d73c28f8dd37e7d2b0d77404c798830dc4aa4485"
        - path: "docs/reference/glossary.md"
          role: "doc"
          git_blob: "b9a60b2c985bf7ba2e92faf22c12d7082bf9d8c6"
        - path: "docs/reference/compatibility.md"
          role: "doc"
          git_blob: "4989ab2d27d4b598caab95f70abcc48f7683efec"
        - path: "docs/reference/platform-compatibility.md"
          role: "doc"
          git_blob: "87ac5088eb1eb189249ca982cf9e418340e8dcc1"
      unresolved: []
    - id: "scope-and-boundaries"
      sources:
        - path: "docs/reference/limitations.md"
          role: "doc"
          git_blob: "8e3e23bf6b098a52db5efcd4e4328dfea588b6e1"
        - path: "docs/reference/tech-stack.md"
          role: "doc"
          git_blob: "d73c28f8dd37e7d2b0d77404c798830dc4aa4485"
      unresolved: []
    - id: "start-here"
      sources:
        - path: "docs/reference/configuration.md"
          role: "doc"
          git_blob: "d6b12bb4af284c1a30b4a363fa41686d2392d4f6"
        - path: "docs/reference/limitations.md"
          role: "doc"
          git_blob: "8e3e23bf6b098a52db5efcd4e4328dfea588b6e1"
        - path: "docs/reference/glossary.md"
          role: "doc"
          git_blob: "b9a60b2c985bf7ba2e92faf22c12d7082bf9d8c6"
        - path: "docs/reference/api.md"
          role: "doc"
          git_blob: "ef8cad70185c47712d0d3721523b8765c0a919f8"
        - path: "docs/reference/compatibility.md"
          role: "doc"
          git_blob: "4989ab2d27d4b598caab95f70abcc48f7683efec"
        - path: "docs/reference/platform-compatibility.md"
          role: "doc"
          git_blob: "87ac5088eb1eb189249ca982cf9e418340e8dcc1"
      unresolved: []
    - id: "detailed-documentation"
      sources:
        - path: "docs/reference/configuration.md"
          role: "doc"
          git_blob: "d6b12bb4af284c1a30b4a363fa41686d2392d4f6"
        - path: "docs/reference/limitations.md"
          role: "doc"
          git_blob: "8e3e23bf6b098a52db5efcd4e4328dfea588b6e1"
        - path: "docs/reference/glossary.md"
          role: "doc"
          git_blob: "b9a60b2c985bf7ba2e92faf22c12d7082bf9d8c6"
        - path: "docs/reference/tech-stack.md"
          role: "doc"
          git_blob: "d73c28f8dd37e7d2b0d77404c798830dc4aa4485"
        - path: "docs/reference/api.md"
          role: "doc"
          git_blob: "ef8cad70185c47712d0d3721523b8765c0a919f8"
        - path: "docs/reference/compatibility.md"
          role: "doc"
          git_blob: "4989ab2d27d4b598caab95f70abcc48f7683efec"
        - path: "docs/reference/platform-compatibility.md"
          role: "doc"
          git_blob: "87ac5088eb1eb189249ca982cf9e418340e8dcc1"
      unresolved: []
    - id: "related-sections"
      sources:
        - path: "docs/README.md"
          role: "doc"
          git_blob: "f46130b93e8bd0bfe43446dd7d42555ae5133400"
        - path: "docs/architecture/README.md"
          role: "doc"
          git_blob: "95d57cee5559b85c1ece0674766ce33232b71358"
        - path: "docs/engineering/README.md"
          role: "doc"
          git_blob: "eb772ae315052f41c6bd2267dbc0886260ba0447"
        - path: "docs/operations/README.md"
          role: "doc"
          git_blob: "aec2487a702a755dcfd080d0d8921cbe0b3bb2bf"
      unresolved: []
---
# Reference

_Last reviewed: 2026-08-13_

This section is the lookup table for EasyKey: what every setting controls, which versions the stack is built from, what the public API of the in-repo frameworks looks like, what is supported and tested, and the limitations to read before building on the project. Reach for it when you need a fact, not an explanation — the explanations live in the architecture, product, and engineering sections.

## At a glance

Seven documents cover the facts of the repository: configuration surfaces and settings, known limitations and trade-offs, the glossary of terms, the declared tech stack, the public API surface of `EasyEngineCore` and `EasyKeyKit`, framework-level compatibility, and OS/architecture compatibility. Every version or minimum stated here is backed by declared evidence (build settings, manifests, or test suites) rather than aspiration.

## Scope and boundaries

This section owns *facts and limits*: what is configured, supported, tested, and named. It does not own how the system is designed ([architecture](../architecture/README.md)), the workflows for building and releasing ([engineering](../engineering/README.md)), or the product story ([product](../product/README.md)). Where a fact is claimed, the owning document states its evidence; this page only routes to it.

## Start here

| You want to | Read |
|---|---|
| Find out what a setting does before tuning it | [configuration.md](configuration.md) |
| Check what is unsupported or deliberately limited before building on it | [limitations.md](limitations.md) |
| Decode a term used in code or documents | [glossary.md](glossary.md) |
| Confirm the stack, versions, and their evidence | [tech-stack.md](tech-stack.md) |
| Use the public API of the in-repo frameworks | [api.md](api.md) |
| Check which frameworks are supported and tested | [compatibility.md](compatibility.md) |
| Check OS, architecture, and build-form minimums | [platform-compatibility.md](platform-compatibility.md) |

## Detailed documentation

<!-- docforge-children:start -->
| Document | Answers |
|---|---|
| [Configuration](configuration.md) | Where does EasyKey read configuration from, and what does each setting control? |
| [Limitations and known issues](limitations.md) | What are the known limitations and deliberate trade-offs to read before building on EasyKey? |
| [Glossary](glossary.md) | What does each term mean as the code and owning documents use it, and where is the meaning defined? |
| [Tech stack](tech-stack.md) | Which technologies and versions make up the stack, with what evidence? |
| [API reference](api.md) | What is the public API surface of the in-repo frameworks, and what is deliberately not public? |
| [Compatibility](compatibility.md) | Which in-repo frameworks are supported and tested, at what versions, and by which suites? |
| [Platform compatibility](platform-compatibility.md) | Which OSes, architectures, and build forms are supported, tested to which minimums? |
<!-- docforge-children:end -->

## Related sections

- [Documentation home](../README.md) — the parent index of all sections.
- [Architecture](../architecture/README.md) — the design that these facts constrain and describe.
- [Engineering](../engineering/README.md) — the workflows that consume these versions and minimums.
- [Operations](../operations/README.md) — the deployment and distribution facts these minimums feed into.
