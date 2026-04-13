/**
 * Code Connect mappings for the PapaBini character library.
 *
 * Links each Figma ComponentSet in the character library file to the
 * <Character> React component so Figma Dev Mode shows real usage code.
 *
 * Figma file: https://www.figma.com/design/moOplvUMcgE538AV53d7Db
 *
 * NOTE: Publishing requires a Figma Organization or Enterprise plan.
 * To publish once eligible:
 *   npx figma connect publish --token <your-figma-token>
 *
 * Potato King is stubbed here — publish after distinct correct/wrong art
 * is added to the Figma file (tracked: https://trello.com/c/aFPvQBrx).
 */

import figma from '@figma/code-connect'
import { Character } from './index'

const STATE_PROP = figma.enum('state', {
  correct: 'correct',
  wrong: 'wrong',
  smile: 'smile',
})

// ─── Flo (node 7:110) ────────────────────────────────────────────────────────
figma.connect(
  Character,
  'https://www.figma.com/design/moOplvUMcgE538AV53d7Db?node-id=7:110',
  {
    props: { state: STATE_PROP },
    example: ({ state }) => <Character id="flo" state={state} />,
  }
)

// ─── Kangar (node 16:2) ───────────────────────────────────────────────────────
figma.connect(
  Character,
  'https://www.figma.com/design/moOplvUMcgE538AV53d7Db?node-id=16:2',
  {
    props: { state: STATE_PROP },
    example: ({ state }) => <Character id="kangar" state={state} />,
  }
)

// ─── Horn (node 10:85) ────────────────────────────────────────────────────────
figma.connect(
  Character,
  'https://www.figma.com/design/moOplvUMcgE538AV53d7Db?node-id=10:85',
  {
    props: { state: STATE_PROP },
    example: ({ state }) => <Character id="horn" state={state} />,
  }
)

// ─── HerzStreifen (node 11:91) ────────────────────────────────────────────────
figma.connect(
  Character,
  'https://www.figma.com/design/moOplvUMcgE538AV53d7Db?node-id=11:91',
  {
    props: { state: STATE_PROP },
    example: ({ state }) => <Character id="herzstreifen" state={state} />,
  }
)

// ─── Flex (node 8:80) ─────────────────────────────────────────────────────────
figma.connect(
  Character,
  'https://www.figma.com/design/moOplvUMcgE538AV53d7Db?node-id=8:80',
  {
    props: { state: STATE_PROP },
    example: ({ state }) => <Character id="flex" state={state} />,
  }
)

// ─── Potato King (stub — node ID TBD) ────────────────────────────────────────
// Add Potato King to the Figma file and replace the placeholder node ID below.
// Do not publish until correct/wrong art is finalised (tracked: Trello #aFPvQBrx).
//
// figma.connect(
//   Character,
//   'https://www.figma.com/design/moOplvUMcgE538AV53d7Db?node-id=TODO',
//   {
//     props: { state: STATE_PROP },
//     example: ({ state }) => <Character id="potatoking" state={state} />,
//   }
// )
