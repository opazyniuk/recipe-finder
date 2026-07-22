# 🍳 It's dinner time

**Tell the app what's in your kitchen — it finds the recipes you can actually cook tonight.**

A full-stack recipe finder built around a real data problem. The interesting part isn't CRUD — it's
turning **96k lines of messy, free-text scraped ingredients** into something matchable, then **ranking**
10k recipes by how cookable they are with what you already have.

🔗 **Live demo:** https://opazyniuk-dinner-production.up.railway.app
📦 **Stack:** Ruby on Rails 8 (JSON API) · PostgreSQL · React + Vite + TypeScript

---

## What it does

You build a **pantry** (the ingredients you have), and the app answers _"what can I make right now?"_:

- **Cook now** — recipes you have every ingredient for.
- **Almost there** — recipes you're missing only 1–2 ingredients for (named, so you can decide).
- **Filters** — difficulty, diet (vegetarian/vegan), and minimum rating.
- **Staples toggle** — assume you have salt/pepper/oil/water/butter (more on _why_ below).

### A well-thought user experience

The focus is on **flow and clarity**, not
decoration:

- **Guided empty state** — with no pantry yet, popular-ingredient chips get you cooking in one tap.
- **The "almost there" decision** — each near-miss _names_ what's missing (_"Just 1 more: butter"_), framing a
  worth-a-quick-shop decision rather than a yes/no match.
- **The data insight, surfaced in the UI** — the staples toggle says _why_ it exists ("salt alone is in ~a third
  of recipes"), so the assumption is transparent, not magic.
- **Every state handled** — loading skeletons, an explicit "Updating…", empty/no-results guidance, and error
  states with one-tap retry, on both screens.
- **Forgiving input** — debounced fuzzy search (`"chiken"` → `"chicken"`), Enter to add the top match,
  popularity-ranked suggestions.
- **Mobile-first & accessible** — responsive grid, no hover-only affordances, `aria` labels and keyboard
  support; the pantry persists in `localStorage`, so there's no account friction.

## User stories

1. **As a home cook with a random fridge,** I add the ingredients I have and instantly see recipes I can
   cook **right now**, so I skip the grocery trip.
2. **As a home cook who doesn't mind a quick shop,** I see recipes I'm **missing only 1–2 ingredients**
   for — with the missing items named — so I can decide whether it's worth a run to the store.
3. **As a home cook with a preference tonight,** I narrow by **difficulty / diet / rating** and
   open a recipe to see exactly **what I have vs. what I need**, so I can start cooking with confidence.

---

## Quickstart

**Prerequisites:** Ruby (see `.ruby-version`), Node 20+, PostgreSQL running locally.

```bash
# 1. Backend
bundle install
bin/rails db:create db:migrate
bin/rails recipes:seed          # seeds ~10k recipes from the bundled dataset in ~10s
bin/rails server                # http://localhost:3000

# 2. Frontend (separate terminal)
cd client
npm install
npm run dev                     # http://localhost:5173  (proxies /api → Rails)
```

Open **http://localhost:5173**. If port 3000 is taken, run Rails on another port and point the proxy at it:
`VITE_API_TARGET=http://localhost:3100 npm run dev`.

```bash
bundle exec rspec               # backend test suite (~170 examples)
```

---

## How it works

```
React SPA (Vite/TS)  ──/api──▶  Rails 8 API  ──SQL──▶  PostgreSQL (pg_trgm)
TanStack Query, Router          thin controllers       recipes · ingredients ·
Tailwind, localStorage          service objects         recipe_ingredients
                                jbuilder views          (canonical, normalized)
  dev:  Vite proxies /api → Rails (no CORS)
  prod: the SPA is built into Rails' public/ → one origin, one deploy artifact
```

The whole app is one idea applied twice: **turn messy text into a stable ingredient identity, then compare
sets of it** — once offline at seed, once live per request.

### 1 · Parse the source data into a matchable model — `Ingredients::Parser`

The dataset is 10k recipes whose ingredients are free-text lines (`"1 (8 ounce) package cream cheese,
softened"`) — impossible to match on directly. The parser distils **one raw line → one canonical ingredient
name**, deterministically (no LLM): it strips the quantity, unit, parenthetical and prep notes, fixes
singulars, and collapses variety/seasoning noise — `"2 russet potatoes, peeled"` → `"potato"`,
`"salt and freshly ground black pepper"` → `"salt and pepper"` (quantity/unit are kept aside for display).
The behaviour is pinned by table-driven specs against real dataset lines.

Those names are then **deduplicated into one `ingredients` table** — each distinct ingredient is a single
row with a stable **id** — and every recipe is linked to its ingredients through a join table
(`Recipes::Importer` does this bulk-load in one streamed, batched pass; counter-caches recomputed; no N+1).
The payoff: a recipe is no longer a bag of strings but a **set of ingredient ids**, which turns "what do I
have / what am I missing" into an exact, indexable set operation rather than fuzzy text search.

### 2 · Turn what the user types into the same ids — `Ingredients::Search`

The user's input has to land on the _same_ canonical ids the recipes were normalised to. Autocomplete is
that bridge: prefix matches first, then `pg_trgm` fuzzy matches so `"chiken"` resolves to `"chicken"`,
ranked by popularity. The user picks a suggestion and the app holds an **id, not a string**. Fuzziness lives
here — where it _helps_ a human find the right ingredient — and deliberately never reaches matching, where
it would corrupt the missing-count.

### 3 · Remember the pantry — `Pantry` + `localStorage`

Picked ids accumulate into a **pantry**: persisted client-side in `localStorage` (survives refresh, no
account, no sign-up friction) and, on the server, wrapped in a `Pantry` value object that knows the
_effective_ set — your selected ids, plus the assumed staples when that toggle is on. The pantry is the
user's half of the comparison.

### 4 · Find recipes by ingredients — `Recipes::Finder`

Given the pantry, **one SQL query** answers the whole question. For each candidate recipe (one that uses at
least one of your ingredients) it counts what you **have** (intersection with the pantry's ids), derives
what you're **missing** (`total − have`, with `total` read from a counter cache rather than a join), names
the missing items, applies the active filters, and keeps only recipes missing **≤ 2**. One round-trip, no
per-recipe queries.

### The ranking, in words

Candidates are recipes that contain at least one of your ingredients. They're ranked **fewest missing →
best coverage → highest rating → simplest recipe**, and only those missing **≤ 2** are shown (that's the
"cook now / almost there" split). Staples, when assumed, count as ingredients you _have_.

---

## Key design decisions & trade-offs

| Decision | Why | Trade-off / what I rejected |
|---|---|---|
| **Canonical `ingredients` + join table**, matched on IDs | Accurate set-matching + clean autocomplete on a normalized relational model | Imperfect long-tail normalization. Rejected raw-text `ILIKE`/JSONB/FTS (over-matches "cream" → cream cheese, sour cream, ice cream). |
| **Coverage ranking + "cook now / almost there" + staples** | Directly answers _"what can I make tonight"_ | Rejected strict-subset matching — with **salt in 38% of recipes**, it hides nearly everything. |
| **One EXPLAIN-tuned SQL query for ranking** (`Recipes::Finder`) | Counter-cache for `total`, an indexed scan over only the pantry's rows for `have`, an early `missing ≤ 2` cutoff, and missing-names deferred to the returned page → **~12 ms** on 10k recipes, ~3× a naive `GROUP BY` warm-cached (far more on a cold one), one round-trip, no N+1 ([EXPLAIN proof](docs/performance.md)) | More complex than a flat `GROUP BY` (two CTEs + a correlated subquery). Rejected the tempting index on `total_time` — the planner ignores it (residual filter, not an access path). |
| **Deterministic core (SQL + parser), no LLM** | Fast, testable, explainable, free | An LLM in the hot path is brittle/costly/non-deterministic. It _would_ fit offline (synonym clustering at seed) — documented as next-step, not built. |
| **Enrichment at seed, filter at query** | Classify once (diet/cuisine), then filter is a cheap `WHERE` on indexed columns | More to compute at seed; data only supports cuisine partially (see below). |
| **Rails API + React SPA, single artifact** | A mainstream Rails/React stack; one origin, one deploy, no CORS | Styling kept deliberately light; the effort went into UX **flow** — states, the named-missing affordance, the data-insight-in-UI. |
| **jbuilder for serialization** | Rails-native, view-template separation | (Works in `--api` mode by forcing `request.format = :json`.) |

📑 **Full decision records** — every decision above, with the alternatives weighed and the consequences, is recorded as an ADR in **[`docs/adr/`](docs/adr/)** (16 records, [indexed here](docs/adr/README.md)).

## Data analysis (this drove the design)

I profiled the dataset before writing matching logic — the decisions fall out of the data:

- **10,013 recipes → 7,101 canonical ingredients → 93,996 links** (seeded in ~10s). Ingredients are
  free-text with unicode fractions, units, parentheticals and prep-notes.
- **Salt appears in 38% of recipes**; the top ingredients are nearly all staples (oil, butter, water,
  flour, eggs…). → Without the **staples assumption, almost nothing is "cookable"** — that's why the
  toggle exists, and it's on by default.
- **4,230 of 7,101 ingredients appear once** (long tail). → I clean the common cases well and
  **document the tail** rather than chase diminishing returns.
- **Parser coverage: 99.83%** — 96,257 of 96,417 raw ingredient lines resolve to a canonical name; the
  **160 dropped (0.17%)** cluster into a few explainable cases (`ground cloves` collides with the `clove`
  _unit_; `fresh or frozen blueberries` is truncated at `or`). I don't claim a _correctness_ percentage —
  there's no labelled ground-truth — so the parser is pinned by table-driven specs on real lines and output
  profiling, not a single number (see [ADR 0002](docs/adr/0002-deterministic-parser-no-llm.md)).
- **Diet derives cleanly from the canonical ingredients** we already have: ~55% of recipes are
  vegetarian, ~15% vegan.
- **Cuisine does not** — the source's `cuisine` is **empty (0/10,013)**, ~6% carry a cuisine-like `category`,
  and it has no Ukrainian dishes. So I **seeded 18 curated Ukrainian recipes** (Borscht, Varenyky, Holubtsi… —
  dishes from my country's kitchen) through the same pipeline — proof the model handles a non-US cuisine. Shown as a
  **badge** where present; the _filter_ stays deferred ([ADR 0015](docs/adr/0015-cuisine-filter-deferred.md)).

---

## Testing

The hardest logic is the parser and the ranking, so that's where the tests are:

- **`Ingredients::Parser`** — table-driven against real, messy dataset lines (the safety net that makes
  normalizing 96k lines trustworthy).
- **`Recipes::Classifier`** — meat/animal/cuisine classification, including the tricky cases
  (`coconut milk`/`peanut butter` are vegan-safe; `eggplant` ≠ egg; `French Bread` ≠ French cuisine).
- **`Recipes::Finder` + request specs** — buckets, staples, every filter, pagination, and the API contract.
- **Frontend E2E** (`client/e2e/`) — one Playwright spec drives the whole pantry flow in a real browser
  (empty state → add ingredient → cook-now/almost buckets → staples toggle → recipe detail → reload
  persistence), with the API mocked so it runs without a backend.

```bash
bundle exec rspec               # backend: ~170 examples
cd client && npm run e2e        # frontend: Playwright happy-path
```

## Project structure

```
app/
  controllers/api/v1/   thin controllers (search, show, autocomplete)
  services/
    ingredients/        parser, search
    recipes/            importer, classifier, finder (+ difficulty, diet, match, result)
  views/api/v1/         jbuilder JSON
client/src/             React SPA (pages, components, hooks, typed api client)
spec/                   RSpec (services + requests)
```

---

## AI usage

I used **Claude Code (Claude Opus)** as an assistant, not a
replacement for understanding:

- **Dataset analysis** — profiling the 10k recipes (field coverage, the salt-38% / long-tail / cuisine-0%
  findings) to ground the design in the data.
- **Approach research** — surveying common recipe-matching approaches to learn which ones fail
  (raw-text matching, strict-subset, rank-by-rating, N+1 seeds) and deliberately avoiding them.
- **Prototyping the ingredient parser** — iterating on the normalization pipeline, then porting it to Ruby.
- **Scaffolding & tests** — boilerplate (Rails/Vite setup, migrations) and table-driven test fixtures.

**How I validated it:** I read every line I kept, drove the parser and classifier with **table-driven
specs against real dataset lines** (which is how I caught e.g. ActiveSupport mis-singularizing
`"pasta" → "pastum"` and `"cloves" → "clofe"`), and manually verified the ranking and the diet/cuisine
enrichment against the live data.

## Known limitations & what's next

Owned honestly:

- **Cuisine is thin in the source** (~6%; no Ukrainian) — so I **seeded 18 curated Ukrainian recipes** to
  exercise the facet, but kept the _filter_ deferred ([ADR 0015](docs/adr/0015-cuisine-filter-deferred.md)).
  Next: infer cuisine from title + signature ingredients, then re-add it faceted.
- **No synonym resolution** — `scallion` ≠ `green onion`, `all-purpose flour` ≠ `flour`. Next: a curated
  synonym table or an offline clustering pass (a clean place for an LLM, off the hot path).
- **Variety collapse is only a proof-of-concept** — `Ingredients::Parser::VarietyCollapser` folds variety
  modifiers into the base ingredient (`baking potato` → `potato`, `cremini mushroom` → `mushroom`), but
  covers just a hand-listed three (potato, mushroom, tomato). Next: broaden the products and source the
  variety→base groups from an ingredient taxonomy's hierarchy (`cremini`'s parent is `mushroom`) instead of
  the curated `GROUPS` constant.
- **Singularization is hand-rolled** — ActiveSupport's `.singularize` mangles food words (`pasta` → `pastum`,
  `cloves` → `clofe`) and Rails keeps it that way for legacy compatibility, so `singularize_token`
  conservatively strips only clear English endings. It still misses irregulars (`leaves` → `leave`) and an
  unknown trailing prep word can defeat variety-collapse (`russet potato scrubbed` stays apart from `potato`).
  Next: a dictionary-grounded lemmatizer (the WordNet-based `lemmatizer` gem) at seed — real singulars,
  handles irregulars; the heavy WordNet dependency was deliberately skipped for a prototype.
- **All ingredients weigh the same** — missing a garnish penalizes a recipe as much as missing the main
  protein, so a cookable dish can land in _almost_ instead of _cook now_. Next: classify **core vs.
  incidental** at seed from signals already on hand (`position`, quantity/unit like _"a pinch"/"to taste"_,
  the _"for garnish"/optional_ notes the parser already strips, title matches), then weight coverage and
  relax `missing ≤ 2` for incidental items.
- **Diet classifier is a heuristic** — hidden animal products (Worcestershire = anchovy, marshmallow =
  gelatin, parmesan's rennet) slip through. Documented, not chased, for a prototype. A ready-made library
  does exactly this — the [Open Food Facts ingredient taxonomy](https://wiki.openfoodfacts.org/Taxonomy_Properties)
  carries per-ingredient `vegan`/`vegetarian` flags (`yes`/`no`/`maybe`) — but measured against our data it
  exact-matched only **9.5%** (674/7,103) of the messy free-text names, so it can't replace the keyword scan
  as-is ([ADR 0016](docs/adr/0016-curated-diet-lists-over-open-food-facts.md)). Next: a canonicalized
  ingredient catalog (clean names, not recipe free-text) makes the OFF lookup viable; until then OFF serves
  to audit and expand the curated lists, not replace them.
- **Long-tail ingredient noise** can leak into autocomplete (e.g. `"garlic powder to taste"`).
- **Frontend tests are E2E-only** — one Playwright spec covers the core pantry flow; component-level
  Vitest unit tests are the natural next step.

**Product, with user accounts** (today the pantry is intentionally local-only — `localStorage`, no sign-up):

- **Sign-up + saved preferences** — persist diet / difficulty / rating so the filters default to the user's tastes.
- **Cross-device pantry** — sync the pantry server-side instead of `localStorage`, so it follows the user across devices.
- **Cooked history** — record dishes marked as cooked, to power "cook it again" and to nudge variety (de-emphasize recent repeats).

## Deployment

Built as a single artifact: the Vite client is built into Rails' `public/`, and Rails serves both the SPA
and `/api` from one origin (no CORS). Target: Fly.io with managed Postgres; `db:seed` runs once after the
first deploy.
