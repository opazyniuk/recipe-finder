import { useState } from 'react'

const EMOJI = ['🍲', '🥘', '🍝', '🥗', '🍳', '🥪', '🍜', '🧁', '🥧', '🍮', '🫕', '🍛']

interface Props {
  src: string | null
  id: number
  className?: string
}

export function RecipeImage({ src, id, className = '' }: Props) {
  const [failed, setFailed] = useState(false)

  if (src && !failed) {
    return (
      <img
        src={src}
        alt=""
        loading="lazy"
        referrerPolicy="no-referrer"
        onError={() => setFailed(true)}
        className={`h-full w-full object-cover ${className}`}
      />
    )
  }

  return (
    <div className="grid h-full place-items-center bg-gradient-to-br from-zinc-50 to-zinc-100 text-4xl">
      {EMOJI[id % EMOJI.length]}
    </div>
  )
}
