import type { CharacterConfig } from '../../types'
import { createCharacterStateComponent, type CharacterStateData } from '../../components/PartsRenderer'
import correctData from './correct.json'
import wrongData from './wrong.json'
import smileData from './smile.json'

// JSON imports widen tuple fields to number[] — double cast required to satisfy Part.c: [n,n,n,n]
const KangarCorrect = createCharacterStateComponent(correctData as unknown as CharacterStateData)
const KangarWrong = createCharacterStateComponent(wrongData as unknown as CharacterStateData)
const KangarSmile = createCharacterStateComponent(smileData as unknown as CharacterStateData)

export const kangarConfig: CharacterConfig = {
  id: 'kangar',
  name: { en: 'Kangar', de: 'Kangar', zh: '康加' },
  accentColor: '#a100b6',
  defaultState: 'smile',
  states: {
    correct: { Component: KangarCorrect, animation: 'celebrate', idleAnimation: 'idle-float' },
    wrong: { Component: KangarWrong, animation: 'slump', idleAnimation: 'idle-wiggle' },
    smile: { Component: KangarSmile, animation: 'pop-in', idleAnimation: 'idle-breathe' },
  },
}
