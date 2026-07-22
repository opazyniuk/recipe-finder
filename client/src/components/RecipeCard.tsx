import { Link } from 'react-router-dom'
import type { Difficulty, RecipeMatch } from '../api'
import { RecipeImage } from './RecipeImage'

const DIFFICULTY_STYLES: Record<Difficulty, string> = {
  easy: 'bg-emerald-100 text-emerald-700',
  medium: 'bg-amber-100 text-amber-700',
  hard: 'bg-rose-100 text-rose-700',
}

export function RecipeCard({ recipe }: { recipe: RecipeMatch }) {
  const cookNow = recipe.missing_count === 0
  const moreLabel = recipe.missing_count === 1 ? 'Just 1 more' : `${recipe.missing_count} more`

  return (
    <Link
      to={`/recipes/${recipe.id}`}
      className="group flex flex-col overflow-hidden rounded-2xl border border-zinc-200 bg-white shadow-sm transition hover:shadow-md"
    >
      <div className="aspect-[4/3] overflow-hidden bg-zinc-100">
        <RecipeImage src={recipe.image_url} id={recipe.id} className="transition group-hover:scale-105" />
      </div>

      <div className="flex flex-1 flex-col gap-2 p-3">
        <h3 className="line-clamp-2 font-semibold leading-snug text-zinc-800">{recipe.title}</h3>

        <div className="flex flex-wrap items-center gap-2 text-xs text-zinc-500">
          {recipe.ratings != null && <span>⭐ {recipe.ratings.toFixed(1)}</span>}
          {recipe.total_time != null && recipe.total_time > 0 && <span>⏱ {recipe.total_time} min</span>}
          <span className={`rounded-full px-2 py-0.5 capitalize ${DIFFICULTY_STYLES[recipe.difficulty]}`}>
            {recipe.difficulty}
          </span>
          {recipe.cuisine && (
            <span className="rounded-full bg-zinc-100 px-2 py-0.5 text-zinc-600">{recipe.cuisine}</span>
          )}
        </div>

        <div className="mt-auto pt-1">
          {cookNow ? (
            <span className="inline-flex items-center gap-1 rounded-full bg-emerald-100 px-2 py-0.5 text-xs font-medium text-emerald-800">
              ✓ You have all {recipe.total_count}
            </span>
          ) : (
            <div className="flex flex-wrap items-center gap-1 text-xs">
              <span className="font-semibold text-amber-700">{moreLabel}:</span>
              {recipe.missing_names.map((name) => (
                <span key={name} className="rounded-full bg-amber-100 px-2 py-0.5 capitalize text-amber-800">
                  {name}
                </span>
              ))}
            </div>
          )}
        </div>
      </div>
    </Link>
  )
}
