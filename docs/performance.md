# Search query performance

`Recipes::Finder` answers every search with **one** SQL query. This is the reproducible
`EXPLAIN ANALYZE` proof that it wins by structure, not luck — regenerate with `bin/rails recipes:explain`.

**Scenario:** pantry = the 8 most common non-staple ingredients
(garlic, egg, onion, white sugar, all purpose flour, milk, baking powder, tomato), staples on → 7086 candidate recipes — the worst case.
Absolute ms are machine-dependent; the structural gap is the point.

| Query | Planning | Execution |
|---|---|---|
| Naive single `GROUP BY` | 0.3 ms | **40.3 ms** |
| Tuned `Recipes::Finder` | 0.3 ms | **11.7 ms** |
| | | **~3.4× faster** |

## Why

- **Naive** seq-scans all `recipe_ingredients` and joins every row of every candidate (~72k here),
  groups, sorts, then `HAVING` discards ~97%. On a cold cache or smaller `work_mem` that sort spills
  to disk and the gap widens sharply — the warm figures above are the conservative case.
- **Tuned** takes `total` from the `ingredients_count` counter cache, scans only the pantry's rows
  for `have` (bitmap index), cuts on `missing ≤ 2` before the heavy work, and defers missing-names to
  the returned page — faster despite returning *more* (the names).

## Naive plan

```text
Limit  (cost=6983.24..6983.30 rows=25 width=76) (actual time=40.054..40.058 rows=25 loops=1)
  Buffers: shared hit=3507
  ->  Sort  (cost=6983.24..6991.60 rows=3344 width=76) (actual time=40.054..40.056 rows=25 loops=1)
        Sort Key: ((count(ri.id) - count(ri.id) FILTER (WHERE (ri.ingredient_id = ANY ('{123,6,80,3,1,7,5,742,8,4,23,37,19,122,128,147,210,214,236,435,572,674,1114,31}'::bigint[]))))), (((count(ri.id) FILTER (WHERE (ri.ingredient_id = ANY ('{123,6,80,3,1,7,5,742,8,4,23,37,19,122,128,147,210,214,236,435,572,674,1114,31}'::bigint[]))))::double precision / (NULLIF(count(ri.id), 0))::double precision)) DESC, r.ratings DESC NULLS LAST, (count(ri.id)), r.id
        Sort Method: top-N heapsort  Memory: 30kB
        Buffers: shared hit=3507
        ->  HashAggregate  (cost=6696.61..6888.88 rows=3344 width=76) (actual time=39.357..39.924 rows=595 loops=1)
              Group Key: r.id
              Filter: ((count(ri.id) - count(ri.id) FILTER (WHERE (ri.ingredient_id = ANY ('{123,6,80,3,1,7,5,742,8,4,23,37,19,122,128,147,210,214,236,435,572,674,1114,31}'::bigint[])))) <= 2)
              Batches: 1  Memory Usage: 1425kB
              Rows Removed by Filter: 6491
              Buffers: shared hit=3507
              ->  Hash Join  (cost=3058.81..5789.40 rows=72572 width=60) (actual time=6.887..29.701 rows=72444 loops=1)
                    Hash Cond: (recipe_ingredients.recipe_id = r.id)
                    Buffers: shared hit=3507
                    ->  Hash Join  (cost=2038.11..4573.41 rows=74366 width=32) (actual time=4.758..19.003 rows=72444 loops=1)
                          Hash Cond: (ri.recipe_id = recipe_ingredients.recipe_id)
                          Buffers: shared hit=2712
                          ->  Seq Scan on recipe_ingredients ri  (cost=0.00..2288.14 rows=94114 width=24) (actual time=0.017..3.364 rows=94114 loops=1)
                                Buffers: shared hit=1347
                          ->  Hash  (cost=1941.43..1941.43 rows=7735 width=8) (actual time=4.721..4.722 rows=7086 loops=1)
                                Buckets: 8192  Batches: 1  Memory Usage: 341kB
                                Buffers: shared hit=1365
                                ->  HashAggregate  (cost=1864.08..1941.43 rows=7735 width=8) (actual time=3.854..4.264 rows=7086 loops=1)
                                      Group Key: recipe_ingredients.recipe_id
                                      Batches: 1  Memory Usage: 913kB
                                      Buffers: shared hit=1365
                                      ->  Bitmap Heap Scan on recipe_ingredients  (cost=199.65..1828.81 rows=14108 width=8) (actual time=0.560..2.251 rows=14022 loops=1)
                                            Recheck Cond: (ingredient_id = ANY ('{123,6,80,3,1,7,5,742}'::bigint[]))
                                            Heap Blocks: exact=1346
                                            Buffers: shared hit=1365
                                            ->  Bitmap Index Scan on index_recipe_ingredients_on_ingredient_id  (cost=0.00..196.12 rows=14108 width=0) (actual time=0.451..0.451 rows=14022 loops=1)
                                                  Index Cond: (ingredient_id = ANY ('{123,6,80,3,1,7,5,742}'::bigint[]))
                                                  Buffers: shared hit=19
                    ->  Hash  (cost=895.31..895.31 rows=10031 width=44) (actual time=2.110..2.111 rows=10031 loops=1)
                          Buckets: 16384  Batches: 1  Memory Usage: 908kB
                          Buffers: shared hit=795
                          ->  Seq Scan on recipes r  (cost=0.00..895.31 rows=10031 width=44) (actual time=0.089..1.040 rows=10031 loops=1)
                                Buffers: shared hit=795
Planning:
  Buffers: shared hit=12
Planning Time: 0.281 ms
Execution Time: 40.254 ms
```

## Tuned plan

```text
Subquery Scan on ranked  (cost=3892.24..5956.69 rows=25 width=229) (actual time=11.600..11.678 rows=25 loops=1)
  Buffers: shared hit=2272
  ->  Limit  (cost=3892.24..3892.30 rows=25 width=197) (actual time=11.570..11.573 rows=25 loops=1)
        Buffers: shared hit=2195
        ->  Sort  (cost=3892.24..3894.89 rows=1061 width=197) (actual time=11.569..11.571 rows=25 loops=1)
              Sort Key: ((r.ingredients_count - pc.have_count)), (((pc.have_count)::double precision / (NULLIF(r.ingredients_count, 0))::double precision)) DESC, r.ratings DESC NULLS LAST, r.ingredients_count, r.id
              Sort Method: top-N heapsort  Memory: 35kB
              Buffers: shared hit=2195
              ->  Hash Join  (cost=2916.78..3862.30 rows=1061 width=197) (actual time=9.648..11.362 rows=595 loops=1)
                    Hash Cond: (r.id = pc.recipe_id)
                    Join Filter: ((r.ingredients_count - pc.have_count) <= 2)
                    Rows Removed by Join Filter: 6491
                    Buffers: shared hit=2195
                    ->  Seq Scan on recipes r  (cost=0.00..895.31 rows=10031 width=141) (actual time=0.082..0.474 rows=10031 loops=1)
                          Buffers: shared hit=795
                    ->  Hash  (cost=2877.01..2877.01 rows=3182 width=16) (actual time=9.546..9.547 rows=7086 loops=1)
                          Buckets: 8192 (originally 4096)  Batches: 1 (originally 1)  Memory Usage: 397kB
                          Buffers: shared hit=1400
                          ->  Subquery Scan on pc  (cost=2725.87..2877.01 rows=3182 width=16) (actual time=8.116..9.109 rows=7086 loops=1)
                                Buffers: shared hit=1400
                                ->  HashAggregate  (cost=2725.87..2845.19 rows=3182 width=24) (actual time=8.116..8.764 rows=7086 loops=1)
                                      Group Key: recipe_ingredients.recipe_id
                                      Filter: (count(*) FILTER (WHERE (recipe_ingredients.ingredient_id = ANY ('{123,6,80,3,1,7,5,742}'::bigint[]))) > 0)
                                      Batches: 1  Memory Usage: 1169kB
                                      Rows Removed by Filter: 1980
                                      Buffers: shared hit=1400
                                      ->  Bitmap Heap Scan on recipe_ingredients  (cost=403.58..2200.72 rows=30009 width=16) (actual time=0.750..3.454 rows=30134 loops=1)
                                            Recheck Cond: (ingredient_id = ANY ('{123,6,80,3,1,7,5,742,8,4,23,37,19,122,128,147,210,214,236,435,572,674,1114,31}'::bigint[]))
                                            Heap Blocks: exact=1347
                                            Buffers: shared hit=1400
                                            ->  Bitmap Index Scan on index_recipe_ingredients_on_ingredient_id  (cost=0.00..396.02 rows=30009 width=0) (actual time=0.650..0.650 rows=30134 loops=1)
                                                  Index Cond: (ingredient_id = ANY ('{123,6,80,3,1,7,5,742,8,4,23,37,19,122,128,147,210,214,236,435,572,674,1114,31}'::bigint[]))
                                                  Buffers: shared hit=53
  SubPlan 1
    ->  Aggregate  (cost=82.57..82.58 rows=1 width=32) (actual time=0.004..0.004 rows=1 loops=25)
          Buffers: shared hit=77
          ->  Sort  (cost=82.53..82.55 rows=7 width=24) (actual time=0.004..0.004 rows=0 loops=25)
                Sort Key: ri."position"
                Sort Method: quicksort  Memory: 25kB
                Buffers: shared hit=77
                ->  Nested Loop  (cost=0.64..82.43 rows=7 width=24) (actual time=0.003..0.003 rows=0 loops=25)
                      Buffers: shared hit=77
                      ->  Index Scan using index_recipe_ingredients_on_recipe_id_and_ingredient_id on recipe_ingredients ri  (cost=0.35..24.33 rows=7 width=12) (actual time=0.003..0.003 rows=0 loops=25)
                            Index Cond: (recipe_id = ranked.id)
                            Filter: (ingredient_id <> ALL ('{123,6,80,3,1,7,5,742,8,4,23,37,19,122,128,147,210,214,236,435,572,674,1114,31}'::bigint[]))
                            Rows Removed by Filter: 5
                            Buffers: shared hit=77
                      ->  Index Scan using ingredients_pkey on ingredients i  (cost=0.28..8.30 rows=1 width=28) (never executed)
                            Index Cond: (id = ri.ingredient_id)
Planning:
  Buffers: shared hit=12
Planning Time: 0.320 ms
Execution Time: 11.746 ms
```
