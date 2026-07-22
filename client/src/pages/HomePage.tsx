import { useState, type ReactNode } from 'react'
import { keepPreviousData, useInfiniteQuery, useQuery } from '@tanstack/react-query'
import { popularIngredients, searchRecipes, type Diet, type Difficulty } from '../api'
import { usePantry } from '../hooks/usePantry'
import { PantryBar } from '../components/PantryBar'
import { ResultsSection } from '../components/ResultsSection'
import { SegmentedControl, type Segment } from '../components/SegmentedControl'

const DIFFICULTIES: Segment<Difficulty | null>[] = [
  { value: null, label: 'All' },
  { value: 'easy', label: 'Easy', activeClassName: 'bg-emerald-500 text-white shadow-sm' },
  { value: 'medium', label: 'Medium', activeClassName: 'bg-amber-500 text-white shadow-sm' },
  { value: 'hard', label: 'Hard', activeClassName: 'bg-rose-500 text-white shadow-sm' },
]

const DIETS: Segment<Diet | null>[] = [
  { value: null, label: 'All' },
  { value: 'vegetarian', label: 'Veg', activeClassName: 'bg-green-600 text-white shadow-sm' },
  { value: 'vegan', label: 'Vegan', activeClassName: 'bg-green-700 text-white shadow-sm' },
]

const RATINGS: Segment<number | null>[] = [
  { value: null, label: 'All' },
  { value: 3, label: '3★+', activeClassName: 'bg-amber-500 text-white shadow-sm' },
  { value: 4, label: '4★+', activeClassName: 'bg-amber-500 text-white shadow-sm' },
  { value: 4.5, label: '4.5★+', activeClassName: 'bg-amber-500 text-white shadow-sm' },
]

export function HomePage() {
  const pantry = usePantry()
  const ids = pantry.items.map((i) => i.id)
  const hasPantry = ids.length > 0
  const smallPantry = hasPantry && ids.length <= 2
  const [difficulty, setDifficulty] = useState<Difficulty | null>(null)
  const [diet, setDiet] = useState<Diet | null>(null)
  const [minRating, setMinRating] = useState<number | null>(null)
  const [filtersOpen, setFiltersOpen] = useState(true)

  const filters = { difficulty, diet, minRating }
  const activeCount = [difficulty, diet, minRating].filter((v) => v !== null).length
  const clearFilters = () => {
    setDifficulty(null)
    setDiet(null)
    setMinRating(null)
  }

  const { data, isLoading, isFetching, isFetchingNextPage, hasNextPage, fetchNextPage, isError, refetch } =
    useInfiniteQuery({
      queryKey: ['recipes', ids, pantry.includeStaples, filters],
      queryFn: ({ pageParam }) => searchRecipes(ids, pantry.includeStaples, filters, pageParam),
      enabled: hasPantry,
      initialPageParam: 1,
      getNextPageParam: (lastPage) => (lastPage.has_more ? lastPage.page + 1 : undefined),
      placeholderData: keepPreviousData,
    })

  const cookNow = data?.pages.flatMap((p) => p.cook_now) ?? []
  const almost = data?.pages.flatMap((p) => p.almost) ?? []
  const cookNowTotal = data?.pages[0]?.cook_now_total ?? 0
  const almostTotal = data?.pages[0]?.almost_total ?? 0

  const popular = useQuery({
    queryKey: ['popular'],
    queryFn: popularIngredients,
    enabled: !hasPantry,
  })

  const noResults = hasPantry && data && cookNow.length === 0 && almost.length === 0

  return (
    <div className="mx-auto max-w-5xl px-4 py-6">
      <header className="mb-6 text-center">
        <h1 className="text-3xl font-extrabold tracking-tight text-zinc-900">🍳 It's dinner time</h1>
        <p className="mt-1 text-zinc-500">Tell me what's in your kitchen — I'll find what you can cook tonight.</p>
      </header>

      <PantryBar
        items={pantry.items}
        includeStaples={pantry.includeStaples}
        onAdd={pantry.add}
        onRemove={pantry.remove}
        onClear={pantry.clear}
        onToggleStaples={pantry.setIncludeStaples}
      />

      {hasPantry && (
        <section className="mt-4 rounded-2xl border border-zinc-200 bg-white p-4 shadow-sm">
          <div className="flex items-center justify-between">
            <button
              type="button"
              onClick={() => setFiltersOpen((open) => !open)}
              aria-expanded={filtersOpen}
              className="-m-1 flex items-center gap-2 rounded-lg p-1 text-zinc-700 transition-colors hover:text-zinc-900"
            >
              <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true" className="h-4 w-4 text-zinc-400">
                <path fillRule="evenodd" clipRule="evenodd" d="M3.792 2.938A49.069 49.069 0 0 1 12 2.25c2.797 0 5.54.236 8.209.688a1.857 1.857 0 0 1 1.541 1.836v1.044a3 3 0 0 1-.879 2.121l-6.182 6.182a1.5 1.5 0 0 0-.439 1.061v2.927a3 3 0 0 1-1.658 2.684l-1.757.878A.75.75 0 0 1 9.75 21v-5.818a1.5 1.5 0 0 0-.44-1.06L3.13 7.938a3 3 0 0 1-.879-2.121V4.774c0-.897.64-1.683 1.542-1.836Z" />
              </svg>
              <span className="text-sm font-semibold">Refine</span>
              {activeCount > 0 && (
                <span className="rounded-full bg-emerald-100 px-2 py-0.5 text-xs font-semibold text-emerald-700">
                  {activeCount}
                </span>
              )}
              <svg
                viewBox="0 0 24 24" fill="none" stroke="currentColor" aria-hidden="true"
                className={`h-4 w-4 text-zinc-400 transition-transform ${filtersOpen ? 'rotate-180' : ''}`}
              >
                <path d="m6 9 6 6 6-6" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </button>
            {activeCount > 0 && (
              <button
                type="button"
                onClick={clearFilters}
                className="rounded-full px-2.5 py-1 text-sm text-zinc-500 transition-colors hover:bg-zinc-100 hover:text-zinc-800"
              >
                Clear filters
              </button>
            )}
          </div>

          {filtersOpen && (
            <div className="mt-4 flex flex-wrap gap-x-8 gap-y-4">
              <FilterField label="Difficulty">
                <SegmentedControl<Difficulty | null> ariaLabel="Filter by difficulty" options={DIFFICULTIES} value={difficulty} onChange={setDifficulty} />
              </FilterField>
              <FilterField label="Diet">
                <SegmentedControl<Diet | null> ariaLabel="Filter by diet" options={DIETS} value={diet} onChange={setDiet} />
              </FilterField>
              <FilterField label="Rating">
                <SegmentedControl<number | null> ariaLabel="Filter by minimum rating" options={RATINGS} value={minRating} onChange={setMinRating} />
              </FilterField>
            </div>
          )}
        </section>
      )}

      {isFetching && !isLoading && !isFetchingNextPage && (
        <p className="mt-4 text-center text-sm text-zinc-400">Updating…</p>
      )}

      {!hasPantry && (
        <div className="mt-10 text-center">
          <p className="text-zinc-500">Start by adding a few ingredients. Popular picks:</p>
          <div className="mt-3 flex flex-wrap justify-center gap-2">
            {popular.isLoading
              ? Array.from({ length: 8 }).map((_, i) => (
                  <span key={i} className="h-8 w-24 animate-pulse rounded-full bg-zinc-100" />
                ))
              : (popular.data ?? []).map((ingredient) => (
                  <button
                    key={ingredient.id}
                    type="button"
                    onClick={() => pantry.add(ingredient)}
                    className="rounded-full border border-zinc-300 bg-white px-3 py-1.5 text-sm capitalize text-zinc-700 hover:border-emerald-500 hover:text-emerald-700"
                  >
                    + {ingredient.name}
                  </button>
                ))}
          </div>
          {popular.isError && (
            <p className="mt-2 text-sm text-zinc-400">Couldn't load suggestions — just type an ingredient above to start.</p>
          )}
        </div>
      )}

      {isError && (
        <div className="mt-8 text-center">
          <p className="text-red-600">Something went wrong while finding recipes.</p>
          <button
            type="button"
            onClick={() => refetch()}
            className="mt-2 rounded-full border border-zinc-300 bg-white px-5 py-2 text-sm font-medium text-zinc-700 shadow-sm hover:border-emerald-500 hover:text-emerald-700"
          >
            Try again
          </button>
        </div>
      )}

      {hasPantry && isLoading && <ResultsSkeleton />}

      {data && smallPantry && !noResults && (
        <p className="mt-6 rounded-xl bg-amber-50 px-4 py-2.5 text-center text-sm text-amber-700">
          💡 This finds meals your pantry can <em>almost</em> cover — the more ingredients you add, the more show up.
        </p>
      )}

      {data && (
        <>
          <ResultsSection title="Cook now" subtitle="you have everything" recipes={cookNow} total={cookNowTotal} accent="emerald" />
          <ResultsSection title="Almost there" subtitle="missing 1–2" recipes={almost} total={almostTotal} accent="amber" />
          {hasNextPage && (
            <div className="mt-8 flex justify-center">
              <button
                type="button"
                onClick={() => fetchNextPage()}
                disabled={isFetchingNextPage}
                className="rounded-full border border-zinc-300 bg-white px-6 py-2.5 text-sm font-medium text-zinc-700 shadow-sm hover:border-emerald-500 hover:text-emerald-700 disabled:cursor-not-allowed disabled:opacity-60"
              >
                {isFetchingNextPage ? 'Loading…' : 'Load more'}
              </button>
            </div>
          )}
        </>
      )}

      {noResults && (
        <div className="mt-10 text-center text-zinc-500">
          <p>No recipes within reach yet.</p>
          <p className="mt-1 text-sm">
            This finder shows meals you can <em>almost</em> cook — one ingredient is rarely enough.
            Add a few more you have (egg, onion, garlic)
            {!pantry.includeStaples && ' — or turn on staples'}
            {(difficulty || diet || minRating) && ' — or relax the filters'}.
          </p>
        </div>
      )}
    </div>
  )
}

function FilterField({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div className="flex flex-col gap-2">
      <span className="text-xs font-semibold uppercase tracking-wide text-zinc-400">{label}</span>
      {children}
    </div>
  )
}

function ResultsSkeleton() {
  return (
    <div className="mt-8 grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
      {Array.from({ length: 8 }).map((_, i) => (
        <div key={i} className="animate-pulse overflow-hidden rounded-2xl border border-zinc-200 bg-white">
          <div className="aspect-[4/3] bg-zinc-100" />
          <div className="space-y-2 p-3">
            <div className="h-4 w-3/4 rounded bg-zinc-100" />
            <div className="h-3 w-1/2 rounded bg-zinc-100" />
          </div>
        </div>
      ))}
    </div>
  )
}
