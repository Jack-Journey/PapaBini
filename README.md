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
- `@source not` lines in `src/index.css`. These exclude markdown and the private names. The markdown types are `.md`, `.MD`, `.mdx` and `.markdown`; revisit the glob if MDX is ever adopted. The private names are covered only as real files and directories at the repo root. A symlink at one of those names is not covered, and neither are the same names deeper in the tree. The `.gitignore` rules ending in `/` match directories only, so a symlink to a file at one of those names is scanned even with both layers in place.

Neither layer covers a private file under another name.

`scripts/` is excluded from the scan by an `@source not` line too: it holds repo tooling, and plain words in it would add CSS.

To check the scan after changing `src/index.css`, `.gitignore`, `vite.config.ts` or the Tailwind version, run `npm run check:scan`. It is a hand-run check, not CI.

- **What it checks.** By default it checks your working tree: every tracked file as it is on disk, uncommitted edits included. Use `-- --ref <rev>` to check a commit instead, and use it only on commits you trust, because it runs that commit's build config. The check plants sentinel classes in a throwaway copy. It then checks that the root `index.html` and every directory under `src/` reach the CSS, and that markdown, the private names and `scripts/` do not.
- **Why both layers are tested on their own.** It runs once with `.gitignore` as committed and once with the private rules removed. A control build with both layers removed must leak every exclusion sentinel. If one stays hidden, the check exits 2, because the layer test is blind.
- **Known gaps.** The symlink cases are pinned as known gaps. A new gap, or a pinned one that closes, fails the check.
- **Your own checkout.** `npm run check:scan -- --audit` fails if an untracked file, or a file reached through a symlink, feeds the CSS. It models Tailwind 4.2.2 and exits 2 on any other installed version until the model is re-read.
- **Side effect.** Each build writes a transient file under `node_modules/.vite-temp/` and deletes it afterwards.

If `src/index.css` moves, rewrite every `../` in it. The lines resolve against the file's new directory. From `src/styles/`, `../resources` means `src/resources/`, which can drop real CSS. The repo-root names are then no longer excluded by those lines. See the comment in `src/index.css`.

## Languages
English · German · Traditional Chinese (繁體中文 with Pinyin)
