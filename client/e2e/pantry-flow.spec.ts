import { test, expect, type Route } from '@playwright/test'

const POPULAR = [
  { id: 1, name: 'chicken', recipes_count: 1200, is_staple: false },
  { id: 2, name: 'rice', recipes_count: 800, is_staple: false },
  { id: 3, name: 'garlic', recipes_count: 1500, is_staple: false },
]

const match = (over: Record<string, unknown>) => ({
  image_url: null, total_time: 30, prep_time: 10, cook_time: 20, ratings: 4.6,
  category: 'Main Dish', cuisine: null, difficulty: 'easy', missing_names: [], ...over,
})

const SEARCH_WITH_STAPLES = {
  cook_now: [match({ id: 101, title: 'Garlic Chicken', have_count: 3, total_count: 3, missing_count: 0, cuisine: 'Ukrainian' })],
  almost: [match({ id: 102, title: 'Chicken Rice Pilaf', difficulty: 'medium', have_count: 3, total_count: 4, missing_count: 1, missing_names: ['onion'] })],
  page: 1, per_page: 24, has_more: false,
}

const SEARCH_NO_STAPLES = {
  cook_now: [],
  almost: [match({ id: 103, title: 'Roast Chicken', difficulty: 'hard', have_count: 3, total_count: 5, missing_count: 2, missing_names: ['salt', 'olive oil'] })],
  page: 1, per_page: 24, has_more: false,
}

const DETAIL = {
  id: 101, title: 'Garlic Chicken', image_url: null, prep_time: 10, cook_time: 20, total_time: 30,
  ratings: 4.6, category: 'Main Dish', cuisine: 'Ukrainian', author: 'Test Cook',
  ingredients: [
    { name: 'chicken', raw_text: '2 chicken breasts', is_staple: false, is_available: true },
    { name: 'garlic', raw_text: '3 cloves garlic, minced', is_staple: false, is_available: true },
    { name: 'salt', raw_text: '1 teaspoon salt', is_staple: true, is_available: true },
    { name: 'parsley', raw_text: '1/4 cup fresh parsley', is_staple: false, is_available: false },
  ],
}

test.beforeEach(async ({ page }) => {
  await page.route('**/api/v1/**', async (route: Route) => {
    const url = new URL(route.request().url())
    const path = url.pathname
    const json = (body: unknown) => route.fulfill({ contentType: 'application/json', body: JSON.stringify(body) })

    if (path.endsWith('/ingredients/popular')) return json(POPULAR)
    if (path.endsWith('/ingredients')) {
      const q = (url.searchParams.get('query') ?? '').toLowerCase()
      return json(POPULAR.filter((i) => i.name.includes(q)))
    }
    if (path.endsWith('/recipes/search')) {
      return json(url.searchParams.get('include_staples') === 'false' ? SEARCH_NO_STAPLES : SEARCH_WITH_STAPLES)
    }
    if (/\/recipes\/\d+$/.test(path)) return json(DETAIL)
    return route.fulfill({ status: 404, body: '[]' })
  })
})

test('pantry flow: buckets, staples toggle, recipe detail, and persistence', async ({ page }) => {
  await test.step('empty state offers popular ingredients', async () => {
    await page.goto('/')
    await expect(page.getByText(/Start by adding a few ingredients/)).toBeVisible()
    await expect(page.getByRole('button', { name: '+ chicken' })).toBeVisible()
  })

  await test.step('adding an ingredient fills cook-now and almost buckets', async () => {
    await page.getByRole('button', { name: '+ chicken' }).click()
    await expect(page.getByRole('button', { name: 'Remove chicken' })).toBeVisible()
    await expect(page.getByRole('heading', { name: 'Cook now' })).toBeVisible()
    await expect(page.getByRole('link', { name: /Garlic Chicken/ })).toBeVisible()
    await expect(page.getByText('Ukrainian')).toBeVisible()
    await expect(page.getByRole('heading', { name: 'Almost there' })).toBeVisible()
    await expect(page.getByText('Just 1 more:')).toBeVisible()
    await expect(page.getByText('onion')).toBeVisible()
  })

  await test.step('fuzzy autocomplete adds a second ingredient', async () => {
    await page.getByRole('textbox', { name: 'Search ingredients' }).fill('ric')
    await page.getByRole('button', { name: /rice/ }).click()
    await expect(page.getByRole('button', { name: 'Remove rice' })).toBeVisible()
  })

  await test.step('turning off staples changes the results', async () => {
    await page.getByRole('checkbox').uncheck()
    await expect(page.getByRole('link', { name: /Roast Chicken/ })).toBeVisible()
    await expect(page.getByText('2 more:')).toBeVisible()
    await expect(page.getByRole('link', { name: /Garlic Chicken/ })).toHaveCount(0)
  })

  await test.step('opening a recipe shows what you have vs. need', async () => {
    await page.getByRole('checkbox').check()
    await page.getByRole('link', { name: /Garlic Chicken/ }).click()
    await expect(page).toHaveURL(/\/recipes\/101$/)
    await expect(page.getByRole('heading', { level: 1, name: 'Garlic Chicken' })).toBeVisible()
    await expect(page.getByText('🛒 Just 1 ingredient to pick up')).toBeVisible()
    await expect(page.getByText('2 chicken breasts')).toBeVisible()
    await expect(page.getByText('1/4 cup fresh parsley')).toBeVisible()
    await expect(page.getByText('need')).toBeVisible()
  })

  await test.step('pantry persists across reload (localStorage, no account)', async () => {
    await page.getByRole('link', { name: /Back to search/ }).click()
    await page.reload()
    await expect(page.getByRole('button', { name: 'Remove chicken' })).toBeVisible()
    await expect(page.getByRole('button', { name: 'Remove rice' })).toBeVisible()
  })
})
