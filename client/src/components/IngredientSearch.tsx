import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { searchIngredients, type Ingredient } from '../api'
import { useDebounced } from '../hooks/useDebounced'

interface Props {
  onSelect: (ingredient: Ingredient) => void
  excludeIds: number[]
}

export function IngredientSearch({ onSelect, excludeIds }: Props) {
  const [q, setQ] = useState('')
  const debounced = useDebounced(q.trim(), 200)

  const { data = [], isFetching } = useQuery({
    queryKey: ['ingredients', debounced],
    queryFn: () => searchIngredients(debounced),
    enabled: debounced.length > 0,
  })

  const suggestions = data.filter((i) => !excludeIds.includes(i.id)).slice(0, 8)

  function pick(ingredient: Ingredient) {
    onSelect(ingredient)
    setQ('')
  }

  return (
    <div className="relative">
      <input
        value={q}
        onChange={(e) => setQ(e.target.value)}
        onKeyDown={(e) => {
          if (e.key === 'Enter' && suggestions[0]) pick(suggestions[0])
        }}
        placeholder="Add an ingredient you have…"
        aria-label="Search ingredients"
        autoComplete="off"
        className="w-full rounded-xl border border-zinc-300 bg-white px-4 py-3 text-base outline-none focus:border-emerald-500 focus:ring-2 focus:ring-emerald-100"
      />
      {debounced.length > 0 && (
        <ul className="absolute z-10 mt-1 max-h-72 w-full overflow-auto rounded-xl border border-zinc-200 bg-white shadow-lg">
          {suggestions.length === 0 && !isFetching && (
            <li className="px-4 py-3 text-sm text-zinc-400">No matches for “{debounced}”.</li>
          )}
          {suggestions.map((i) => (
            <li key={i.id}>
              <button
                type="button"
                onClick={() => pick(i)}
                className="flex w-full items-center justify-between gap-3 px-4 py-2.5 text-left hover:bg-emerald-50"
              >
                <span className="capitalize text-zinc-800">{i.name}</span>
                <span className="shrink-0 text-xs text-zinc-400">{i.recipes_count} recipes</span>
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}
