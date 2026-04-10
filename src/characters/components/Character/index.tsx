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

  const stateConfig = config.states[state] ?? config.states[config.defaultState]

  if (!stateConfig) return null

  const sizePx = resolvePx(size)

  return (
    <CharacterAnimator
      state={state}
      sizePx={sizePx}
      animation={stateConfig.animation}
      idleAnimation={stateConfig.idleAnimation}
    >
      <CharacterRenderer config={config} state={state} size={sizePx} />
    </CharacterAnimator>
  )
}
