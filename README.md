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

Tailwind scans the whole repo root for class names. Every file there that is not ignored is a CSS input. That includes untracked files under any name, and the targets of symlinks, which the scanner follows. "Ignored" means the repo's `.gitignore`, plus `.git/info/exclude` in a git repo. Global git excludes are **not** honoured, so `git status` can show a file as ignored while Tailwind still scans it.

Private paths and build output are kept out in two ways:

- Rules in `.gitignore`. These are load-bearing for the CSS as well as for git: `CLAUDE.md`, `.claude/`, `design/`, `team/`, `research/`, `resources/`, `to-be-filed/`, `dist/` and `.vite/`. Without the `dist/` rule, a stale build feeds the next one.
- `@source not` lines in `src/index.css`. These exclude the private paths and markdown.

Neither covers a private file under another name. See the comment in `src/index.css`.

## Languages
English · German · Traditional Chinese (繁體中文 with Pinyin)
