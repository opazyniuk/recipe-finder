# 0011. Idempotent single-source import pipeline

- **Status:** Accepted
- **Date:** 2026-06-23

## Context

The project starts from a fixed source dataset. Loading ~10k recipes / ~93k
ingredient links naively (per-row inserts, `reset_counters`) would be slow and fragile,
and the load should be a re-runnable seed, not a one-off.

## Decision

`Recipes::Importer` is an **idempotent** pipeline (skips if recipes exist; `FORCE=1`
wipes and reseeds): stream-download + decompress the gz (no temp file), parse every line
via `Ingredients::Parser`, then **bulk-insert in batches sized under Postgres' 65,535
bind-param limit** (ingredients `upsert_all(unique_by: :name)`; recipes
`insert_all(returning: :id)` in 2k batches, ids captured in input order; links
`insert_all` in 5k batches, deduped per recipe). Counter caches are recomputed with **two
set-based `UPDATE … FROM (SELECT … GROUP BY)`**, not per-row. Seeds in ~7s. The reusable
core (`Parser`, `Classifier`) is source-agnostic; ingredients dedupe by `name`.

## Alternatives considered

- **Per-row `create!` + `reset_counters`** — ~17k+ queries, slow and N+1-shaped.
- **A `Source` adapter + recipe natural key now** — no value at this scope; deliberately
  deferred.

## Consequences

- Fast, repeatable seed; counter caches that the search query depends on
  ([0006](0006-single-tuned-search-query.md)) are maintained set-based.
- **Trade-off / deferred:** ingest is full-reseed-only. The importer hardcodes the
  recipe-scrapers record shape and one AllRecipes quirk (`unwrap_dead_image_proxy` for the
  Meredith image CDN), and `recipes` has no `external_url`/`source` — so no incremental
  adds, no cross-source dedup, no provenance, and parser improvements reach existing rows
  only via a full re-download (id churn).
- What would change this: a `Source` adapter (raw → normalized), `recipes.external_url`
  (unique) for incremental upserts, and a `recanonicalize` task re-parsing stored
  `raw_text` (decoupling parser fixes from re-fetch).
