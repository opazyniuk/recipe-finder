# 0001. Canonical relational ingredient model

- **Status:** Accepted
- **Date:** 2026-06-23

## Context

The dataset is 10,013 recipes whose ingredients are **free-text scraped lines** like
`"1 (8 ounce) package cream cheese, softened"` — ~96k lines total. The core feature is
matching a recipe's ingredients against a user's pantry and counting what's missing.
Matching on raw strings is unreliable: the same ingredient appears in dozens of surface
forms, and substring matching over-matches ("cream" hits cream cheese, sour cream, ice
cream). A relational model is the natural fit.

## Decision

Normalize every line to a **canonical ingredient name** (see [0002](0002-deterministic-parser-no-llm.md))
and store a three-table relational model: `recipes`, `ingredients` (unique by `name`),
and a `recipe_ingredients` join carrying `raw_text`, parsed `quantity`/`unit`, and
`position`. Matching is then exact set-membership on ingredient **ids**.

## Alternatives considered

- **Raw ingredient strings on the recipe** — no dedup, no clean autocomplete, and
  matching degrades to fuzzy string compare. Rejected.
- **JSONB array of ingredients per recipe** — loses the join, can't index ingredient
  popularity, and gives up clean set-matching. Rejected.
- **Full-text search over raw lines** — over-matches and produces thousands of noisy
  pseudo-ingredients; can't compute an accurate missing-count. Rejected.

## Consequences

- Exact, id-based set matching; clean autocomplete; per-ingredient popularity via a
  counter cache; a clean relational model.
- `raw_text` + parsed `quantity`/`unit` are retained for display and for future
  quantity-aware matching at zero query cost.
- **Trade-off:** correctness now depends on normalization quality. The long tail is
  imperfect (4,742 of 6,947 ingredients are hapax) — accepted and documented, see
  [0002](0002-deterministic-parser-no-llm.md).
- The join is cheap at 10k/93k rows. At millions of recipes this becomes the thing to
  denormalize (per-recipe coverage structures / inverted index) — see [0012](0012-prototype-not-built-to-scale.md).
