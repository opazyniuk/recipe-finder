import { useCallback, useEffect, useState } from 'react'
import type { Ingredient } from '../api'

export interface PantryItem {
  id: number
  name: string
}

const ITEMS_KEY = 'dinner.pantry.v1'
const STAPLES_KEY = 'dinner.staples.v1'

function load<T>(key: string, fallback: T): T {
  try {
    const raw = localStorage.getItem(key)
    return raw === null ? fallback : (JSON.parse(raw) as T)
  } catch {
    return fallback
  }
}

export function usePantry() {
  const [items, setItems] = useState<PantryItem[]>(() => load(ITEMS_KEY, []))
  const [includeStaples, setIncludeStaples] = useState<boolean>(() => load(STAPLES_KEY, true))

  useEffect(() => {
    localStorage.setItem(ITEMS_KEY, JSON.stringify(items))
  }, [items])

  useEffect(() => {
    localStorage.setItem(STAPLES_KEY, JSON.stringify(includeStaples))
  }, [includeStaples])

  const add = useCallback((ingredient: Ingredient | PantryItem) => {
    setItems((prev) =>
      prev.some((p) => p.id === ingredient.id)
        ? prev
        : [...prev, { id: ingredient.id, name: ingredient.name }]
    )
  }, [])

  const remove = useCallback((id: number) => {
    setItems((prev) => prev.filter((p) => p.id !== id))
  }, [])

  const clear = useCallback(() => setItems([]), [])

  const has = useCallback((id: number) => items.some((p) => p.id === id), [items])

  return { items, includeStaples, setIncludeStaples, add, remove, clear, has }
}
