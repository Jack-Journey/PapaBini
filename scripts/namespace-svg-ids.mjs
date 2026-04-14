/**
 * namespace-svg-ids.mjs
 *
 * One-time fix script for BUG 1 — SVG mask/group ID collisions.
 *
 * Problem: Multiple character JSON files contain SVG with identical mask IDs
 * (e.g. mask0_0_4, mask0_0_13). When all characters render in the same DOM,
 * url(#mask0_0_4) resolves to whichever element with that ID appears first in
 * document order, causing incorrect clipping across characters.
 *
 * Fix: For every `id="..."` in each part's SVG string, prefix it with
 * `{char}_{state}_p{partIndex}_` to make it globally unique. Update all
 * matching `url(#...)` and `href="#..."` references in the same SVG string.
 *
 * The substitution is scoped per-SVG-string so it can never bleed across parts.
 * Only IDs that need fixing are modified — already-namespaced IDs (e.g. gradient
 * IDs that were namespaced at export time) are left untouched by design: the
 * prefix is only applied when the original ID is NOT already prefixed with the
 * char_state_ pattern.
 *
 * Usage: node scripts/namespace-svg-ids.mjs
 * Run from project root: ~/GitHub/PapaBini
 */

import { readFileSync, writeFileSync } from 'fs'
import { resolve, dirname } from 'path'
import { fileURLToPath } from 'url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const projectRoot = resolve(__dirname, '..')

const FILES = [
  ['flo', 'correct'],
  ['flo', 'wrong'],
  ['flo', 'smile'],
  ['kangar', 'correct'],
  ['kangar', 'wrong'],
  ['kangar', 'smile'],
  ['horn', 'correct'],
  ['horn', 'wrong'],
  ['horn', 'smile'],
  ['herzstreifen', 'correct'],
  ['herzstreifen', 'wrong'],
  ['herzstreifen', 'smile'],
  ['flex', 'correct'],
  ['flex', 'wrong'],
  ['flex', 'smile'],
  ['potatoking', 'correct'],
  ['potatoking', 'wrong'],
  ['potatoking', 'smile'],
]

/**
 * Namespace all id="..." values and their url(#...) / href="#..." references
 * within a single SVG string. Scoped to this string only — no global state.
 *
 * Strategy: collect all id values in this SVG, build a substitution map,
 * then do a single-pass replacement. Only IDs that are NOT already namespaced
 * with `{char}_{state}_` are modified.
 *
 * @param {string} svg - Raw SVG string from a JSON part
 * @param {string} prefix - e.g. "flo_correct_p4_"
 * @returns {string} - SVG with all IDs and references namespaced
 */
function namespaceSvgIds(svg, prefix) {
  // Collect all id="..." values in this SVG string
  const idPattern = /\bid="([^"]+)"/g
  const ids = new Set()
  let m
  while ((m = idPattern.exec(svg)) !== null) {
    ids.add(m[1])
  }

  if (ids.size === 0) return svg

  // Build substitution map: only namespace IDs that don't already start with prefix
  // This is idempotent — re-running the script won't double-namespace
  const substitutions = new Map()
  for (const id of ids) {
    if (!id.startsWith(prefix)) {
      substitutions.set(id, `${prefix}${id}`)
    }
  }

  if (substitutions.size === 0) return svg

  // Sort by length descending to avoid partial-match substitution errors
  // (e.g. "mask0_0_1" being replaced inside "mask0_0_13")
  const sortedOriginals = [...substitutions.keys()].sort((a, b) => b.length - a.length)

  let result = svg

  for (const original of sortedOriginals) {
    const replacement = substitutions.get(original)

    // Replace id="original" -> id="replacement"
    result = result.replaceAll(`id="${original}"`, `id="${replacement}"`)

    // Replace url(#original) -> url(#replacement)
    result = result.replaceAll(`url(#${original})`, `url(#${replacement})`)

    // Replace href="#original" -> href="#replacement"
    result = result.replaceAll(`href="#${original}"`, `href="#${replacement}"`)

    // Replace xlink:href="#original" -> xlink:href="#replacement"
    result = result.replaceAll(`xlink:href="#${original}"`, `xlink:href="#${replacement}"`)
  }

  return result
}

let totalFilesModified = 0
let totalPartsModified = 0

for (const [char, state] of FILES) {
  const filePath = resolve(projectRoot, 'src/characters/characters', char, `${state}.json`)

  let raw
  try {
    raw = readFileSync(filePath, 'utf-8')
  } catch {
    console.warn(`  SKIP — file not found: ${filePath}`)
    continue
  }

  const data = JSON.parse(raw)
  let fileModified = false

  data.parts = data.parts.map((part, index) => {
    const prefix = `${char}_${state}_p${index}_`
    const original = part.s
    const namespaced = namespaceSvgIds(original, prefix)

    if (namespaced !== original) {
      totalPartsModified++
      fileModified = true
      return { ...part, s: namespaced }
    }

    return part
  })

  if (fileModified) {
    writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n', 'utf-8')
    totalFilesModified++
    console.log(`  updated: ${char}/${state}.json`)
  } else {
    console.log(`  clean:   ${char}/${state}.json`)
  }
}

console.log(`\nDone. ${totalFilesModified} files updated, ${totalPartsModified} parts modified.`)
