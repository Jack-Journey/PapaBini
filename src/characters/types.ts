import type { HTMLMotionProps } from 'motion/react'
import type { ComponentType } from 'react'
import type { ANIMATION_PRESETS } from './animations/presets'

// ---------------------------------------------------------------------------
// Parts — canonical schema for character JSON data files
// ---------------------------------------------------------------------------

/** A single visual part of a character state */
export interface Part {
  /** Part name — used for animation targeting and devtools identification */
  n: string
  /** Coordinate kind: 'i' = inset percentages [top,right,bottom,left] | 'p' = pixel [x,y,width,height] */
  k: 'i' | 'p'
  /**
   * Coordinates — 4-element tuple. Semantics depend on k:
   *   k='i': CSS inset percentages [top, right, bottom, left]
   *   k='p': pixel values [x, y, width, height] within the NATIVE_SIZE (200px) canvas.
   *          Constraint: x + width <= 200, y + height <= 200
   *          Source Figma frames are scaled to 200px before authoring
   *          (e.g. 344px Figma → 200px native via factor 200/344 ≈ 0.5814)
   */
  c: [number, number, number, number]
  /**
   * SVG string — must begin with <svg.
   * Never user-supplied content — sourced exclusively from build-time JSON authored by developers.
   */
  s: string
}

/** Complete data for one character state, loaded from a JSON file */
export interface CharacterStateData {
  char: string
  state: string
  parts: Part[]
}

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

export interface CharacterAssetProps {
  size?: number
  className?: string
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
