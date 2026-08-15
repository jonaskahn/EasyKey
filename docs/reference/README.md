# Reference

_Last reviewed: 2026-08-15_

This section is the lookup table for EasyKey: what every setting controls, which versions the stack is built from, what the public API of the in-repo frameworks looks like, what is supported and tested, and the limitations to read before building on the project. Reach for it when you need a fact, not an explanation — the explanations live in the architecture, product, and engineering sections.

## At a glance

Six documents cover the facts of the repository: configuration surfaces and settings, known limitations and trade-offs, the declared tech stack, the public API surface of `EasyEngineCore` and `EasyKeyKit`, framework-level compatibility, and OS/architecture compatibility. Every version or minimum stated here is backed by declared evidence (build settings, manifests, or test suites) rather than aspiration.

## Scope and boundaries

This section owns *facts and limits*: what is configured, supported, tested, and named. It does not own how the system is designed ([architecture](../architecture/README.md)), the workflows for building and releasing ([engineering](../engineering/README.md)), or the product story ([product](../product/README.md)). Where a fact is claimed, the owning document states its evidence; this page only routes to it.

## Start here

| You want to | Read |
|---|---|
| Find out what a setting does before tuning it | [configuration.md](configuration.md) |
| Check what is unsupported or deliberately limited before building on it | [limitations.md](limitations.md) |
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
| [Tech stack](tech-stack.md) | Which technologies and versions make up the stack, with what evidence? |
| [API reference](api.md) | What is the public API surface of the in-repo frameworks, and what is deliberately not public? |
| [Compatibility](compatibility.md) | Which in-repo frameworks are supported and tested, at what versions, and by which suites? |
| [Platform compatibility](platform-compatibility.md) | Which OSes, architectures, and build forms are supported, tested to which minimums? |
<!-- docforge-children:end -->

## Related sections

- README — the parent index of all sections.
- [Architecture](../architecture/README.md) — the design that these facts constrain and describe.
- [Engineering](../engineering/README.md) — the workflows that consume these versions and minimums.
- [Operations](../operations/README.md) — the deployment and distribution facts these minimums feed into.
- [Product](../product/README.md) — the product story the reference facts describe.
