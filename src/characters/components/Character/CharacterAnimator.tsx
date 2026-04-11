import { AnimatePresence, motion } from 'motion/react'
import type { ReactNode } from 'react'
import type { AnimationPreset, AnimationRef, CharacterState } from '../../types'
import { ANIMATION_PRESETS } from '../../animations/presets'

interface CharacterAnimatorProps {
  state: CharacterState
  sizePx: number
  animation: AnimationRef
  idleAnimation?: AnimationRef
  children: ReactNode
}

function resolvePreset(ref: AnimationRef): AnimationPreset {
  if (typeof ref === 'string') {
    return ANIMATION_PRESETS[ref as keyof typeof ANIMATION_PRESETS] ?? {}
  }
  return ref
}

export function CharacterAnimator({
  state,
  sizePx,
  animation,
  idleAnimation,
  children,
}: CharacterAnimatorProps) {
  const enter = resolvePreset(animation)
  const idle = idleAnimation ? resolvePreset(idleAnimation) : undefined

  // Note: AnimationPreset.parts (per-named-part motion overrides, keyed by SVG group id) is
  // defined in types.ts but not yet wired here. Implement when per-character-part animation
  // targeting is required — the data structure is forward-declared and ready.

  // Outer wrapper: handles state entry/exit animation (keyed so AnimatePresence
  // can unmount/mount on state change)
  // Inner wrapper: handles the idle loop, layered independently of entry animation
  return (
    <AnimatePresence mode="wait">
      <motion.div
        key={state}
        style={{ width: sizePx, height: sizePx, flexShrink: 0 }}
        {...enter.enter}
      >
        {idle?.idle ? (
          <motion.div style={{ width: sizePx, height: sizePx }} {...idle.idle}>
            {children}
          </motion.div>
        ) : (
          children
        )}
      </motion.div>
    </AnimatePresence>
  )
}
