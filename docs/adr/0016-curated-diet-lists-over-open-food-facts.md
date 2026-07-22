# 0016. Curated diet lists over an Open Food Facts lookup

- **Status:** Accepted
- **Date:** 2026-06-23

## Context

Diet filters ([0014](0014-derived-difficulty-diet-filters.md)) derive vegetarian/vegan
from the ingredient set via `Recipes::Classifier` — a substring token scan against
curated `MEAT` / `DAIRY_EGG` / `PLANT` lists (`meat?` → not vegetarian, `animal?` → not
vegan). Hand-maintained word lists look unprincipled, so we evaluated replacing them with
[Open Food Facts](https://world.openfoodfacts.org)' ingredients taxonomy (ODbL), which
carries `vegan` / `vegetarian` properties (`yes` / `no` / `maybe`) per ingredient.

Inspection surfaced two facts:

- OFF's flags are **hierarchical and sparse** — only ~889 of 6,100 nodes carry an
  explicit flag; `chicken` has none and inherits from `poultry → animal`. Usable
  classification requires resolving inheritance up the parent graph (tractable: the
  resolved map is ~4,500 entries / ~240 KB).
- The hard part is matching: our ingredient names are normalized but messy, OFF keys are
  clean canonicals.

So we **measured** OFF's coverage against the 7,103 real ingredients in the database
before committing to anything.

## Decision

Keep the keyword substring-scan; do **not** integrate OFF as a runtime lookup. The
curated lists stay the source of truth for `meat?` / `animal?`.

## Alternatives considered

- **OFF lookup (primary) + keyword fallback** — rejected on data. OFF exact-matched only
  **674 / 7,103 (9.5%)** of our ingredients; the keyword scan classified 1,628 of the
  remaining misses as meat/animal. Recipe lines are free-text (`"beef chuck pot roast"`,
  `"salmon fillet skin removed"`); OFF keys are canonicals (`"beef"`, `"salmon"`). Exact
  match fails ~90% of the time; the substring scan works because it finds the indicator
  *inside* the phrase. OFF would carry <10% while the disliked lists still did the work —
  the worst of both: more dependency, same lists.
- **OFF-only + conservative default** — drops the lists, but with a 9.5% match rate the
  other ~90% default to "assume animal," making the diet filters badly over-restrictive.
- **Re-source the token lists from OFF** — viable but marginal: the high-frequency
  indicators (`beef`, `sausage`, `cheese`, `salmon`, `cod`) are already covered; OFF adds
  mostly long-tail tokens, at the cost of token extraction + ambiguity handling
  (`milk` in `cow's milk` vs `coconut milk`).

## Consequences

- Zero runtime dependency, deterministic, and effective on the messy free-text the
  dataset actually contains — validated by measurement, not assumed.
- **Trade-off:** classification stays heuristic — long-tail items and hidden derivatives
  slip through (already noted in [0014](0014-derived-difficulty-diet-filters.md)). The
  lists are hand-curated, but the data shows that is the *right* tool for free-text
  ingredients here, not a shortcut.
- **What would change this call:** a canonicalized ingredient catalog (clean names rather
  than recipe free-text) would make OFF exact-lookup viable; or if diet correctness became
  safety-critical, invest in OFF-sourced tokens + curation. OFF stays a useful reference
  to *audit and expand* the curated lists against — it just can't replace the scan.
