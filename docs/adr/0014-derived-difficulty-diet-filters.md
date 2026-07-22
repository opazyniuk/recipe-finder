# 0014. Derived difficulty & diet filters

- **Status:** Accepted
- **Date:** 2026-06-23

## Context

The dataset is thin — 9 fields, and `cuisine` is 100% empty (see [0015](0015-cuisine-filter-deferred.md)).
Useful filters beyond the pantry have to come from data that's actually present
(`prep_time`/`cook_time`, `ratings`, `ingredients`) or be *derived*.

## Decision

Layer a few optional filters **on top of** the coverage ranking, as extra `WHERE`
predicates on the same finder query ([0006](0006-single-tuned-search-query.md)):

- **Difficulty** — a `CASE` expression over total time / ingredient count
  (`Recipes::Finder::Difficulty`).
- **Diet** (vegetarian / vegan) — **derived from the ingredient set** by
  `Recipes::Classifier` (token match against curated MEAT / DAIRY_EGG / PLANT lists:
  `meat?` → not vegetarian, `animal?` → not vegan).
- **Minimum rating** — a simple `ratings >= :min_rating` threshold.

## Alternatives considered

- **No filters** — leaves obvious, present data (time, rating) unused.
- **A dietary metadata field** — doesn't exist in the dataset; deriving from ingredients
  is the only option without new data.
- **An LLM/offline tagging pass for diet** — heavier; the curated token lists are good
  enough for a prototype and stay deterministic.

## Consequences

- Filters compose cleanly as predicates; no new query or infrastructure.
- **Trade-off:** diet derivation is heuristic — token lists miss edge cases (e.g. hidden
  animal derivatives, gelatin in candy). Honest, documented, and easy to extend.
- Time-based filtering is the strongest *unbuilt* extension (97% of recipes have a usable
  total time) and is the recommended next filter.
