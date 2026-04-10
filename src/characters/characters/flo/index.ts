import type { CharacterConfig } from '../../types'
import FloCorrect from './FloCorrect'
import FloWrong from './FloWrong'
import FloSmile from './FloSmile'

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
