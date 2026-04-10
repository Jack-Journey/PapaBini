import type { CharacterConfig, CharacterState } from '../../types'

interface CharacterRendererProps {
  config: CharacterConfig
  state: CharacterState
  size: number
}

export function CharacterRenderer({ config, state, size }: CharacterRendererProps) {
  const stateConfig = config.states[state] ?? config.states[config.defaultState]

  if (!stateConfig) return null

  const { Component } = stateConfig

  return <Component size={size} />
}
