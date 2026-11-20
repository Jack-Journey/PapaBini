// Prints the files Tailwind's scanner reads for this repo, one per line as
// "<path>\t<realpath>". Used by `check-tailwind-scan.sh --audit`.
//
// Usage: node scripts/tailwind-scan-inputs.mjs <repo-root> <css-entry>
//
// It builds the scanner's sources the same way @tailwindcss/vite 4.2.2 does
// (dist/index.mjs, class B `generate`): compile the entry stylesheet with
// base = the stylesheet's directory, then
//   root === "none" -> no root source
//   root === null   -> { base: <vite root>, pattern: "**/*" }
//   otherwise       -> the `source(...)` root
// followed by every `@source` / `@source not` line.
//
// ASSUMPTIONS. This is a model of the plugin, not the build:
//   - The Vite root is the repo root (vite.config.ts sets no `root`).
//     The plugin uses config.root; this file uses <repo-root>.
//   - The installed @tailwindcss/vite, /node and /oxide are 4.2.2.
// check-tailwind-scan.sh --audit exits 2 if either assumption fails, so an
// upgrade forces a re-read of the plugin before the audit is trusted. Its
// three positive controls catch only gross mismatches; they cannot see
// this model missing a source a newer plugin adds.
//
// Read-only: it reads files and writes nothing.

import { compile } from '@tailwindcss/node'
import { Scanner } from '@tailwindcss/oxide'
import fs from 'node:fs'
import path from 'node:path'

const [repoRoot, cssEntry] = process.argv.slice(2)
if (!repoRoot || !cssEntry) {
  process.stderr.write('usage: tailwind-scan-inputs.mjs <repo-root> <css-entry>\n')
  process.exit(2)
}

const cssPath = path.resolve(repoRoot, cssEntry)
// Side effect: reads the entry stylesheet from disk.
const compiler = await compile(fs.readFileSync(cssPath, 'utf8'), {
  base: path.dirname(cssPath),
  onDependency() {},
})

const rootSources =
  compiler.root === 'none'
    ? []
    : compiler.root === null
      ? [{ base: repoRoot, pattern: '**/*', negated: false }]
      : [{ ...compiler.root, negated: false }]

const scanner = new Scanner({ sources: rootSources.concat(compiler.sources) })
// Side effect: walks the file tree. `files` is only populated after scan().
scanner.scan()

for (const file of scanner.files) {
  let real = file
  try {
    real = fs.realpathSync(file)
  } catch {
    real = '<unresolvable>'
  }
  process.stdout.write(`${file}\t${real}\n`)
}
