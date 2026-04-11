import type { CharacterStateConfig } from '../../types'

interface CharacterRendererProps {
  // Resolved stateConfig passed from Character/index.tsx — resolution happens once upstream,
  // not repeated here, to avoid duplicating the fallback logic in two places.
  stateConfig: CharacterStateConfig
  size: number
}

export function CharacterRenderer({ stateConfig, size }: CharacterRendererProps) {
  const { Component } = stateConfig
  return <Component size={size} />
}
