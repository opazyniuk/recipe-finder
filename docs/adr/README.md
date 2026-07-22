# Architecture Decision Records

The significant decisions behind the **"It's dinner time"** recipe finder, in the
lightweight [Michael Nygard ADR](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
format.

Each record captures one decision: the **context** (the forces at play), the
**decision**, the **alternatives** weighed, and the **consequences** — including
trade-offs and *what would change the call at scale*. They're deliberately short,
roughly one screen each.

Recorded retroactively from the build notes (June 2026) — the structured, defensible
index of the decisions made while building.

## Status legend

- **Accepted** — in force.
- **Deferred** — deliberately *not* shipped now; groundwork kept, re-add path documented.
- **Superseded by NNNN** — replaced by a later ADR.

## Index

| # | Decision | Status |
|---|----------|--------|
| [0001](0001-canonical-relational-ingredient-model.md) | Canonical relational ingredient model | Accepted |
| [0002](0002-deterministic-parser-no-llm.md) | Deterministic ingredient parser, no LLM in the hot path | Accepted |
| [0003](0003-coverage-ranking-buckets.md) | Rank by ingredient coverage into "cook now" / "almost there" | Accepted |
| [0004](0004-target-user-cook-now.md) | Target user: "cook now with what's on hand" | Accepted |
| [0005](0005-pantry-staples-assumed-on-hand.md) | Treat pantry staples as assumed on-hand | Accepted |
| [0006](0006-single-tuned-search-query.md) | One structurally-tuned SQL query for search (142→13 ms) | Accepted |
| [0007](0007-trigram-gin-autocomplete.md) | Trigram GIN for typo-tolerant ingredient autocomplete | Accepted |
| [0008](0008-rails-api-react-spa.md) | Rails JSON API + React SPA, single-origin deploy | Accepted |
| [0009](0009-jbuilder-serialization.md) | jbuilder views for JSON serialization | Accepted |
| [0010](0010-service-and-value-objects.md) | Service objects + immutable value objects (`Data.define`) | Accepted |
| [0011](0011-idempotent-import-pipeline.md) | Idempotent single-source import pipeline | Accepted |
| [0012](0012-prototype-not-built-to-scale.md) | Ship as a prototype; document the scale path | Accepted |
| [0013](0013-load-more-pagination.md) | "Load more" pagination, not numbered pages | Accepted |
| [0014](0014-derived-difficulty-diet-filters.md) | Derived difficulty & diet filters | Accepted |
| [0015](0015-cuisine-filter-deferred.md) | Cuisine filter deferred — data not ready | Deferred |
| [0016](0016-curated-diet-lists-over-open-food-facts.md) | Curated diet lists over an Open Food Facts lookup | Accepted |
| [0017](0017-curated-ukrainian-recipes.md) | Seed curated Ukrainian recipes to exercise the cuisine facet | Accepted |

## Adding a new ADR

Copy `0000-template.md` to `NNNN-short-title.md`, fill it in, add a row above. Don't
edit an accepted ADR's decision — **supersede** it with a new ADR and link back, so the
history of *why* stays intact.
