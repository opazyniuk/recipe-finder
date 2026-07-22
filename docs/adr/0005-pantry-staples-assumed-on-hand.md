# 0005. Treat pantry staples as assumed on-hand

- **Status:** Accepted
- **Date:** 2026-06-23

## Context

Recipes almost always call for salt, pepper, water, oil, butter. If those count as
"missing", nearly every recipe looks 2–3 ingredients short and the fewest-missing
ranking collapses into noise. It's worse than reordering: a genuinely cookable dish can
fall past the `missing ≤ 2` cutoff and **vanish from results entirely** just because the
user never listed "salt". (Profiling: salt alone is in ~36% of recipes.)

## Decision

Maintain a small curated set of universal **staples** (16 canonical ingredients: salt &
pepper variants, water, common oils, butter). `Ingredients::Parser` flags them with
`is_staple` at import; the `Pantry` value object folds staple ids into the user's
"available" set, so they never count as missing. It's a **default-on toggle** ("Assume I
have staples") the user can switch off. Sugar and flour are deliberately *not* staples —
they are recipe-defining.

## Alternatives considered

- **Count everything literally** — the noise problem above; ranking becomes meaningless.
- **Infer staples per user / per session** — no data for it and over-engineered.
- **A larger staples list (sugar, flour, …)** — would hide genuinely recipe-defining
  ingredients and mis-rank baking recipes.

## Consequences

- The fewest-missing ranking becomes meaningful. Verified end-to-end: *Brooklyn Style
  Pizza Dough* with pantry `{yeast, bread flour}` → staples **on**: missing 0 ("cook
  now"); **off**: missing 3, so it drops out entirely.
- Candidate relevance is gated on *selected* ingredients, not staples, so a staple alone
  never makes a recipe relevant (see [0006](0006-single-tuned-search-query.md)).
- Coupled to [0004](0004-target-user-cook-now.md): under persona B this flips — you'd
  *want* salt to surface onto the shopping list.
- **Trade-off:** the staples list is a hand-curated product judgment; the toggle exists
  precisely so the user can override it.
