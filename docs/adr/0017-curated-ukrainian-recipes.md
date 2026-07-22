# 0017. Seed curated Ukrainian recipes to exercise the cuisine facet

- **Status:** Accepted
- **Date:** 2026-06-23

## Context

The allrecipes source is US-centric: `cuisine` is 0% populated, ~6% carry a cuisine-like
`category`, and it has no Ukrainian dishes. The cuisine column and classifier are groundwork
([0015](0015-cuisine-filter-deferred.md)) with no coherent data to show.

## Decision

Seed **18 curated Ukrainian recipes** (Borscht, Varenyky, Holubtsi…) through the same
parser → classifier → diet pipeline, tagged `cuisine: "Ukrainian"`. First-class, searchable,
idempotent upsert by title.

## Alternatives considered

- **Seed nothing** — no proof the pipeline generalizes beyond the US source.
- **Fabricate tags on existing recipes** — dishonest, no real signal.
- **Seed many cuisines** — more noise than a prototype needs; one proves the point.

## Consequences

- Shows the model handles a non-US cuisine end-to-end, no special-casing.
- DB holds **10,031 recipes** (10,013 + 18); cuisine flows through search/diet unchanged.
- Seeds **data, not a filter** — the filter stays deferred ([0015](0015-cuisine-filter-deferred.md)).
- **Changes if:** cuisine is inferred at scale → curated rows become unnecessary.