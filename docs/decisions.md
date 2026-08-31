# Decisions

_Last reviewed: 2026-08-27_

This file is the compact decision log: identifier, outcome title, status, date, and superseding record. Status moves proposed → accepted → superseded; a superseded row always names the replacement so a reader does not treat a stale record as current. Harvest produced zero ADR candidates, so this section states the empty register rather than reconstructing rationale. Read [architecture.md](architecture.md) for the resulting structure and [product.md](product.md) for what the product commits to ship.

## At a glance

This repository records architectural decisions that are expensive to reverse, not obvious from one file, or likely to be re-asked. Status values: **proposed** (written, not yet in force), **accepted** (in force), **superseded** (replaced; the successor id is in the register). Harvest recorded no such records, so there is nothing to apply before a change. Resulting facts live in [architecture.md](architecture.md); user-visible commitments live in [product.md](product.md).

Reading paths: stay here to confirm the log is empty; go to architecture before changing structure; go to product before changing what ships.

## Scope and boundaries

This file owns the decision register and, when harvest yields them, one section per budgeted ADR (context, decision, evidenced alternatives, consequences, revisit condition). It does not own implementation detail, architecture invariants, or retroactive justification the repository does not evidence.

Adjacent sections own the rest: [architecture.md](architecture.md) (the facts a decision would have shaped), [product.md](product.md) (capabilities and non-goals), [engineering.md](engineering.md) (how to build and ship). Compact layout keeps this section in `docs/`; harvest did not seed spilled decision files, and this folder has no unmerged decision siblings to link.

## Decision register

| ID | Decision | Status | Date | Superseded by |
|---|---|---|---|---|

The table is the full record. Harvest recorded zero decision candidates (`decision_candidates`: 0), so there are no rows, no register-only entries, and no folded ADR sections. A later row would keep the id, outcome title, status, date, and successor; a register-only row would stay named, dated, and status-tracked without expanding context or alternatives here. Unmerged siblings would be linked from this register; none exist.
