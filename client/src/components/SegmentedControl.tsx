import type { ReactNode } from 'react'

export interface Segment<T> {
  value: T
  label: ReactNode
  activeClassName?: string
}

interface Props<T> {
  options: Segment<T>[]
  value: T
  onChange: (value: T) => void
  ariaLabel?: string
}

export function SegmentedControl<T extends string | number | null>({
  options,
  value,
  onChange,
  ariaLabel,
}: Props<T>) {
  return (
    <div role="group" aria-label={ariaLabel} className="inline-flex rounded-full bg-zinc-100 p-1">
      {options.map((option) => {
        const active = option.value === value
        return (
          <button
            key={String(option.value)}
            type="button"
            aria-pressed={active}
            onClick={() => onChange(option.value)}
            className={`rounded-full px-3.5 py-1.5 text-sm font-medium transition-colors ${
              active
                ? (option.activeClassName ?? 'bg-zinc-800 text-white shadow-sm')
                : 'text-zinc-500 hover:text-zinc-800'
            }`}
          >
            {option.label}
          </button>
        )
      })}
    </div>
  )
}
