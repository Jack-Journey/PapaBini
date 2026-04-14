// ---------------------------------------------------------------------------
// Animation sequences — multi-step character storytelling
//
// Placeholder for future use. Sequences allow a character to play through
// multiple animation steps in order (e.g. wrong → slump → recover → smile).
// Uses Framer Motion's animate() imperative API under the hood.
// ---------------------------------------------------------------------------

export type AnimationStep = {
  preset: string
  duration?: number
  delay?: number
}

export type AnimationSequence = AnimationStep[]

// Example (not wired yet):
// export const wrongToRecover: AnimationSequence = [
//   { preset: 'slump', duration: 400 },
//   { preset: 'idle-wiggle', duration: 800 },
//   { preset: 'pop-in', duration: 300 },
// ]
