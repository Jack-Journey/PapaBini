# PapaBini

A multi-game platform for father and child.

## Games
- **Math Adventure** — mental arithmetic for school years 1 to 4 (math) (game #1, in development)

## Stack
- React + TypeScript + Vite + Tailwind v4
- UI kit TBD

## Development

```bash
npm install
npm run dev
```

### Tailwind scan scope and `.gitignore`

Tailwind scans the whole repo root for class names. It skips anything `.gitignore` ignores, and markdown, which `src/index.css` excludes. So the private-folder rules in `.gitignore` (`CLAUDE.md`, `.claude/`, `design/`, `team/`, `research/`, `resources/`, `to-be-filed/`) are load-bearing. They keep private content out of the shipped CSS as well as out of git. Do not remove them without changing the scan. See the comment in `src/index.css`.

## Languages
English · German · Traditional Chinese (繁體中文 with Pinyin)
