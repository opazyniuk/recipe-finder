# 0004. Target user: "cook now with what's on hand"

- **Status:** Accepted
- **Date:** 2026-06-23

## Context

The ranking objective depends entirely on *who* the user is. Two readings of the goal
lead to different products: (A) someone cooking **now** with what's already in their
kitchen — missing ingredients are a penalty; or (B) someone planning ahead and
**shopping** for what's missing — missing ingredients are a shopping list, and ranking
would optimize for recipe quality/variety instead. This had to be resolved before the
ranking could be designed.

## Decision

Build for **persona A — cook now**. The product goal settles it directly: help someone
cook dinner with the ingredients they already have at home. That is cook-now, not
plan-and-shop. So missing ingredients are a penalty and we rank by fewest-missing
([0003](0003-coverage-ranking-buckets.md)). It is a documented **decision**, not an open
question — the goal answers it.

## Alternatives considered

- **Persona B — plan & shop** — would flip the objective: treat "missing" as a shopping
  list and rank by quality/variety, not by minimizing the shop. Not the goal here.

## Consequences

- Sets the objective for every downstream decision: the penalty model, the staples
  assumption ([0005](0005-pantry-staples-assumed-on-hand.md)), the bucket cutoff.
- What would change this: an explicit product direction toward meal-planning/shopping,
  at which point persona B's ranking and a shopping-list view become in scope.
