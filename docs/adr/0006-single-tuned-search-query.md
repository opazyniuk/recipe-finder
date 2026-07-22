# 0006. One structurally-tuned SQL query for search

- **Status:** Accepted
- **Date:** 2026-06-23

## Context

The search is the one query worth profiling (everything else is trivial). The first
version was a single big `GROUP BY`: it took every candidate (for a popular pantry item,
7,299 of 10,013 recipes), joined all ~74k of their `recipe_ingredients`, computed
total/have/missing, then `HAVING ≤ 2` discarded ~97%. `EXPLAIN ANALYZE` on the seeded
10k DB showed an external sort spilling **4.5 MB to disk** at **~142 ms**.

## Decision

Compute everything in **one SQL query**, tuned **structurally rather than with indexes**,
in three moves:
1. `total_count` reads the `recipes.ingredients_count` **counter cache** — no join to count.
2. `pantry_coverage` is one **indexed scan** over only the pantry-matching rows
   (`ingredient_id IN (:available)` → bitmap index scan), carrying `selected_count` for
   the "≥1 selected" relevance gate; the `missing ≤ 2` cutoff applies **before** any
   heavy work.
3. `missing_names` is a **correlated subquery scoped to the returned page** (≤25 rows),
   not a `string_agg` over 74k.

Result: **~142 ms → ~13 ms (~11×)**, byte-identical output (verified old vs new).

## Alternatives considered

- **Add an index on `recipes.total_time`** (the difficulty filter's column) — tested;
  changed nothing (identical plan, ~19 ms). Difficulty is a `CASE` expression, not a
  range on `total_time`, and recipes are reached by PK join from the CTE, so `total_time`
  is only a residual filter, never an access path. An index pays off on the driving
  predicate, not on a column you post-filter an already-narrow set by.
- **Multiple round-trips** (separate have/missing queries) — N+1 and slower.

## Consequences

- Sub-15 ms search, one round-trip, no N+1. The optimization approach in one line:
  profile first, fix the structure, prove it with `EXPLAIN ANALYZE`.
- Per-bucket result totals (`cook_now_total` / `almost_total`) ride along on the same
  query via `COUNT(*) FILTER (…) OVER ()` over the matched set (before `LIMIT`), so the UI
  shows "N of M" without a second count query (~+2 ms, measured ~13 → ~15 ms).
- Relies on the `ingredients_count` counter cache staying correct (maintained set-based
  at import, see [0011](0011-idempotent-import-pipeline.md)).
- What would change this at scale: keyset pagination on the sort tuple and a denormalized
  per-recipe coverage structure (see [0012](0012-prototype-not-built-to-scale.md)).
