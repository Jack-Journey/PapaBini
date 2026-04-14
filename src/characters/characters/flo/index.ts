import type { CharacterConfig } from '../../types'
import { createCharacterStateComponent, type CharacterStateData } from '../../components/PartsRenderer'
import correctData from './correct.json'
import wrongData from './wrong.json'
import smileData from './smile.json'

// JSON imports widen tuple fields to number[] — double cast required to satisfy Part.c: [n,n,n,n]
const FloCorrect = createCharacterStateComponent(correctData as unknown as CharacterStateData)
const FloWrong = createCharacterStateComponent(wrongData as unknown as CharacterStateData)
const FloSmile = createCharacterStateComponent(smileData as unknown as CharacterStateData)

export const floConfig: CharacterConfig = {
  id: 'flo',
  name: { en: 'Flo', de: 'Flo', zh: '弗洛' },
  // Teal accent — placeholder until design token system (card 5.3) ships
  accentColor: '#5ecfcf',
  defaultState: 'smile',
  states: {
    correct: {
      Component: FloCorrect,
      animation: 'celebrate',
      idleAnimation: 'idle-float',
    },
    wrong: {
      Component: FloWrong,
      animation: 'slump',
      idleAnimation: 'idle-wiggle',
    },
    smile: {
      Component: FloSmile,
      animation: 'pop-in',
      idleAnimation: 'idle-breathe',
    },
  },
}
