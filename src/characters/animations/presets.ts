import type { AnimationPreset } from '../types'

// ---------------------------------------------------------------------------
// Animation presets — shared across all characters
//
// Each preset is keyed by a human-readable name. Characters reference presets
// by name in their config. New presets can be added here without touching
// any character or component code.
// ---------------------------------------------------------------------------

export const ANIMATION_PRESETS = {

  // --- Entry animations ---------------------------------------------------

  'pop-in': {
    enter: {
      initial: { scale: 0.7, opacity: 0 },
      animate: { scale: 1, opacity: 1 },
      transition: { type: 'spring', stiffness: 400, damping: 20 },
    },
  },

  'bounce-in': {
    enter: {
      initial: { y: -20, opacity: 0 },
      animate: { y: 0, opacity: 1 },
      transition: { type: 'spring', stiffness: 500, damping: 18 },
    },
  },

  'celebrate': {
    enter: {
      animate: { scale: [1, 1.15, 1], rotate: [0, -4, 4, -2, 0] },
      transition: { duration: 0.5, ease: 'easeOut' },
    },
  },

  'slump': {
    enter: {
      animate: { y: [0, 8, 4], rotate: [0, -3, -1] },
      transition: { duration: 0.4, ease: 'easeOut' },
    },
  },

  // --- Idle loops ---------------------------------------------------------
  // TODO: Replace hardcoded duration values with design system animation tokens when token system
  // ships (card 5.3). prefers-reduced-motion: idle loop animations below do not currently
  // respect prefers-reduced-motion — known gap, tracked for post-token-system pass.

  'idle-breathe': {
    idle: {
      animate: { scaleY: [1, 1.025, 1] },
      transition: { repeat: Infinity, duration: 3.5, ease: 'easeInOut' },
    },
  },

  'idle-float': {
    idle: {
      animate: { y: [0, -6, 0] },
      transition: { repeat: Infinity, duration: 2.5, ease: 'easeInOut' },
    },
  },

  'idle-wiggle': {
    idle: {
      animate: { rotate: [-1.5, 1.5, -1.5] },
      transition: { repeat: Infinity, duration: 2, ease: 'easeInOut' },
    },
  },

} as const satisfies Record<string, AnimationPreset>

// AnimationPresetName is defined canonically in types.ts — do not redefine here.
