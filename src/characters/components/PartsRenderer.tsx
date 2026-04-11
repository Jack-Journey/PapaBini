/**
 * PartsRenderer — generic data-driven renderer for character states.
 *
 * Reads a CharacterStateData JSON (char + state + parts[]) and renders each
 * part as an absolutely-positioned <div> containing raw inline SVG.
 *
 * Coordinate systems:
 *   k: 'i' — inset percentages [top, right, bottom, left] — same as CSS inset shorthand
 *   k: 'p' — pixel values [x, y, width, height] within the NATIVE_SIZE canvas
 *             Constraint: x + width <= NATIVE_SIZE, y + height <= NATIVE_SIZE
 *             Source Figma frames are scaled to NATIVE_SIZE before authoring
 *             (e.g. 344px Figma → 200px native via factor 200/344 ≈ 0.5814)
 *
 * SVG trust model:
 *   All SVG strings come from build-time JSON authored by developers, never user input.
 *   A runtime guard (DEV only) warns if a part's s field doesn't begin with <svg.
 *   See canonical Part type definition in types.ts.
 *
 * Factory:
 *   createCharacterStateComponent wraps a JSON data object as a React component.
 *   Data is captured at module load time — no re-creation on render.
 *   The factory and renderer are co-located here for now; split if the engine grows.
 */

import type { CSSProperties } from 'react'
import type { CharacterStateData } from '../types'

export type { CharacterStateData }

const NATIVE_SIZE = 200

interface PartsRendererProps {
  data: CharacterStateData
  size?: number
  className?: string
}

export function PartsRenderer({ data, size = NATIVE_SIZE, className }: PartsRendererProps) {
  const scale = size / NATIVE_SIZE

  return (
    <div
      style={{ width: size, height: size, overflow: 'hidden', flexShrink: 0 }}
      className={className}
      data-character={data.char.toLowerCase()}
      data-state={data.state}
    >
      <div
        style={{
          width: NATIVE_SIZE,
          height: NATIVE_SIZE,
          position: 'relative',
          transform: `scale(${scale})`,
          transformOrigin: 'top left',
        }}
      >
        {data.parts.map((p, i) => {
          let style: CSSProperties
          if (p.k === 'i') {
            const [t, r, b, l] = p.c
            style = {
              position: 'absolute',
              top: `${t}%`,
              right: `${r}%`,
              bottom: `${b}%`,
              left: `${l}%`,
            }
          } else {
            const [x, y, w, h] = p.c
            style = {
              position: 'absolute',
              left: x,
              top: y,
              width: w,
              height: h,
            }
          }
          if (import.meta.env.DEV && !p.s.trimStart().startsWith('<svg')) {
            console.warn(`[PartsRenderer] Part "${p.n}" in ${data.char}/${data.state} does not start with <svg — check JSON source data`)
          }

          return (
            <div
              key={`${p.n}-${i}`}
              style={style}
              data-part={p.n}
              // Safe: SVG strings sourced from build-time JSON authored by developers, never user input.
              // Runtime guard above warns in DEV if content is not a valid SVG string.
              dangerouslySetInnerHTML={{ __html: p.s }}
            />
          )
        })}
      </div>
    </div>
  )
}

// Factory: wraps a JSON data object as a state Component matching the
// CharacterAssetProps contract expected by the registry.
export function createCharacterStateComponent(data: CharacterStateData) {
  return function CharacterStateComponent({
    size,
    className,
  }: {
    size?: number
    className?: string
  }) {
    return <PartsRenderer data={data} size={size} className={className} />
  }
}
