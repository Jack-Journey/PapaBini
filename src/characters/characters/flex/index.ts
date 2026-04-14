import type { CharacterConfig } from '../../types'
import { createCharacterStateComponent, type CharacterStateData } from '../../components/PartsRenderer'
import correctData from './correct.json'
import wrongData from './wrong.json'
import smileData from './smile.json'

// JSON imports widen tuple fields to number[] — double cast required to satisfy Part.c: [n,n,n,n]
const FlexCorrect = createCharacterStateComponent(correctData as unknown as CharacterStateData)
const FlexWrong = createCharacterStateComponent(wrongData as unknown as CharacterStateData)
const FlexSmile = createCharacterStateComponent(smileData as unknown as CharacterStateData)

export const flexConfig: CharacterConfig = {
  id: 'flex',
  name: { en: 'Flex', de: 'Flex', zh: '弗萊克斯' },
  accentColor: '#FFD059',
  defaultState: 'smile',
  states: {
    correct: { Component: FlexCorrect, animation: 'celebrate', idleAnimation: 'idle-float' },
    wrong: { Component: FlexWrong, animation: 'slump', idleAnimation: 'idle-wiggle' },
    smile: { Component: FlexSmile, animation: 'pop-in', idleAnimation: 'idle-breathe' },
  },
}
