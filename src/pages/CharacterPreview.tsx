import { useState } from 'react'
import { Character } from '../characters'
import type { CharacterState } from '../characters'

const STATES: CharacterState[] = ['correct', 'wrong', 'smile']

const STATE_LABELS: Record<string, string> = {
  correct: '✓ Correct',
  wrong: '✗ Wrong',
  smile: '◡ Smile',
}

export default function CharacterPreview() {
  const [activeState, setActiveState] = useState<CharacterState>('smile')

  return (
    <div className="min-h-screen bg-gray-50 p-8 font-sans">
      <h1 className="text-2xl font-bold text-gray-800 mb-2">Character Preview</h1>
      <p className="text-sm text-gray-500 mb-8">Dev page — not part of game routing</p>

      {/* State toggle */}
      <div className="flex gap-3 mb-12">
        {STATES.map(s => (
          <button
            key={s}
            onClick={() => setActiveState(s)}
            className={[
              'px-5 py-3 rounded-2xl text-sm font-semibold transition-all min-h-[56px]',
              activeState === s
                ? 'bg-teal-400 text-white shadow-md scale-105'
                : 'bg-white text-gray-600 shadow-sm hover:shadow-md',
            ].join(' ')}
          >
            {STATE_LABELS[s] ?? s}
          </button>
        ))}
      </div>

      {/* All sizes — animated */}
      <section className="mb-12">
        <h2 className="text-xs font-semibold uppercase tracking-widest text-gray-400 mb-6">
          Flo — {activeState} — all sizes
        </h2>
        <div className="flex items-end gap-10 flex-wrap">
          {(['sm', 'md', 'lg'] as const).map(size => (
            <div key={size} className="flex flex-col items-center gap-3">
              <Character id="flo" state={activeState} size={size} />
              <span className="text-xs text-gray-400 font-mono">{size}</span>
            </div>
          ))}
        </div>
      </section>

      {/* All states side-by-side at md */}
      <section>
        <h2 className="text-xs font-semibold uppercase tracking-widest text-gray-400 mb-6">
          Flo — all states — md
        </h2>
        <div className="flex items-end gap-10 flex-wrap">
          {STATES.map(s => (
            <div key={s} className="flex flex-col items-center gap-3">
              <Character id="flo" state={s} size="md" />
              <span className="text-xs text-gray-400 font-mono">{s}</span>
            </div>
          ))}
        </div>
      </section>
    </div>
  )
}
