import type { CharacterConfig } from './types'
import { floConfig } from './characters/flo'
import { kangarConfig } from './characters/kangar'
import { hornConfig } from './characters/horn'
import { herzStreifenConfig } from './characters/herzstreifen'
import { flexConfig } from './characters/flex'
import { potatoKingConfig } from './characters/potatoking'

// ---------------------------------------------------------------------------
// Master character registry
//
// All characters available on the PapaBini platform are registered here.
// Games import characters from this registry via the public API (index.ts).
// Adding a character = adding its config import and pushing to this array.
// ---------------------------------------------------------------------------

export const CHARACTERS: CharacterConfig[] = [
  floConfig,
  kangarConfig,
  hornConfig,
  herzStreifenConfig,
  flexConfig,
  potatoKingConfig,
]

export function getCharacter(id: string): CharacterConfig | undefined {
  return CHARACTERS.find(c => c.id === id)
}
