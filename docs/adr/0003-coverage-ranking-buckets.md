# 0003. Rank by ingredient coverage into "cook now" / "almost there"

- **Status:** Accepted
- **Date:** 2026-06-23

## Context

"Find the most relevant recipes you can prepare with what you have" needs a concrete
ranking objective. A strict "you must have every ingredient" filter is too harsh —
nearly every recipe needs salt, so strict-subset matching returns almost nothing
(salt alone is in ~36% of recipes).

## Decision

Rank candidate recipes by **how few ingredients are missing**, and split results into
two buckets: **Cook now** (missing 0) and **Almost there** (missing 1–2, named so the
user can decide). Recipes missing more than 2 are cut (`MAX_MISSING = 2`). Within the
buckets, sort lexicographically: `missing_count ASC → coverage DESC → rating DESC →
fewer total ingredients → id`. "Relevant" = closest to cookable now, quality as a
tiebreak.

## Alternatives considered

- **Strict subset (have ALL)** — collapses to near-empty results because of staples.
  Addressed instead by [0005](0005-pantry-staples-assumed-on-hand.md) + the soft cutoff.
- **Any-match / OR** — returns too much, unranked by cookability.
- **Rating-only ranking** — ignores the entire point (what *you* can cook).

## Consequences

- Directly answers the "dinner tonight" framing; the named 1–2-missing bucket adds
  utility without drifting into shopping-list territory (see [0004](0004-target-user-cook-now.md)).
- `MAX_MISSING` is a single tunable constant; the bucket split is a runtime `partition`
  on `missing_count`.
- The `missing ≤ 2` cutoff also prunes the candidate set hard, which keeps the search
  query and its pagination cheap (see [0006](0006-single-tuned-search-query.md),
  [0013](0013-load-more-pagination.md)).
- **Trade-off:** the cutoff and weights are product judgments, not learned. Fine for a
  prototype; a real product would A/B the weights and the threshold.
