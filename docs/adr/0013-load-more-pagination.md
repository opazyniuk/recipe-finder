# 0013. "Load more" pagination, not numbered pages

- **Status:** Accepted
- **Date:** 2026-06-23

## Context

The search result isn't a flat list — it's two ranked buckets (cook-now / almost) over a
relevance-ranked feed with no meaningful total count. "Page 3 of N" doesn't map onto
that.

## Decision

Use **append-style "load more"**. The search returns `has_more` via a cheap lookahead —
fetch `per_page + 1`, flag the extra — rather than computing a total. The client uses
`useInfiniteQuery` and appends. It stays coherent because the sort leads with
`missing_count ASC`: all cook-now rows are globally contiguous at the front, so appended
pages never interleave a cook-now row behind an almost row — "load more" only ever grows
the bottom.

## Alternatives considered

- **Numbered pages + total count** — needs a second `COUNT(*)` over the grouped set, and
  "page N of M" is meaningless for a two-bucket relevance feed.
- **No pagination** — fine for tiny pantries, breaks for popular ingredients that match
  thousands of recipes.

## Consequences

- No extra count query; `has_more` is effectively free.
- Matches the UX (infinite-scroll-style "show me more cookable recipes").
- **Trade-off:** offset pagination (`(page-1) * per_page`) — but the `missing ≤ 2`
  cutoff ([0003](0003-coverage-ranking-buckets.md)) prunes the set hard enough that
  offsets stay shallow. What would change this: a result-set large enough to warrant
  jump-to-page (add a count + numbered pages) or deep offsets at scale (switch to keyset
  pagination on the sort tuple).
