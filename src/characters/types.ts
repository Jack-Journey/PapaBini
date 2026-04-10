import type { HTMLMotionProps } from 'motion/react'
import type { ComponentType, SVGProps } from 'react'
import type { ANIMATION_PRESETS } from './animations/presets'

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

export type CharacterBaseState = 'correct' | 'wrong' | 'smile'

// Open string union — new states can be added without breaking existing code
export type CharacterState = CharacterBaseState | (string & {})

// ---------------------------------------------------------------------------
// Size
// ---------------------------------------------------------------------------

export type CharacterSizeName = 'sm' | 'md' | 'lg'
export type CharacterSize = CharacterSizeName | number

export const SIZE_PX: Record<CharacterSizeName, number> = {
  sm: 120,
  md: 180,
  lg: 240,
}

// ---------------------------------------------------------------------------
// Localisation
// ---------------------------------------------------------------------------

export type Language = 'en' | 'de' | 'zh'

export interface LocalisedString {
  en: string
  de: string
  zh: string
}

// ---------------------------------------------------------------------------
// Animation
// ---------------------------------------------------------------------------

// Motion config for a single animation phase
export type MotionConfig = Pick<
  HTMLMotionProps<'div'>,
  'initial' | 'animate' | 'exit' | 'transition'
>

export interface AnimationPreset {
  enter?: MotionConfig
  exit?: MotionConfig
  idle?: MotionConfig
  // Per named SVG part overrides — keyed by the SVG group id attribute
  parts?: Record<string, MotionConfig>
}

export type AnimationPresetName = keyof typeof ANIMATION_PRESETS

export type AnimationRef = AnimationPresetName | AnimationPreset

// ---------------------------------------------------------------------------
// Asset
// ---------------------------------------------------------------------------

export type CharacterAssetProps = SVGProps<SVGSVGElement> & {
  size?: number
}

// ---------------------------------------------------------------------------
// Registry
// ---------------------------------------------------------------------------

export interface CharacterStateConfig {
  Component: ComponentType<CharacterAssetProps>
  animation: AnimationRef
  idleAnimation?: AnimationRef
}

export interface CharacterConfig {
  id: string
  name: LocalisedString
  // Accent colour used for UI theming around this character (placeholder until tokens ship)
  accentColor: string
  defaultState: CharacterState
  states: Partial<Record<CharacterState, CharacterStateConfig>>
}
