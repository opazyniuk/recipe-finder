export interface Ingredient {
  id: number
  name: string
  recipes_count: number
  is_staple: boolean
}

export type Difficulty = 'easy' | 'medium' | 'hard'
export type Diet = 'vegetarian' | 'vegan'

export interface RecipeMatch {
  id: number
  title: string
  image_url: string | null
  total_time: number | null
  prep_time: number | null
  cook_time: number | null
  ratings: number | null
  category: string | null
  cuisine: string | null
  difficulty: Difficulty
  have_count: number
  total_count: number
  missing_count: number
  missing_names: string[]
}

export interface SearchResult {
  cook_now: RecipeMatch[]
  almost: RecipeMatch[]
  cook_now_total: number
  almost_total: number
  page: number
  per_page: number
  has_more: boolean
}

export interface RecipeIngredient {
  name: string
  raw_text: string
  is_staple: boolean
  is_available: boolean
}

export interface RecipeDetail {
  id: number
  title: string
  image_url: string | null
  prep_time: number | null
  cook_time: number | null
  total_time: number | null
  ratings: number | null
  category: string | null
  cuisine: string | null
  author: string | null
  ingredients: RecipeIngredient[]
}

async function getJSON<T>(url: string): Promise<T> {
  const res = await fetch(url)
  if (!res.ok) throw new Error(`Request failed (${res.status})`)
  return res.json() as Promise<T>
}

function pantryParams(ingredientIds: number[], includeStaples: boolean): URLSearchParams {
  const params = new URLSearchParams()
  ingredientIds.forEach((id) => params.append('ingredient_ids[]', String(id)))
  params.set('include_staples', String(includeStaples))
  return params
}

export const searchIngredients = (query: string) =>
  getJSON<Ingredient[]>(`/api/v1/ingredients?query=${encodeURIComponent(query)}`)

export const popularIngredients = () =>
  getJSON<Ingredient[]>(`/api/v1/ingredients/popular`)

export interface RecipeFilters {
  difficulty?: Difficulty | null
  diet?: Diet | null
  minRating?: number | null
}

export const searchRecipes = (
  ingredientIds: number[],
  includeStaples: boolean,
  filters: RecipeFilters = {},
  page = 1,
) => {
  const params = pantryParams(ingredientIds, includeStaples)
  if (filters.difficulty) params.set('difficulty', filters.difficulty)
  if (filters.diet) params.set('diet', filters.diet)
  if (filters.minRating) params.set('min_rating', String(filters.minRating))
  if (page > 1) params.set('page', String(page))
  return getJSON<SearchResult>(`/api/v1/recipes/search?${params}`)
}

export const fetchRecipe = (id: number, ingredientIds: number[], includeStaples: boolean) =>
  getJSON<RecipeDetail>(`/api/v1/recipes/${id}?${pantryParams(ingredientIds, includeStaples)}`)
