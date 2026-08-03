---
id: "reference_index"
title: "Reference"
docforge_provenance:
  schema: "2.0"
  doc_id: "reference_index"
  path: "docs/reference/README.md"
  generated_at: "2026-08-03T09:30:00Z"
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
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
        - path: "docs/reference/tech-stack.md"
          role: "doc"
          git_blob: "6ab8fefba82e1574f588a33ce46e753c39dcd14f"
      unresolved: []
    - id: "at-a-glance"
      sources:
        - path: "docs/reference/configuration.md"
          role: "doc"
          git_blob: "cd5c690ece84602590635391872b0fa5c5c26d5f"
        - path: "docs/reference/tech-stack.md"
          role: "doc"
          git_blob: "6ab8fefba82e1574f588a33ce46e753c39dcd14f"
        - path: "docs/reference/glossary.md"
          role: "doc"
          git_blob: "2a4b44989ee10d8ed0a2aaafb5c0221c7a522818"
      unresolved: []
    - id: "scope-and-boundaries"
      sources:
        - path: "docs/reference/limitations.md"
          role: "doc"
          git_blob: "9aec52633368984700f558d596a07a00dd984d41"
      unresolved: []
    - id: "start-here"
      sources:
        - path: "docs/reference/configuration.md"
          role: "doc"
          git_blob: "cd5c690ece84602590635391872b0fa5c5c26d5f"
        - path: "docs/reference/limitations.md"
          role: "doc"
          git_blob: "9aec52633368984700f558d596a07a00dd984d41"
        - path: "docs/reference/glossary.md"
          role: "doc"
          git_blob: "2a4b44989ee10d8ed0a2aaafb5c0221c7a522818"
        - path: "docs/reference/api.md"
          role: "doc"
          git_blob: "5498a277adbb3b3e49b16f21b17c0fdb0d02ee66"
      unresolved: []
    - id: "detailed-documentation"
      sources:
        - path: "docs/reference/configuration.md"
          role: "doc"
          git_blob: "cd5c690ece84602590635391872b0fa5c5c26d5f"
        - path: "docs/reference/limitations.md"
          role: "doc"
          git_blob: "9aec52633368984700f558d596a07a00dd984d41"
        - path: "docs/reference/glossary.md"
          role: "doc"
          git_blob: "2a4b44989ee10d8ed0a2aaafb5c0221c7a522818"
        - path: "docs/reference/tech-stack.md"
          role: "doc"
          git_blob: "6ab8fefba82e1574f588a33ce46e753c39dcd14f"
        - path: "docs/reference/api.md"
          role: "doc"
          git_blob: "5498a277adbb3b3e49b16f21b17c0fdb0d02ee66"
        - path: "docs/reference/compatibility.md"
          role: "doc"
          git_blob: "7516db01e1ac506aa4ac6ef4877f07ac85290881"
        - path: "docs/reference/platform-compatibility.md"
          role: "doc"
          git_blob: "8cf9debf8d8f66f4d5247b5f87fceeb45463f605"
      unresolved: []
    - id: "related-sections"
      sources:
        - path: "docs/architecture/README.md"
          role: "doc"
          git_blob: "be324cfd1a847e1b3c9162f9196e9be1fd526347"
      unresolved: []
---
# Reference

_Last reviewed: 2026-08-03_

This section is the lookup table for EasyKey: what every setting controls, which versions the stack is built from, what the public API of the in-repo frameworks looks like, what is supported and tested, the terms the code uses, and the limitations to read before building on the project. Reach for it when you need a fact, not an explanation — the explanations live in the architecture, product, and engineering sections.

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
