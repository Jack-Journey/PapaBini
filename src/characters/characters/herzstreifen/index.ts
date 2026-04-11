import type { CharacterConfig } from '../../types'
import { createCharacterStateComponent, type CharacterStateData } from '../../components/PartsRenderer'
import correctData from './correct.json'
import wrongData from './wrong.json'
import smileData from './smile.json'

// JSON imports widen tuple fields to number[] — double cast required to satisfy Part.c: [n,n,n,n]
const HerzCorrect = createCharacterStateComponent(correctData as unknown as CharacterStateData)
const HerzWrong = createCharacterStateComponent(wrongData as unknown as CharacterStateData)
const HerzSmile = createCharacterStateComponent(smileData as unknown as CharacterStateData)

export const herzStreifenConfig: CharacterConfig = {
  id: 'herzstreifen',
  name: { en: 'HerzStreifen', de: 'HerzStreifen', zh: '心紋' },
  accentColor: '#0075A7',
  defaultState: 'smile',
  states: {
    correct: { Component: HerzCorrect, animation: 'celebrate', idleAnimation: 'idle-float' },
    wrong: { Component: HerzWrong, animation: 'slump', idleAnimation: 'idle-wiggle' },
    smile: { Component: HerzSmile, animation: 'pop-in', idleAnimation: 'idle-breathe' },
  },
}
