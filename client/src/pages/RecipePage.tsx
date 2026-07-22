import { Link, useParams } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { fetchRecipe } from '../api'
import { usePantry } from '../hooks/usePantry'
import { RecipeImage } from '../components/RecipeImage'

export function RecipePage() {
  const { id } = useParams()
  const { items, includeStaples } = usePantry()
  const ids = items.map((i) => i.id)
  const recipeId = Number(id)

  const { data: recipe, isLoading, isError, refetch } = useQuery({
    queryKey: ['recipe', recipeId, ids, includeStaples],
    queryFn: () => fetchRecipe(recipeId, ids, includeStaples),
  })

  const missing = recipe?.ingredients.filter((i) => !i.is_available) ?? []
  const cookNow = recipe != null && missing.length === 0

  return (
    <div className="mx-auto max-w-3xl px-4 py-6">
      <Link to="/" className="text-sm text-emerald-700 hover:underline">
        ← Back to search
      </Link>

      {isLoading && <RecipeDetailSkeleton />}
      {isError && (
        <div className="mt-8">
          <p className="text-red-600">Couldn't load this recipe.</p>
          <button
            type="button"
            onClick={() => refetch()}
            className="mt-2 rounded-full border border-zinc-300 bg-white px-5 py-2 text-sm font-medium text-zinc-700 shadow-sm hover:border-emerald-500 hover:text-emerald-700"
          >
            Try again
          </button>
        </div>
      )}

      {recipe && (
        <article className="mt-4">
          <div className="mb-4 aspect-video w-full overflow-hidden rounded-2xl bg-zinc-100">
            <RecipeImage src={recipe.image_url} id={recipe.id} />
          </div>
          <h1 className="text-2xl font-bold text-zinc-900">{recipe.title}</h1>

          <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-sm text-zinc-500">
            {recipe.ratings != null && <span>⭐ {recipe.ratings.toFixed(1)}</span>}
            {recipe.prep_time != null && recipe.prep_time > 0 && <span>🔪 {recipe.prep_time} min prep</span>}
            {recipe.cook_time != null && recipe.cook_time > 0 && <span>🍳 {recipe.cook_time} min cook</span>}
            {recipe.total_time != null && recipe.total_time > 0 && <span>⏱ {recipe.total_time} min total</span>}
            {recipe.cuisine && <span className="font-medium text-zinc-600">{recipe.cuisine}</span>}
            {recipe.category && <span>{recipe.category}</span>}
            {recipe.author && <span>by {recipe.author}</span>}
          </div>

          <div className="mt-3">
            {cookNow ? (
              <span className="inline-flex items-center gap-1.5 rounded-full bg-emerald-100 px-3 py-1 text-sm font-medium text-emerald-800">
                ✓ You can cook this right now
              </span>
            ) : (
              <span className="inline-flex items-center gap-1.5 rounded-full bg-amber-100 px-3 py-1 text-sm font-medium text-amber-800">
                🛒 {missing.length === 1 ? 'Just 1 ingredient' : `${missing.length} ingredients`} to pick up
              </span>
            )}
          </div>

          <h2 className="mt-6 mb-2 font-semibold text-zinc-800">Ingredients</h2>
          <ul className="divide-y divide-zinc-100 overflow-hidden rounded-xl border border-zinc-200">
            {recipe.ingredients.map((ingredient, index) => (
              <li key={index} className="flex items-center gap-3 px-4 py-2.5">
                <span className={ingredient.is_available ? 'text-emerald-600' : 'text-zinc-300'}>
                  {ingredient.is_available ? '✓' : '○'}
                </span>
                <span className={`flex-1 ${ingredient.is_available ? 'text-zinc-700' : 'text-zinc-500'}`}>
                  {ingredient.raw_text}
                </span>
                {!ingredient.is_available && (
                  <span className="rounded-full bg-amber-100 px-2 py-0.5 text-xs text-amber-800">need</span>
                )}
              </li>
            ))}
          </ul>
        </article>
      )}
    </div>
  )
}

function RecipeDetailSkeleton() {
  return (
    <div className="mt-4 animate-pulse">
      <div className="mb-4 aspect-video w-full rounded-2xl bg-zinc-100" />
      <div className="h-7 w-2/3 rounded bg-zinc-100" />
      <div className="mt-3 h-4 w-1/3 rounded bg-zinc-100" />
      <div className="mt-6 space-y-2">
        {Array.from({ length: 6 }).map((_, i) => (
          <div key={i} className="h-10 rounded bg-zinc-100" />
        ))}
      </div>
    </div>
  )
}
