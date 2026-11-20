#!/usr/bin/env bash
#
# check-tailwind-scan.sh - hand-run check of which files feed the public CSS.
#
# Papabini #35. Not wired into CI (Jack, 11-06: a hand-run check script is
# enough for now). Run it after any change to src/index.css, .gitignore,
# vite.config.ts, the Tailwind version, or where the stylesheet lives.
#
#   npm run check:scan                  sentinel check on the committed HEAD
#   npm run check:scan -- --worktree    same, on the working tree's tracked
#                                       files, uncommitted edits included
#   npm run check:scan -- --ref <rev>   same, on any commit
#   npm run check:scan -- --audit       audit THIS checkout's real inputs
#
# Exit: 0 = every row passed. 1 = at least one row failed. 2 = the check could
# not run (build failed, no CSS emitted, bad input). It fails closed.
#
# THE CRITERION IS COVERAGE, NOT A DIGEST. A byte-identical or digest pin is
# satisfied by a no-op or a revert, so it proves nothing about the scan.
# Instead, sentinel classes (arbitrary values, unused anywhere else) are
# planted in a throwaway copy, and the emitted CSS is read:
#
#   PRESENT  root index.html, src/, nested src/, public/ if it exists.
#            The root sentinel is the control for over-narrowing: a scan
#            rooted at src/ (the old `source(".")` shape) drops it.
#   ABSENT   markdown (.md .MD .mdx .markdown, at the root and in src/),
#            each private root name (CLAUDE.md .claude design team research
#            resources to-be-filed), and scripts/ (this tooling).
#            Checked twice: with .gitignore as committed, and with the
#            private .gitignore rules REMOVED, which proves the
#            `@source not` lines on their own.
#   UNIQUE   every sentinel is absent from a clean build of the same copy,
#            so no PRESENT row can pass by accident.
#   MOVES    the planted build's CSS differs from the clean build's
#            (anti-vacuity: the scan is on at all).
#
# The copy lives in `mktemp -d` outside the repo, is filled from
# `git archive` (or the tracked working-tree files), and reuses the repo's
# node_modules through a symlink. Nothing is planted in the real checkout.
# The copy is `git init`-ed so the scanner treats it as a git repo, like
# the real checkout. The trap removes it on every exit path.
#
# --audit reads the real checkout without writing to it. It asks Tailwind's
# own scanner for its input files (scripts/tailwind-scan-inputs.mjs) and
# fails on any input that is not a tracked file, and on any input reached
# through a symlink. `git check-ignore` is NOT used as the oracle: the
# scanner ignores global git excludes, so git can call a file ignored while
# Tailwind still scans it.
#
# KNOWN GAPS (reported, never counted as a pass):
#   - A symlink at a private name leaks its target's classes. The sentinel
#     run prints GAP rows for research -> a directory and team -> a file,
#     with both layers and with `@source not` alone. Measured on 4.2.2: the
#     file symlink leaks in both runs; the directory symlink is caught by
#     the `research/` .gitignore rule and leaks when that rule is removed.
#     The `@source not` lines do not cover either. This is the documented
#     state, not a pass. A "no leak" NOTE where a GAP is expected means
#     the gap may have closed; re-read the scanner before relying on it.
#   - A moved stylesheet is not exercised. Moving src/index.css without
#     rewriting its `../` paths shifts every `@source not` line.
#   - Private names deeper than the root (e.g. src/design/) are covered by
#     .gitignore only. They are not planted here.
#   - The sentinel run checks the committed files only. Untracked files and
#     local symlinks in your checkout are what --audit is for.
#   - --audit models how @tailwindcss/vite 4.2.2 builds its scanner sources.
#     Its positive controls fail the audit if that model stops matching.
#   - `tsc -b` is not run. Only `vite build` produces the CSS.
#
# bash 3.2 compatible (macOS /bin/bash): no mapfile, no associative arrays.

set -u
set -o pipefail

GREP=/usr/bin/grep
CSS_ENTRY="src/index.css"
PRIVATE_NAMES="CLAUDE.md .claude design team research resources to-be-filed"
# The .gitignore rules for those names, removed in the second-layer run.
PRIVATE_RULES="CLAUDE.md .claude/ design/ team/ research/ resources/ to-be-filed/"

MODE="sentinel"
REF="HEAD"
FROM_WORKTREE=0

usage() {
  sed -n '9,14p' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --audit) MODE="audit" ;;
    --worktree) FROM_WORKTREE=1 ;;
    --ref)
      [ $# -ge 2 ] || { echo "check-tailwind-scan: --ref needs a revision" >&2; exit 2; }
      REF="$2"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "check-tailwind-scan: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P) || exit 2
REPO=$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null) || {
  echo "check-tailwind-scan: not inside a git checkout" >&2; exit 2; }
REPO=$(cd "$REPO" && pwd -P) || exit 2

FAILS=0
GAPS=0

# die: fail closed. Prints to stderr so the message survives a $(...) capture.
die() {
  printf 'FAIL  %s\n' "$1" >&2
  echo "check-tailwind-scan: could not complete the check (fail closed)." >&2
  exit 2
}
pass() { printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; FAILS=$((FAILS + 1)); }
gap()  { printf 'GAP   %s\n' "$1"; GAPS=$((GAPS + 1)); }
note() { printf 'NOTE  %s\n' "$1"; }

# node_modules: reuse the repo's install, read-only. Resolve the real path so
# a symlinked node_modules in the checkout still works.
[ -d "$REPO/node_modules/.bin" ] || die "no node_modules in $REPO (run npm install first)"
NM=$(cd "$REPO/node_modules" && pwd -P) || die "cannot resolve node_modules"

# --- audit mode --------------------------------------------------------------

if [ "$MODE" = "audit" ]; then
  [ "$FROM_WORKTREE" -eq 0 ] && [ "$REF" = "HEAD" ] || die "--audit takes no --ref or --worktree"
  [ -f "$REPO/$CSS_ENTRY" ] || die "no $CSS_ENTRY in $REPO"

  AUDIT_TMP=$(mktemp -d "${TMPDIR:-/tmp}/tw-scan-audit.XXXXXX") || die "mktemp failed"
  trap 'rm -rf "$AUDIT_TMP"' EXIT
  trap 'exit 130' INT TERM

  # Side effect: none on the checkout. The helper only reads files.
  (cd "$REPO" && node "$SCRIPT_DIR/tailwind-scan-inputs.mjs" "$REPO" "$CSS_ENTRY") \
    > "$AUDIT_TMP/inputs.tsv" 2> "$AUDIT_TMP/inputs.err"
  rc=$?
  [ "$rc" -eq 0 ] || { cat "$AUDIT_TMP/inputs.err" >&2; die "scanner helper exited $rc"; }

  git -C "$REPO" ls-files > "$AUDIT_TMP/tracked.txt" || die "git ls-files failed"

  # Positive controls: the helper must reproduce the known shape of the scan.
  # If it does not, it no longer models the build and its answer is void.
  $GREP -q -F -- "$REPO/index.html	" "$AUDIT_TMP/inputs.tsv" \
    || die "audit control: root index.html is not a scanner input (model mismatch)"
  $GREP -q -F -- "$REPO/src/" "$AUDIT_TMP/inputs.tsv" \
    || die "audit control: no file under src/ is a scanner input (model mismatch)"
  if $GREP -q -F -- "$REPO/README.md	" "$AUDIT_TMP/inputs.tsv"; then
    die "audit control: README.md is a scanner input (model mismatch)"
  fi

  count=0
  while IFS='	' read -r file real; do
    [ -n "$file" ] || continue
    count=$((count + 1))
    rel="${file#"$REPO"/}"
    if [ "$rel" = "$file" ]; then
      fail "input outside the repo root: $file"
      continue
    fi
    if [ "$real" != "$file" ]; then
      fail "input reached through a symlink: $rel -> $real"
      continue
    fi
    if [ "$rel" = ".git" ] && [ -f "$file" ]; then
      note ".git is a worktree pointer file and is scanned (paths only, no classes)"
      continue
    fi
    if ! $GREP -q -F -x -- "$rel" "$AUDIT_TMP/tracked.txt"; then
      fail "untracked file feeds the public CSS: $rel"
    fi
  done < "$AUDIT_TMP/inputs.tsv"

  [ "$count" -gt 0 ] || die "scanner reported no input files"
  echo "audit: $count scanner inputs read from $REPO"
  if [ "$FAILS" -gt 0 ]; then
    echo "check-tailwind-scan --audit: $FAILS input(s) would feed the public CSS but are not tracked files." >&2
    echo "Remove them, or ignore them in the repo .gitignore (global excludes do not count)." >&2
    exit 1
  fi
  pass "every scanner input is a tracked file, none reached through a symlink"
  exit 0
fi

# --- sentinel mode -----------------------------------------------------------

TMP=$(mktemp -d "${TMPDIR:-/tmp}/tw-scan-check.XXXXXX") || die "mktemp failed"
case "$TMP" in
  "$REPO"|"$REPO"/*) rm -rf "$TMP"; die "temp dir is inside the repo: $TMP" ;;
esac
# Side effect: everything below is written under $TMP, removed on exit.
trap 'rm -rf "$TMP"' EXIT
trap 'exit 130' INT TERM

if [ "$FROM_WORKTREE" -eq 1 ]; then
  SOURCE_LABEL="working tree (tracked files)"
else
  git -C "$REPO" rev-parse --verify -q "$REF^{commit}" >/dev/null || die "unknown revision: $REF"
  SOURCE_LABEL="$REF ($(git -C "$REPO" rev-parse --short "$REF^{commit}"))"
fi
echo "check-tailwind-scan: $SOURCE_LABEL"

# The sentinel class for number N. Composed at run time so the literal never
# appears in this file. Arbitrary values, so no real code uses them.
sentinel_class() { printf '%s-[%spx]' w "$1"; }
# The same class as it appears in emitted CSS: .w-\[3501px\]
sentinel_selector() { printf '.%s-\\[%spx\\]' w "$1"; }

# populate DEST: fill DEST with the source files, link node_modules, git init.
populate() {
  local dest="$1"
  mkdir -p "$dest" || die "mkdir $dest failed"
  if [ "$FROM_WORKTREE" -eq 1 ]; then
    (cd "$REPO" && git ls-files -z | tar -cf - --null -T -) | tar -xf - -C "$dest" \
      || die "copying tracked working-tree files failed"
  else
    git -C "$REPO" archive --format=tar "$REF" | tar -xf - -C "$dest" \
      || die "git archive $REF failed"
  fi
  [ -f "$dest/$CSS_ENTRY" ] || die "no $CSS_ENTRY in the copy (stylesheet moved? this check assumes $CSS_ENTRY)"
  [ -f "$dest/index.html" ] || die "no root index.html in the copy"
  ln -s "$NM" "$dest/node_modules" || die "linking node_modules failed"
  git -c init.defaultBranch=main init -q "$dest" || die "git init in the copy failed"
}

# build DEST: vite build in DEST; prints the path of the single emitted CSS.
build() {
  local dest="$1" log="$1.build.log" rc
  (cd "$dest" && ./node_modules/.bin/vite build --logLevel error --emptyOutDir) > "$log" 2>&1
  rc=$?
  if [ "$rc" -ne 0 ]; then
    cat "$log" >&2
    die "vite build failed (rc $rc) in $(basename "$dest")"
  fi
  set -- "$dest"/dist/assets/*.css
  [ $# -eq 1 ] && [ -f "$1" ] || die "build emitted $# CSS files in $(basename "$dest") (expected exactly 1)"
  [ -s "$1" ] || die "emitted CSS is empty in $(basename "$dest")"
  printf '%s\n' "$1"
}

# plant PATH N: write a file at PATH whose only content uses sentinel N.
plant() {
  mkdir -p "$(dirname "$1")" || die "mkdir for $1 failed"
  printf '<div class="%s"></div>\n' "$(sentinel_class "$2")" > "$1" || die "planting $1 failed"
}

# in_css CSS N: true if sentinel N's rule is in the emitted CSS.
in_css() { $GREP -q -F -- "$(sentinel_selector "$2")" "$1"; }

# --- the rows ----------------------------------------------------------------
# PRESENT rows: "N|path relative to the copy|label". index.html is edited in
# place; the others are new files.
PRESENT_ROWS="3501|index.html|root index.html
3502|src/scan-sentinel.tsx|src/
3503|src/characters/scan-sentinel.ts|nested src/"

ABSENT_ROWS="3511|scan-sentinel.md|markdown .md (root)
3512|scan-sentinel.MD|markdown .MD (root)
3513|scan-sentinel.mdx|markdown .mdx (root)
3514|scan-sentinel.markdown|markdown .markdown (root)
3515|src/notes/scan-sentinel.md|markdown .md (src/)
3516|src/notes/scan-sentinel.MD|markdown .MD (src/)
3517|src/notes/scan-sentinel.mdx|markdown .mdx (src/)
3518|src/notes/scan-sentinel.markdown|markdown .markdown (src/)
3521|CLAUDE.md|private CLAUDE.md
3522|.claude/scan-sentinel.html|private .claude/
3523|design/scan-sentinel.html|private design/
3524|team/scan-sentinel.html|private team/
3525|research/scan-sentinel.html|private research/
3526|resources/scan-sentinel.html|private resources/
3527|to-be-filed/scan-sentinel.html|private to-be-filed/
3531|scripts/scan-sentinel.html|tooling scripts/"

PUBLIC_N=3504
GAP_DIR_N=3541
GAP_FILE_N=3542
ALL_NUMS="3501 3502 3503 $PUBLIC_N 3511 3512 3513 3514 3515 3516 3517 3518 3521 3522 3523 3524 3525 3526 3527 3531 $GAP_DIR_N $GAP_FILE_N"

# plant_all DEST: plant every PRESENT and ABSENT sentinel in DEST.
plant_all() {
  local dest="$1" n p label
  while IFS='|' read -r n p label; do
    [ -n "$n" ] || continue
    if [ "$p" = "index.html" ]; then
      # Insert the sentinel before </body>, then prove the insert happened.
      awk -v cls="$(sentinel_class "$n")" \
        '/<\/body>/ && !done { print "    <div class=\"" cls "\"></div>"; done=1 } { print }' \
        "$dest/index.html" > "$dest/index.html.new" || die "editing index.html failed"
      mv "$dest/index.html.new" "$dest/index.html" || die "editing index.html failed"
      $GREP -q -F -- "$(sentinel_class "$n")" "$dest/index.html" \
        || die "root sentinel was not written into index.html (no </body>?)"
    else
      plant "$dest/$p" "$n"
    fi
  done <<EOF
$PRESENT_ROWS
EOF
  if [ -d "$dest/public" ]; then
    plant "$dest/public/scan-sentinel.html" "$PUBLIC_N"
  fi
  while IFS='|' read -r n p label; do
    [ -n "$n" ] || continue
    plant "$dest/$p" "$n"
  done <<EOF
$ABSENT_ROWS
EOF
}

# strip_private_rules DEST: remove the private-name rules from DEST/.gitignore.
strip_private_rules() {
  local dest="$1" rules="$TMP/private-rules.txt" r before after
  : > "$rules"
  for r in $PRIVATE_RULES; do printf '%s\n' "$r" >> "$rules"; done
  before=$(wc -l < "$dest/.gitignore" | tr -d ' ')
  $GREP -v -x -F -f "$rules" "$dest/.gitignore" > "$dest/.gitignore.new"
  # grep -v exits 1 when every line was removed; only >1 is an error.
  [ $? -le 1 ] || die "filtering .gitignore failed"
  mv "$dest/.gitignore.new" "$dest/.gitignore" || die "rewriting .gitignore failed"
  after=$(wc -l < "$dest/.gitignore" | tr -d ' ')
  for r in $PRIVATE_RULES; do
    if $GREP -q -F -x -- "$r" "$dest/.gitignore"; then die "rule $r still in the stripped .gitignore"; fi
  done
  note "second-layer run: removed $((before - after)) private rule(s) from .gitignore"
}

# check_rows CSS LABEL: assert PRESENT rows present, ABSENT rows absent.
check_rows() {
  local css="$1" run="$2" n p label
  while IFS='|' read -r n p label; do
    [ -n "$n" ] || continue
    if in_css "$css" "$n"; then pass "[$run] PRESENT $label"
    else fail "[$run] PRESENT $label: sentinel missing from the CSS (scan does not cover it)"; fi
  done <<EOF
$PRESENT_ROWS
EOF
  if [ "$HAS_PUBLIC" -eq 1 ]; then
    if in_css "$css" "$PUBLIC_N"; then pass "[$run] PRESENT public/"
    else fail "[$run] PRESENT public/: sentinel missing from the CSS"; fi
  fi
  while IFS='|' read -r n p label; do
    [ -n "$n" ] || continue
    if in_css "$css" "$n"; then fail "[$run] ABSENT $label: sentinel leaked into the CSS"
    else pass "[$run] ABSENT $label"; fi
  done <<EOF
$ABSENT_ROWS
EOF
}

# 1. Clean build: no plants. Every sentinel must be absent (UNIQUE).
populate "$TMP/clean"
HAS_PUBLIC=0
[ -d "$TMP/clean/public" ] && HAS_PUBLIC=1
CLEAN_CSS=$(build "$TMP/clean") || exit 2
unique_ok=1
for n in $ALL_NUMS; do
  if in_css "$CLEAN_CSS" "$n"; then
    fail "UNIQUE sentinel $(sentinel_class "$n") is already in a clean build; pick another"
    unique_ok=0
  fi
done
[ "$unique_ok" -eq 1 ] && pass "UNIQUE no sentinel appears in a clean build"
if [ "$HAS_PUBLIC" -eq 0 ]; then
  note "public/ does not exist in this tree; its PRESENT row is skipped"
fi

# 2. Planted build, .gitignore as committed (both layers).
populate "$TMP/both"
plant_all "$TMP/both"
BOTH_CSS=$(build "$TMP/both") || exit 2
check_rows "$BOTH_CSS" "both layers"

# 3. Anti-vacuity: the src/ sentinel moved the output.
if cmp -s "$CLEAN_CSS" "$BOTH_CSS"; then
  fail "MOVES planted build CSS is identical to the clean build: the scan is off"
elif in_css "$BOTH_CSS" 3502; then
  pass "MOVES a src/ mutant changes the emitted CSS"
else
  fail "MOVES the CSS changed, but not by the src/ sentinel"
fi

# 4. Planted build with the private .gitignore rules removed: proves the
#    `@source not` layer on its own.
populate "$TMP/layer2"
strip_private_rules "$TMP/layer2"
plant_all "$TMP/layer2"
L2_CSS=$(build "$TMP/layer2") || exit 2
check_rows "$L2_CSS" "@source not only"

# 5. KNOWN GAP: symlinks at private names, run with .gitignore as committed
#    and with the private rules removed. Reported as GAP, never as PASS.
mkdir -p "$TMP/outside/dir" || die "mkdir outside failed"
plant "$TMP/outside/dir/scan-sentinel.html" "$GAP_DIR_N"
plant "$TMP/outside/file.html" "$GAP_FILE_N"

# gap_run NAME RUN-LABEL STRIP: one copy with research -> outside dir and
# team -> outside file; STRIP=1 removes the private .gitignore rules first.
gap_run() {
  local dest="$TMP/$1" run="$2" css
  populate "$dest"
  [ "$3" -eq 1 ] && strip_private_rules "$dest"
  ln -s "$TMP/outside/dir" "$dest/research" || die "symlink failed"
  ln -s "$TMP/outside/file.html" "$dest/team" || die "symlink failed"
  css=$(build "$dest") || exit 2
  if in_css "$css" "$GAP_DIR_N"; then gap "[$run] symlink research -> outside directory LEAKS into the CSS (known, unfixed)"
  else note "[$run] symlink research -> outside directory: no leak"; fi
  if in_css "$css" "$GAP_FILE_N"; then gap "[$run] symlink team -> outside file LEAKS into the CSS (known, unfixed)"
  else note "[$run] symlink team -> outside file: no leak"; fi
}
gap_run gap-both "both layers" 0
gap_run gap-layer2 "@source not only" 1

echo
if [ "$FAILS" -gt 0 ]; then
  echo "check-tailwind-scan: $FAILS row(s) FAILED ($GAPS known gap(s) reported)." >&2
  exit 1
fi
echo "check-tailwind-scan: all rows passed. $GAPS known gap(s) reported, not counted as passes."
exit 0
