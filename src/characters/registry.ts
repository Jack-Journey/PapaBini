import type { CharacterConfig } from './types'
import { floConfig } from './characters/flo'

// ---------------------------------------------------------------------------
// Master character registry
//
// All characters available on the PapaBini platform are registered here.
// Games import characters from this registry via the public API (index.ts).
// Adding a character = adding its config import and pushing to this array.
// ---------------------------------------------------------------------------

export const CHARACTERS: CharacterConfig[] = [
  floConfig,
  // kangarConfig,      ← add when Kangar assets are ready
  // hornConfig,
  // herzStreifenConfig,
  // flexConfig,
]

export function getCharacter(id: string): CharacterConfig | undefined {
  return CHARACTERS.find(c => c.id === id)
}
