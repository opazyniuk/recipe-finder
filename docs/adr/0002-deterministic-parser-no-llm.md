# 0002. Deterministic ingredient parser, no LLM in the hot path

- **Status:** Accepted
- **Date:** 2026-06-23

## Context

Turning `"1 (8 ounce) package cream cheese, softened"` into the canonical name
`"cream cheese"` (plus best-effort quantity/unit) is the hardest part of the project.
It runs over ~96k lines at import time and must be correct enough that the missing-count
is trustworthy. An LLM is the obvious "smart" tool, but this is a structured-data
problem, not an open-ended NLP one.

## Decision

`Ingredients::Parser` is fully **deterministic** — no model, no network. A fixed
pipeline (`normalize_name`): drop parentheticals *before* the comma split → drop
prep notes after the first comma → strip trailing phrases → remove numbers/units/
sizes/prep stopwords → conservatively singularize survivors → collapse seasonings.
Clean the common cases well; **defer the long tail** rather than chase diminishing
returns. The behaviour is pinned by table-driven specs against real dataset lines.

## Alternatives considered

- **LLM text-to-SQL / LLM normalization in the request path** — brittle, costs per
  call, non-deterministic, untestable. Rejected for the hot path; kept as a documented
  *offline, at-seed* option for synonym clustering (scallion = green onion).
- **`ActiveSupport#singularize`** — corrupts ingredient words (`cloves → clofe` via the
  `-ves` rule; `pasta → pastum` via the Latin `-a` rule). Replaced with a conservative
  `singularize_token` that strips only clear English endings and protects `-ss/-us/-is`.
- **Full text-parsing system / NLP tokenizer** — over-engineered for a prototype.

## Consequences

- Fast, free, explainable, and unit-testable; the parser contract is a real safety net.
- **Measured coverage: 99.83%** (96,257 of 96,417 lines parse; 160 dropped). The drops aren't random —
  they're a few homonym/heuristic edge cases: `clove` is modelled as a *unit* (a clove of garlic), so
  `ground cloves` (the spice) drops; and the `or`-truncation that turns "salt or pepper" → salt also
  truncates "fresh **or** frozen blueberries" / "can **or** bottle beer", where the ingredient sits *after*
  `or`. *Correctness* of parsed names has no labelled ground-truth — validated by specs + profiling, not a number.
- **Trade-off:** the long tail is imperfect — irregular singulars (`molasses → molass`)
  and unresolved synonyms remain. Documented as the headline known limitation.
- What would change this: a defined precision target tied to how matching accuracy is
  evaluated, or an offline LLM/embedding pass to cluster synonyms — cached in the DB so
  the runtime stays deterministic.
