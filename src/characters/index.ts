// ---------------------------------------------------------------------------
// Public API — character engine
//
// Games import from here. Internal implementation details (registry internals,
// animation presets, individual character configs) are not re-exported.
// ---------------------------------------------------------------------------

export { Character } from './components/Character'
export { CHARACTERS, getCharacter } from './registry'
export type {
  CharacterConfig,
  CharacterState,
  CharacterSize,
  CharacterSizeName,
  Language,
  AnimationPreset,
  AnimationPresetName,
} from './types'
