import type { RecipeMatch } from '../api'
import { RecipeCard } from './RecipeCard'

interface Props {
  title: string
  subtitle: string
  recipes: RecipeMatch[]
  total: number
  accent: 'emerald' | 'amber'
}

export function ResultsSection({ title, subtitle, recipes, total, accent }: Props) {
  if (recipes.length === 0) return null

  const dot = accent === 'emerald' ? 'bg-emerald-500' : 'bg-amber-500'

  return (
    <section className="mt-8">
      <div className="mb-3 flex items-baseline gap-2">
        <span className={`inline-block h-2.5 w-2.5 rounded-full ${dot}`} />
        <h2 className="text-xl font-bold text-zinc-800">{title}</h2>
        <span className="text-sm text-zinc-400">
          {recipes.length} of {total} · {subtitle}
        </span>
      </div>
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
        {recipes.map((recipe) => (
          <RecipeCard key={recipe.id} recipe={recipe} />
        ))}
      </div>
    </section>
  )
}
