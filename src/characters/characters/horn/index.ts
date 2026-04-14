import type { CharacterConfig } from '../../types'
import { createCharacterStateComponent, type CharacterStateData } from '../../components/PartsRenderer'
import correctData from './correct.json'
import wrongData from './wrong.json'
import smileData from './smile.json'

// JSON imports widen tuple fields to number[] — double cast required to satisfy Part.c: [n,n,n,n]
const HornCorrect = createCharacterStateComponent(correctData as unknown as CharacterStateData)
const HornWrong = createCharacterStateComponent(wrongData as unknown as CharacterStateData)
const HornSmile = createCharacterStateComponent(smileData as unknown as CharacterStateData)

export const hornConfig: CharacterConfig = {
  id: 'horn',
  name: { en: 'Horn', de: 'Horn', zh: '霍恩' },
  accentColor: '#f59e0b',
  defaultState: 'smile',
  states: {
    correct: { Component: HornCorrect, animation: 'celebrate', idleAnimation: 'idle-float' },
    wrong: { Component: HornWrong, animation: 'slump', idleAnimation: 'idle-wiggle' },
    smile: { Component: HornSmile, animation: 'pop-in', idleAnimation: 'idle-breathe' },
  },
}
