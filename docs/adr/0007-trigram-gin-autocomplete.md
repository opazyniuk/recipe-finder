# 0007. Trigram GIN for typo-tolerant ingredient autocomplete

- **Status:** Accepted
- **Date:** 2026-06-23

## Context

The pantry picker needs fast autocomplete over ~6,947 ingredient names, ideally tolerant
of typos ("chiken" → "chicken"). A plain B-tree on `name` only helps anchored prefixes
and can't do case-insensitive or fuzzy infix matching.

## Decision

Index `ingredients.name` with a **GIN trigram index** (`gin_trgm_ops`, the `pg_trgm`
extension). `Ingredients::Search.autocomplete` runs `WHERE name ILIKE :prefix OR name %
:query`, ordered prefix-matches-first → `recipes_count` desc → name. The single trigram
GIN serves **both** predicates: `gin_trgm_ops` accelerates `ILIKE`/`LIKE` *and* the `%`
similarity operator.

## Alternatives considered

- **Exact / prefix-only B-tree** — no typo tolerance, no infix matching.
- **Postgres full-text search (`tsvector`)** — built for documents/word stems, not short
  fuzzy entity names; doesn't give similarity ranking for typos.
- **GiST trigram** — smaller and supports KNN distance ordering, but lossier and slower
  to search. GIN wins for a read-heavy, write-once table (see consequences).

## Consequences

- Cheap typo tolerance and prefix-first ordering from one index.
- **Trade-off:** GIN writes are expensive (one row explodes into many trigram keys), but
  ingredients are bulk-loaded once at seed and then read-only — the ideal GIN profile.
- Honest scale note: on 6,947 rows the planner often still prefers a seq scan (the table
  is tiny); the index is correct and "on for growth", where it dominates at 100k+ names.
- Popularity ordering relies on the `recipes_count` counter cache, avoiding a runtime
  aggregate.
