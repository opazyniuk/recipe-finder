# 0015. Cuisine filter deferred — data not ready

- **Status:** Deferred
- **Date:** 2026-06-23

## Context

A cuisine filter (Italian / Mexican / …) is an obvious feature. But the dataset has no
cuisine field (`cuisine` is 100% empty), so it can only be **derived**. The first
derivation — `Recipes::Classifier.cuisine_for` matching a literal `"<Cuisine> Recipes"`
in the category text — tags only **644 / 10,013 recipes (6.4%)**. Crossed with the pantry
intersection and the `missing ≤ 2` cutoff, a realistic 14-ingredient pantry surfaces ~1
cuisine-tagged recipe out of 60+ reachable — so almost every cuisine selection returned
zero results.

## Decision

**Pull the cuisine filter** for now. The filter logic was correct; there was just
nothing to filter, and a control that near-always empties the results reads as broken —
worse than not shipping it. Removed: the filter UI, the `/recipes/cuisines` endpoint, and
the finder's cuisine predicate. **Kept as groundwork:** the `cuisine` column, the
classifier, and the per-recipe `cuisine` — now **shown as a badge** where present (display-only, never a filter).

## Alternatives considered

- **Ship it anyway** — most selections return empty; bad UX, reads as a bug.
- **Faceted-only (offer only reachable cuisines)** — better, but pointless at 6.4%
  coverage; revisit once coverage is high.

## Consequences

- No broken-feeling control in the UI; the groundwork stays so re-adding is cheap.
- **What would change this (re-add path):** lift coverage by inferring cuisine from title
  + signature ingredients (taco/salsa → Mexican, curry/garam masala → Indian,
  miso/teriyaki → Japanese) instead of category text alone — then re-add the filter,
  ideally **faceted** so no pick is ever empty (offer only cuisines reachable from the
  current pantry).
- A deliberate "judgment under data constraints" call — surfaced openly rather than
  hidden.
