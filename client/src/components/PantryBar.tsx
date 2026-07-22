import type { Ingredient } from '../api'
import type { PantryItem } from '../hooks/usePantry'
import { IngredientSearch } from './IngredientSearch'

interface Props {
  items: PantryItem[]
  includeStaples: boolean
  onAdd: (ingredient: Ingredient) => void
  onRemove: (id: number) => void
  onClear: () => void
  onToggleStaples: (value: boolean) => void
}

export function PantryBar({ items, includeStaples, onAdd, onRemove, onClear, onToggleStaples }: Props) {
  return (
    <div className="rounded-2xl border border-zinc-200 bg-white p-4 shadow-sm">
      <IngredientSearch onSelect={onAdd} excludeIds={items.map((i) => i.id)} />

      {items.length > 0 && (
        <div className="mt-3 flex flex-wrap items-center gap-2">
          {items.map((i) => (
            <span
              key={i.id}
              className="inline-flex items-center gap-1 rounded-full bg-emerald-100 py-1 pl-3 pr-1.5 text-sm font-medium text-emerald-800"
            >
              <span className="capitalize">{i.name}</span>
              <button
                type="button"
                onClick={() => onRemove(i.id)}
                aria-label={`Remove ${i.name}`}
                className="grid h-5 w-5 place-items-center rounded-full leading-none text-emerald-700 hover:bg-emerald-200"
              >
                ×
              </button>
            </span>
          ))}
          <button type="button" onClick={onClear} className="rounded-full px-3 py-1 text-sm text-zinc-500 hover:text-zinc-800">
            Clear all
          </button>
        </div>
      )}

      <div className="mt-3">
        <label className="flex items-center gap-2 text-sm text-zinc-600">
          <input
            type="checkbox"
            checked={includeStaples}
            onChange={(e) => onToggleStaples(e.target.checked)}
            className="h-4 w-4 rounded accent-emerald-600"
          />
          <span>
            Assume I have <strong>staples</strong> (salt, pepper, oil, water, butter)
          </span>
        </label>
        <p className="mt-1 pl-6 text-xs text-zinc-400">
          Salt alone is in ~a third of recipes — without this, almost everything looks 1–2 short.
        </p>
      </div>
    </div>
  )
}
