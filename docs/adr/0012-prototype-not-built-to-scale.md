# 0012. Ship as a prototype; document the scale path

- **Status:** Accepted
- **Date:** 2026-06-23

## Context

This is built as a prototype, deliberately avoiding over-engineering. It's
tempting to design for millions of recipes up front, but that would add infrastructure
nothing at this scale needs.

## Decision

Treat this as a **prototype**: 10k recipes load once, queries are simple and fast enough.
Where a scale concern is real, **document the next step** rather than build it now.

## Alternatives considered

- **Design for millions of recipes now** — inverted-index/search-engine infrastructure,
  denormalized coverage structures, background ingest. Over-engineered for this scale.

## Consequences

- The codebase stays small and reviewable; effort went into the parts that actually
  matter ([0002](0002-deterministic-parser-no-llm.md), [0006](0006-single-tuned-search-query.md)).
- Documented scale path, so the thinking is visible without the cost:
  - search: keyset pagination on the sort tuple + denormalized per-recipe coverage /
    inverted index ([0006](0006-single-tuned-search-query.md), [0013](0013-load-more-pagination.md));
  - ingest: a streamed background job + source adapters ([0011](0011-idempotent-import-pipeline.md));
  - matching: bitmap-over-dense-ingredient-id-space for pantry intersection.
- **Trade-off:** explicit ceilings (single-source ingest, offset pagination, no synonym
  layer) — each documented in its own ADR so nothing is a silent gap.
