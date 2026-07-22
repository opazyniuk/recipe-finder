# 0010. Service objects + immutable value objects

- **Status:** Accepted
- **Date:** 2026-06-23

## Context

The real work — parsing, importing, searching, classifying — doesn't belong in
controllers or models. It needs a home that's testable in isolation and reads as domain
logic, not framework glue.

## Decision

Put the work in **domain-namespaced service objects** (`Ingredients::Parser`,
`Ingredients::Search`, `Recipes::Importer`, `Recipes::Finder`, `Recipes::Classifier`)
and model the data they pass around as **immutable value objects via `Data.define`** with
factory methods: the `Pantry` (`app/values/pantry.rb`) encapsulating `selected_ids` /
`available_ids`, and `Recipes::Finder::{Match, Result, Difficulty, Diet}`
(`Match.from_row`, `Result.from_matches`).

## Alternatives considered

- **Fat models / fat controllers** — mixes HTTP and persistence with business logic,
  harder to test, the classic Rails sprawl.
- **Primitive hashes/arrays passed around** — no encapsulation; e.g. the "selected ∪
  staples" rule would be duplicated at every call site instead of living in `Pantry`.

## Consequences

- Each piece is unit-testable in isolation; the controllers stay thin.
- `Pantry` owns the staples-folding rule in one place ([0005](0005-pantry-staples-assumed-on-hand.md)),
  so the finder just binds `:selected` / `:available`.
- `Data.define` gives cheap immutability and value equality without boilerplate.
- **Trade-off:** more small classes/files; justified by the clarity and testability, and
  it scales better than piling logic into `Recipe`/`Ingredient`.
