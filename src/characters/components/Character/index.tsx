import type { CharacterState, CharacterSize, CharacterSizeName } from '../../types'
import { SIZE_PX } from '../../types'
import { getCharacter } from '../../registry'
import { CharacterRenderer } from './CharacterRenderer'
import { CharacterAnimator } from './CharacterAnimator'

interface CharacterProps {
  id: string
  state: CharacterState
  size?: CharacterSize
}

function resolvePx(size: CharacterSize): number {
  if (typeof size === 'number') return size
  return SIZE_PX[size as CharacterSizeName]
}

export function Character({ id, state, size = 'md' }: CharacterProps) {
  const config = getCharacter(id)

  if (!config) {
    if (import.meta.env.DEV) {
      console.warn(`[Character] Unknown character id: "${id}"`)
    }
    return null
  }

  // Resolve to the actual state key that will be rendered. If the requested
  // state is not defined, fall back to defaultState. The resolved key (not the
  // raw prop) is passed to CharacterAnimator so AnimatePresence keys on what
  // is actually rendering — two unknown states that both fall back to the same
  // default will share a key and not trigger spurious re-animation.
  const resolvedStateKey = config.states[state] !== undefined ? state : config.defaultState
  const stateConfig = config.states[resolvedStateKey]

  if (!stateConfig) return null

  const sizePx = resolvePx(size)

  return (
    // Accessible wrapper: role="img" + aria-label expose the character identity
    // and current state to assistive technology. The inner SVG parts are marked
    // aria-hidden in PartsRenderer so the AT tree is not polluted with decorative
    // SVG content.
    <div role="img" aria-label={`${config.name.en} — ${resolvedStateKey}`}>
      <CharacterAnimator
        resolvedStateKey={resolvedStateKey}
        sizePx={sizePx}
        animation={stateConfig.animation}
        idleAnimation={stateConfig.idleAnimation}
      >
        {/* stateConfig resolved once above — passed directly so CharacterRenderer does not re-resolve */}
        <CharacterRenderer stateConfig={stateConfig} size={sizePx} />
      </CharacterAnimator>
    </div>
  )
}
