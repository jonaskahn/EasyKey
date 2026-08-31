# Concepts

_Last reviewed: 2026-08-27_

This file is the compact domain-vocabulary register. A concept belongs here only when harvest records a repository-defined model with a lifecycle and invariants — not a one-line term and not an architecture block. Harvest produced zero concept candidates, so this section orients and bounds the empty register. Read [architecture.md](architecture.md) for system shape and [product.md](product.md) for who the product serves.

## At a glance

There is no harvested domain vocabulary to hold before reading architecture. Structure, import direction, and invariants live in [architecture.md](architecture.md). User-facing capabilities and non-goals live in [product.md](product.md). A term that needs one sentence belongs in the glossary in [reference.md](reference.md), not a concept section here.

Reading paths: stay here only to confirm the register is empty; go to architecture for how EasyKey is built; go to product for what ships.

## Scope and boundaries

This file owns the concept register and, when harvest yields them, one section per budgeted concept (what it models, owning block, lifecycle, invariants, relationships, failure boundary, where it lives). It does not own architecture rules, product outcomes, or glossary definitions.

Adjacent sections own the rest: [architecture.md](architecture.md) (deployable blocks and constraints), [product.md](product.md) (users and capabilities), [reference.md](reference.md) (lookup terms), [flows.md](flows.md) (ordered runtime). Compact layout keeps this section in `docs/`; harvest did not seed spilled concept files, and this folder has no unmerged concept siblings to link.

## Concept register

| Concept | Defined in | Depended on by |
|---|---|---|

The table is the full register. Harvest recorded zero concept candidates (`concept_candidates`: 0), so there are no rows, no register-only entries, and no folded concept sections. A later row would name a concept, where the repository defines it, and which documents depend on it; a register-only row would locate it without explaining lifecycle or invariants here.
