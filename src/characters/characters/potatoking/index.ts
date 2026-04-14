import type { CharacterConfig } from '../../types'
import { createCharacterStateComponent, type CharacterStateData } from '../../components/PartsRenderer'
import correctData from './correct.json'
import wrongData from './wrong.json'
import smileData from './smile.json'

// JSON imports widen tuple fields to number[] — double cast required to satisfy Part.c: [n,n,n,n]
const PotatoKingCorrect = createCharacterStateComponent(correctData as unknown as CharacterStateData)
const PotatoKingWrong = createCharacterStateComponent(wrongData as unknown as CharacterStateData)
const PotatoKingSmile = createCharacterStateComponent(smileData as unknown as CharacterStateData)

export const potatoKingConfig: CharacterConfig = {
  id: 'potatoking',
  name: { en: 'Potato King', de: 'Kartoffelkönig', zh: '馬鈴薯王' },
  accentColor: '#FB923C',
  defaultState: 'smile',
  states: {
    correct: { Component: PotatoKingCorrect, animation: 'celebrate', idleAnimation: 'idle-float' },
    wrong: { Component: PotatoKingWrong, animation: 'slump', idleAnimation: 'idle-wiggle' },
    smile: { Component: PotatoKingSmile, animation: 'pop-in', idleAnimation: 'idle-breathe' },
  },
}
