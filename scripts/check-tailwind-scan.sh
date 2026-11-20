#!/usr/bin/env bash
#
# check-tailwind-scan.sh - hand-run check of which files feed the public CSS.
#
# Papabini #35. Not wired into CI (Jack, 11-06: a hand-run check script is
# enough for now). Run it after any change to src/index.css, .gitignore,
# vite.config.ts, the Tailwind version, or where the stylesheet lives.
#
#   npm run check:scan                  sentinel check on the WORKING TREE:
#                                       every tracked file as it is on disk,
#                                       uncommitted edits included
#   npm run check:scan -- --ref <rev>   same, on a commit (e.g. --ref HEAD)
#   npm run check:scan -- --audit       audit THIS checkout's real inputs
#
# The default reads the working tree on purpose: the edit you just made to
# src/index.css or .gitignore is the thing to check, committed or not.
# (`--worktree` is still accepted and means the default.) Untracked files
# are not copied; --audit is the check for those.
#
# Exit: 0 = every row passed.
#       1 = at least one coverage row FAILED. A FAIL row that has been scored
#           always reaches the "N row(s) FAILED" summary and exit 1, even
#           when a later step (a strip, the control build, a build) then
#           cannot complete; that step's reason is printed after the summary.
#       2 = NO coverage row failed, and the check could not run or could not
#           trust its own controls (build failed, no CSS emitted, a strip or
#           control build did not do what it claims). It fails closed.
#
# THE CRITERION IS COVERAGE, NOT A DIGEST. A byte-identical or digest pin is
# satisfied by a no-op or a revert, so it proves nothing about the scan.
# Instead, sentinel classes (arbitrary values, unused anywhere else) are
# planted in a throwaway copy, and the emitted CSS is read:
#
#   PRESENT  root index.html, and EVERY directory under src/ (enumerated at
#            run time from the copy), and public/ if it exists. The root
#            sentinel is the control for a scan rooted at src/ (the old
#            `source(".")` shape); the per-directory sentinels catch an
#            exclusion or glob that drops any one src/ directory.
#   ABSENT   markdown (.md .MD .mdx .markdown, at the root and in src/),
#            each private root name (CLAUDE.md .claude design team research
#            resources to-be-filed), and scripts/ (this tooling) when the
#            tree has it.
#            Checked twice: with .gitignore as committed, and with the
#            private .gitignore rules removed ("@source not only").
#   FILES    every file under src/ of a source type (ts tsx js jsx mjs cjs
#            css html) is a scanner input, per tailwind-scan-inputs.mjs run
#            on the copy. Catches exclusions by file name or extension
#            (e.g. `@source not "../src/**/*.ts"`), which keep every
#            directory sentinel green. Uses the same version-pinned model as
#            --audit, so the sentinel run also exits 2 on a Tailwind version
#            the model was not read from.
#   CONTROL  The "@source not only" run is trusted only if its strip is
#            proven. The strip must remove exactly the expected number of
#            rules (else exit 2). And a control build with BOTH layers
#            removed (private rules stripped AND every `@source not` line
#            deleted) must LEAK every private, markdown and scripts plant.
#            If one stays hidden, some other rule is covering it, the layer
#            test is blind, and the run exits 2.
#   UNIQUE   every sentinel is absent from a clean build of the same copy,
#            so no PRESENT row can pass by accident.
#   MOVES    the planted build's CSS differs from the clean build's
#            (anti-vacuity: the scan is on at all).
#   GAP      symlinks at private names. The set of rows that leak is pinned
#            (EXPECTED_GAPS below, measured on Tailwind 4.2.2). A gap that is
#            not in the pin, or a pinned gap that stops leaking, is a FAIL
#            row: either one means the boundary moved.
#
# The copy lives in `mktemp -d` outside the repo, is filled from the tracked
# working-tree files (or `git archive` with --ref), and reuses the repo's
# node_modules through a symlink. No sentinel is planted in the real
# checkout. The copy is `git init`-ed so the scanner treats it as a git
# repo, like the real checkout. The trap removes it on every exit path.
#
# SIDE EFFECTS OUTSIDE THE COPY. node_modules is shared, not strictly
# read-only: each `vite build` bundles the copy's vite.config.ts into
# node_modules/.vite-temp/ (through the symlink, so in the REAL install) and
# deletes it afterwards. A run killed at that moment can leave a stray .mjs.
#
# TRUST. --ref runs THAT commit's vite.config.ts and plugins with your user
# rights, and they can write into the shared node_modules. Use --ref only on
# commits you trust; never on an unreviewed fork branch.
#
# --audit reads the real checkout without writing to it. It asks Tailwind's
# own scanner for its input files (scripts/tailwind-scan-inputs.mjs) and
# fails on any input that is not a tracked file, and on any input reached
# through a symlink. `git check-ignore` is NOT used as the oracle: the
# scanner ignores global git excludes, so git can call a file ignored while
# Tailwind still scans it.
#   The helper re-creates how @tailwindcss/vite 4.2.2 builds its scanner
#   sources. It is a model, not the build. So --audit exits 2 unless the
#   installed @tailwindcss/vite, @tailwindcss/node and @tailwindcss/oxide
#   are exactly MODEL_VERSION, and unless vite.config.ts sets no `root`
#   (the model assumes the Vite root is the repo root). Its three positive
#   controls (index.html scanned, something under src/ scanned, README.md
#   not scanned) catch only gross mismatches; they cannot see the model
#   under-reporting a source it does not know about. The version pin is
#   what forces a re-read on upgrade.
#
# KNOWN GAPS (reported, never counted as a pass):
#   - A symlink at a private name leaks its target's classes. Measured on
#     4.2.2: team -> a file leaks with both layers; research -> a directory
#     is caught by the `research/` .gitignore rule and leaks with the
#     `@source not` lines alone. Neither `@source not` line covers a
#     symlink. These print as GAP rows and are pinned.
#   - A moved stylesheet is not exercised. Moving src/index.css without
#     rewriting its `../` paths shifts every `@source not` line.
#   - Private names deeper than the root (e.g. src/design/) are covered by
#     .gitignore only. They are not planted here.
#   - Untracked files and local symlinks in your checkout are not copied.
#     --audit is the check for those.
#   - --worktree with a tracked file deleted but not staged exits 2.
#   - FILES covers src/ only, and only the listed types. A file under src/
#     that a .gitignore rule ignores on purpose would show as a FILES FAIL.
#   - A path under src/ containing '|' or a newline, or a symlink on any
#     plant path inside the copy, stops the run (exit 2).
#   - `tsc -b` is not run. Only `vite build` produces the CSS.
#
# bash 3.2 compatible (macOS /bin/bash): no mapfile, no associative arrays.

set -u
set -o pipefail

GREP=/usr/bin/grep
CSS_ENTRY="src/index.css"
# The .gitignore rules for the private names, removed in the second-layer
# and control runs. The strip must remove exactly this many.
PRIVATE_RULES="CLAUDE.md .claude/ design/ team/ research/ resources/ to-be-filed/"
PRIVATE_RULE_COUNT=7
# The Tailwind version the --audit model was read from.
MODEL_VERSION="4.2.2"
# GAP rows that leak today (Tailwind 4.2.2), one per line, exact names.
# PRIVATE_RULES, PRIVATE_RULE_COUNT and EXPECTED_GAPS move TOGETHER: adding,
# respelling or removing a private .gitignore rule changes which rules the
# strip removes, how many, and which symlink gaps leak in which run.
EXPECTED_GAPS="[both layers] team -> outside file
[@source not only] research -> outside directory
[@source not only] team -> outside file"

MODE="sentinel"
REF=""
NL='
'
# File types under src/ that must each be a scanner input (FILES rows).
SRC_SCANNED_EXT="ts tsx js jsx mjs cjs css html"

usage() {
  cat <<'USAGE'
check-tailwind-scan.sh                 sentinel check on the working tree
check-tailwind-scan.sh --ref <rev>     sentinel check on a commit
check-tailwind-scan.sh --audit         audit this checkout's real scanner inputs
Exit 0 = every row passed.
Exit 1 = at least one coverage row FAILED (always wins once a row has failed;
         a later step that could not complete is reported after the summary).
Exit 2 = no row failed, but the check could not run or trust its controls.
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --audit) MODE="audit" ;;
    --worktree) REF="" ;;
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

TMP=""
# summary_failed: the closing line for a run with FAIL rows (stderr).
summary_failed() {
  echo >&2
  echo "check-tailwind-scan: $FAILS row(s) FAILED ($GAPS pinned gap(s) reported)." >&2
}

# stop_run REASON: the single exit path for a step that cannot complete.
# Precedence: if any coverage row has already FAILED, those rows stand. Print
# the FAILED summary, then REASON, and exit 1. Only a run with no failed row
# exits 2 (fail closed).
stop_run() {
  if [ "$FAILS" -gt 0 ]; then
    summary_failed
    printf 'STOP  %s\n' "$1" >&2
    echo "check-tailwind-scan: the run stopped at the step above; the FAIL rows already scored stand (exit 1)." >&2
    exit 1
  fi
  printf 'FAIL  %s\n' "$1" >&2
  echo "check-tailwind-scan: could not complete the check (fail closed, exit 2)." >&2
  exit 2
}

# die REASON: stop. Inside a $(...) subshell it records REASON and exits 3;
# the caller's `|| bail` then decides the exit code in the parent shell,
# where FAILS is authoritative, so the reason prints after the summary.
die() {
  if [ "${BASH_SUBSHELL:-0}" -gt 0 ] && [ -n "${TMP:-}" ] && [ -d "$TMP" ]; then
    printf '%s\n' "$1" > "$TMP/stop.reason"
    exit 3
  fi
  stop_run "$1"
}

# bail: handle a failed $(...) step in the parent shell.
bail() {
  local rc="$1" reason="a step exited $1 without a reason"
  if [ -f "$TMP/stop.reason" ]; then reason=$(cat "$TMP/stop.reason"); fi
  stop_run "$reason"
}

pass() { printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; FAILS=$((FAILS + 1)); }
gap()  { printf 'GAP   %s\n' "$1"; GAPS=$((GAPS + 1)); }
note() { printf 'NOTE  %s\n' "$1"; }

# node_modules: reuse the repo's install (shared; vite writes .vite-temp in
# it, see the header). Resolve the real path so a symlinked node_modules in
# the checkout still works.
[ -d "$REPO/node_modules/.bin" ] || die "no node_modules in $REPO (run npm install first)"
NM=$(cd "$REPO/node_modules" && pwd -P) || die "cannot resolve node_modules"

# pkg_version NAME: the installed version of package NAME, read from its
# package.json by path (some packages do not export package.json).
pkg_version() {
  node -e 'process.stdout.write(String(JSON.parse(require("fs").readFileSync(process.argv[1], "utf8")).version))' \
    "$NM/$1/package.json" 2>/dev/null
}

# require_model_version: the scanner-input model (tailwind-scan-inputs.mjs)
# is valid only for the version it was read from. Exit 2 otherwise.
require_model_version() {
  local pkg v
  for pkg in @tailwindcss/vite @tailwindcss/node @tailwindcss/oxide; do
    v=$(pkg_version "$pkg") || die "cannot read the installed version of $pkg"
    [ "$v" = "$MODEL_VERSION" ] || die "scanner-input model is for $pkg $MODEL_VERSION, installed $v: re-read @tailwindcss/vite dist/index.mjs (class B generate), update scripts/tailwind-scan-inputs.mjs, then bump MODEL_VERSION"
  done
}

# --- audit mode --------------------------------------------------------------

if [ "$MODE" = "audit" ]; then
  [ -z "$REF" ] || die "--audit takes no --ref"
  [ -f "$REPO/$CSS_ENTRY" ] || die "no $CSS_ENTRY in $REPO"

  require_model_version
  # The model assumes the Vite root is the repo root.
  if $GREP -q -E '(^|[^A-Za-z0-9_])root[[:space:]]*:' "$REPO/vite.config.ts"; then
    die "vite.config.ts appears to set root; the audit model assumes the Vite root is the repo root"
  fi

  AUDIT_TMP=$(mktemp -d "${TMPDIR:-/tmp}/tw-scan-audit.XXXXXX") || die "mktemp failed"
  trap 'rm -rf "$AUDIT_TMP"' EXIT
  trap 'exit 130' INT TERM

  # Side effect: none on the checkout. The helper only reads files.
  (cd "$REPO" && node "$SCRIPT_DIR/tailwind-scan-inputs.mjs" "$REPO" "$CSS_ENTRY") \
    > "$AUDIT_TMP/inputs.tsv" 2> "$AUDIT_TMP/inputs.err"
  rc=$?
  [ "$rc" -eq 0 ] || { cat "$AUDIT_TMP/inputs.err" >&2; die "scanner helper exited $rc"; }

  # Tracked paths raw (NUL-separated, no quoting), so non-ASCII names match
  # the scanner's raw paths. Captured to a file first: a pipeline would hide
  # git's exit status.
  git -C "$REPO" -c core.quotePath=false ls-files -z > "$AUDIT_TMP/tracked.z" \
    || die "git ls-files failed"
  tr '\0' '\n' < "$AUDIT_TMP/tracked.z" > "$AUDIT_TMP/tracked.txt" || die "tr failed"

  # Positive controls: gross-mismatch checks only (see the header).
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
  echo "audit: $count scanner inputs read from $REPO (model: Tailwind $MODEL_VERSION)"
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
# Physical path: the scanner reports canonical paths (/var -> /private/var on
# macOS), and the FILES rows compare against them.
TMP_RAW="$TMP"
TMP=$(cd "$TMP" && pwd -P) || { rm -rf "$TMP_RAW"; die "cannot resolve the temp dir"; }
case "$TMP" in
  "$REPO"|"$REPO"/*) rm -rf "$TMP"; die "temp dir is inside the repo: $TMP" ;;
esac
# Side effect: everything below is written under $TMP, removed on exit.
trap 'rm -rf "$TMP"' EXIT
trap 'exit 130' INT TERM

if [ -z "$REF" ]; then
  SOURCE_LABEL="working tree (tracked files, uncommitted edits included)"
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
  if [ -z "$REF" ]; then
    (cd "$REPO" && git ls-files -z | tar -cf - --null -T -) | tar -xf - -C "$dest" \
      || die "copying tracked working-tree files failed (a tracked file deleted but not staged?)"
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
  # An unmatched glob stays literal in bash, so test that it named a file.
  set -- "$dest"/dist/assets/*.css
  [ -f "$1" ] || die "build emitted no CSS file in $(basename "$dest")"
  [ $# -eq 1 ] || die "build emitted $# CSS files in $(basename "$dest") (expected exactly 1)"
  [ -s "$1" ] || die "emitted CSS is empty in $(basename "$dest")"
  printf '%s\n' "$1"
}

# no_symlink_on_path DEST REL: exit 2 if any component of DEST/REL (each
# directory on the way, and the file itself) is a symlink. A tracked symlink
# at e.g. design/ would otherwise carry a sentinel OUTSIDE the copy, where
# the trap does not clean it up.
no_symlink_on_path() {
  local dest="$1" rel="$2" cur="$1" part
  local IFS=/
  set -f
  for part in $rel; do
    [ -n "$part" ] || continue
    cur="$cur/$part"
    if [ -L "$cur" ]; then
      set +f
      die "plant path $rel crosses a symlink in the copy ($cur); refusing to write through it"
    fi
  done
  set +f
}

# plant PATH N: write a file at PATH whose only content uses sentinel N.
plant() {
  mkdir -p "$(dirname "$1")" || die "mkdir for $1 failed"
  printf '<div class="%s"></div>\n' "$(sentinel_class "$2")" > "$1" || die "planting $1 failed"
}

# in_css CSS N: true if sentinel N's rule is in the emitted CSS.
in_css() { $GREP -q -F -- "$(sentinel_selector "$2")" "$1"; }

# --- the rows ----------------------------------------------------------------
# Rows are "N|path relative to the copy|label". The root index.html is edited
# in place; the others are new files. The src/ PRESENT rows are added at run
# time, one per directory under src/ (see build_present_rows).

# Each markdown sentinel has its own basename: macOS file systems are
# usually case-insensitive, so x.md and x.MD would be ONE file.
ABSENT_ROWS="3511|scan-sentinel-lower.md|markdown .md (root)
3512|scan-sentinel-upper.MD|markdown .MD (root)
3513|scan-sentinel-mdx.mdx|markdown .mdx (root)
3514|scan-sentinel-markdown.markdown|markdown .markdown (root)
3515|src/notes/scan-sentinel-lower.md|markdown .md (src/)
3516|src/notes/scan-sentinel-upper.MD|markdown .MD (src/)
3517|src/notes/scan-sentinel-mdx.mdx|markdown .mdx (src/)
3518|src/notes/scan-sentinel-markdown.markdown|markdown .markdown (src/)
3521|CLAUDE.md|private CLAUDE.md
3522|.claude/scan-sentinel.html|private .claude/
3523|design/scan-sentinel.html|private design/
3524|team/scan-sentinel.html|private team/
3525|research/scan-sentinel.html|private research/
3526|resources/scan-sentinel.html|private resources/
3527|to-be-filed/scan-sentinel.html|private to-be-filed/"

# scripts/ and public/ rows exist only when the tree has those directories.
SCRIPTS_ROW="3531|scripts/scan-sentinel.html|tooling scripts/"
PUBLIC_ROW="3504|public/scan-sentinel.html|public/"

GAP_DIR_N=3541
GAP_FILE_N=3542

# build_present_rows DEST: print the PRESENT rows for the tree in DEST:
# root index.html, one row per directory under src/ (numbered from 3601),
# and public/ if it exists. Run on the clean copy, before anything is
# planted, so planted directories (src/notes) are not enumerated.
build_present_rows() {
  local dest="$1" n=3601 d
  printf '%s\n' "3501|index.html|root index.html"
  (cd "$dest" && find src -type d | LC_ALL=C sort) > "$TMP/src-dirs.txt" \
    || die "listing src/ directories failed"
  [ -s "$TMP/src-dirs.txt" ] || die "no src/ directory in the copy"
  # Rows are |- and newline-delimited: such a name would mangle its row.
  if [ -n "$(cd "$dest" && find src -name '*|*' -print -o -name "*$NL*" -print)" ]; then
    die "a path under src/ contains '|' or a newline; the row format cannot carry it"
  fi
  while IFS= read -r d; do
    [ -n "$d" ] || continue
    printf '%s\n' "$n|$d/scan-sentinel-dir.tsx|$d/"
    n=$((n + 1))
  done < "$TMP/src-dirs.txt"
  if [ -d "$dest/public" ]; then printf '%s\n' "$PUBLIC_ROW"; fi
}

# plant_rows DEST ROWS: plant each row's sentinel, then read every plant back.
plant_rows() {
  local dest="$1" rows="$2" n p label
  while IFS='|' read -r n p label; do
    [ -n "$n" ] || continue
    if [ "$p" = "index.html" ]; then
      no_symlink_on_path "$dest" "$p"
      # Insert the sentinel before </body>, then prove the insert happened.
      awk -v cls="$(sentinel_class "$n")" \
        '/<\/body>/ && !done { print "    <div class=\"" cls "\"></div>"; done=1 } { print }' \
        "$dest/index.html" > "$dest/index.html.new" || die "editing index.html failed"
      mv "$dest/index.html.new" "$dest/index.html" || die "editing index.html failed"
    else
      no_symlink_on_path "$dest" "$p"
      plant "$dest/$p" "$n"
    fi
  done <<EOF
$rows
EOF
  # Read every plant back. Two paths can name one file (case-insensitive
  # file systems), and a row whose sentinel was overwritten passes ABSENT
  # without testing anything.
  while IFS='|' read -r n p label; do
    [ -n "$n" ] || continue
    $GREP -q -F -- "$(sentinel_class "$n")" "$dest/$p" \
      || die "planted sentinel for '$label' was not found in $p after planting"
  done <<EOF
$rows
EOF
}

# strip_private_rules DEST: remove the private-name rules from DEST/.gitignore.
# Fails closed unless exactly PRIVATE_RULE_COUNT lines were removed: a rule
# respelled (e.g. /team/) would otherwise stay in force and blind the run.
strip_private_rules() {
  local dest="$1" rules="$TMP/private-rules.txt" r before after removed
  : > "$rules"
  for r in $PRIVATE_RULES; do printf '%s\n' "$r" >> "$rules"; done
  before=$(wc -l < "$dest/.gitignore" | tr -d ' ')
  $GREP -v -x -F -f "$rules" "$dest/.gitignore" > "$dest/.gitignore.new"
  # grep -v exits 1 when every line was removed; only >1 is an error.
  [ $? -le 1 ] || die "filtering .gitignore failed"
  mv "$dest/.gitignore.new" "$dest/.gitignore" || die "rewriting .gitignore failed"
  after=$(wc -l < "$dest/.gitignore" | tr -d ' ')
  removed=$((before - after))
  [ "$removed" -eq "$PRIVATE_RULE_COUNT" ] \
    || die "second-layer strip removed $removed of $PRIVATE_RULE_COUNT private .gitignore rules (a rule was respelled, moved or deleted); the layer test would be blind. If the change is intended, update (PRIVATE_RULES, PRIVATE_RULE_COUNT and EXPECTED_GAPS in this script move together)"
}

# strip_source_not DEST: delete every `@source not` line from the copy's
# stylesheet (control build only).
strip_source_not() {
  local css="$1/$CSS_ENTRY"
  $GREP -v -E '^[[:space:]]*@source[[:space:]]+not[[:space:]]' "$css" > "$css.new"
  [ $? -le 1 ] || die "filtering $CSS_ENTRY failed"
  mv "$css.new" "$css" || die "rewriting $CSS_ENTRY failed"
  # No textual survival check here: comments mention `@source not` too. An
  # exclusion that survives (e.g. two directives on one line) keeps a plant
  # hidden, and the control's leak assertion stops the run on that.
}

# check_rows CSS LABEL PRESENT-ROWS ABSENT-ROWS
check_rows() {
  local css="$1" run="$2" n p label
  while IFS='|' read -r n p label; do
    [ -n "$n" ] || continue
    if in_css "$css" "$n"; then pass "[$run] PRESENT $label"
    else fail "[$run] PRESENT $label: sentinel missing from the CSS (scan does not cover it)"; fi
  done <<EOF
$3
EOF
  while IFS='|' read -r n p label; do
    [ -n "$n" ] || continue
    if in_css "$css" "$n"; then fail "[$run] ABSENT $label: sentinel leaked into the CSS"
    else pass "[$run] ABSENT $label"; fi
  done <<EOF
$4
EOF
}

# check_src_inputs DEST: FILES rows. Every file under DEST/src/ whose type is
# in SRC_SCANNED_EXT must be one of the scanner's inputs, as reported by
# tailwind-scan-inputs.mjs run against the copy. This catches exclusions
# that keep every directory but drop files by name or extension (e.g.
# `@source not "../src/**/*.ts"`), which no directory sentinel can see.
check_src_inputs() {
  local dest="$1" f ext missing=0 total=0 rc
  require_model_version
  (cd "$dest" && node "$SCRIPT_DIR/tailwind-scan-inputs.mjs" "$dest" "$CSS_ENTRY") \
    > "$TMP/copy-inputs.tsv" 2> "$TMP/copy-inputs.err"
  rc=$?
  [ "$rc" -eq 0 ] || { cat "$TMP/copy-inputs.err" >&2; die "scanner helper exited $rc on the copy"; }
  cut -f1 "$TMP/copy-inputs.tsv" > "$TMP/copy-inputs.txt" || die "reading scanner inputs failed"
  (cd "$dest" && find src -type f | LC_ALL=C sort) > "$TMP/src-files.txt" || die "listing src/ files failed"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    ext="${f##*.}"
    case " $SRC_SCANNED_EXT " in *" $ext "*) ;; *) continue ;; esac
    total=$((total + 1))
    if ! $GREP -q -F -x -- "$dest/$f" "$TMP/copy-inputs.txt"; then
      fail "FILES $f is not a scanner input (an exclusion drops it from the CSS)"
      missing=$((missing + 1))
    fi
  done < "$TMP/src-files.txt"
  [ "$total" -gt 0 ] || die "FILES: no source files of a scanned type under src/"
  [ "$missing" -eq 0 ] && pass "FILES all $total tracked src/ source files ($SRC_SCANNED_EXT) are scanner inputs"
  return 0
}

# --- 1. clean build: no plants; every sentinel must be absent (UNIQUE) --------
populate "$TMP/clean"
PRESENT=$(build_present_rows "$TMP/clean") || bail $?
ABSENT="$ABSENT_ROWS"
if [ -d "$TMP/clean/scripts" ]; then
  ABSENT="$ABSENT
$SCRIPTS_ROW"
else
  note "scripts/ does not exist in this tree; its ABSENT row is skipped"
fi
[ -d "$TMP/clean/public" ] || note "public/ does not exist in this tree; its PRESENT row is skipped"
SRC_DIRS=$(wc -l < "$TMP/src-dirs.txt" | tr -d ' ')
note "PRESENT rows: root index.html + $SRC_DIRS src/ directories"

CLEAN_CSS=$(build "$TMP/clean") || bail $?
ALL_ROWS="$PRESENT
$ABSENT"
unique_ok=1
while IFS='|' read -r n p label; do
  [ -n "$n" ] || continue
  if in_css "$CLEAN_CSS" "$n"; then
    fail "UNIQUE sentinel $(sentinel_class "$n") ($label) is already in a clean build; pick another"
    unique_ok=0
  fi
done <<EOF
$ALL_ROWS
EOF
for n in $GAP_DIR_N $GAP_FILE_N; do
  if in_css "$CLEAN_CSS" "$n"; then
    fail "UNIQUE gap sentinel $(sentinel_class "$n") is already in a clean build"
    unique_ok=0
  fi
done
[ "$unique_ok" -eq 1 ] && pass "UNIQUE no sentinel appears in a clean build"

# FILES rows, on the clean copy (committed config, nothing planted).
check_src_inputs "$TMP/clean"

# --- 2. planted build, .gitignore as committed (both layers) ----------------
populate "$TMP/both"
plant_rows "$TMP/both" "$ALL_ROWS"
BOTH_CSS=$(build "$TMP/both") || bail $?
check_rows "$BOTH_CSS" "both layers" "$PRESENT" "$ABSENT"

# --- 3. anti-vacuity: the src/ sentinel moved the output --------------------
if cmp -s "$CLEAN_CSS" "$BOTH_CSS"; then
  fail "MOVES planted build CSS is identical to the clean build: the scan is off"
elif in_css "$BOTH_CSS" 3601; then
  pass "MOVES a src/ mutant changes the emitted CSS"
else
  fail "MOVES the CSS changed, but not by the src/ sentinel"
fi

# --- 4. GAP rows: symlinks at private names, pinned -------------------------
mkdir -p "$TMP/outside/dir" || die "mkdir outside failed"
plant "$TMP/outside/dir/scan-sentinel.html" "$GAP_DIR_N"
plant "$TMP/outside/file.html" "$GAP_FILE_N"
: > "$TMP/gaps-seen.txt"

# gap_row CSS NAME N: report one gap row against the pin.
gap_row() {
  local css="$1" name="$2" n="$3" expected=0
  # Here-string, not a pipe: under pipefail an early-exiting grep -q can make
  # the producer's SIGPIPE turn a match into a miss.
  if $GREP -q -F -x -- "$name" <<<"$EXPECTED_GAPS"; then expected=1; fi
  if in_css "$css" "$n"; then
    if [ "$expected" -eq 1 ]; then gap "$name LEAKS into the CSS (known, pinned)"
    else fail "GAP pin: $name LEAKS but is not an expected gap (new leak: the boundary moved; if intended, update (PRIVATE_RULES, PRIVATE_RULE_COUNT and EXPECTED_GAPS in this script move together))"; fi
  else
    if [ "$expected" -eq 1 ]; then fail "GAP pin: $name no longer leaks but is pinned as a gap (re-read the scanner, then update (PRIVATE_RULES, PRIVATE_RULE_COUNT and EXPECTED_GAPS in this script move together))"
    else note "$name: no leak (as pinned)"; fi
  fi
}

# gap_run NAME RUN-LABEL STRIP: one copy with research -> outside dir and
# team -> outside file; STRIP=1 removes the private .gitignore rules first.
gap_run() {
  local dest="$TMP/$1" run="$2" css
  populate "$dest"
  [ "$3" -eq 1 ] && strip_private_rules "$dest"
  ln -s "$TMP/outside/dir" "$dest/research" || die "symlink failed"
  ln -s "$TMP/outside/file.html" "$dest/team" || die "symlink failed"
  css=$(build "$dest") || bail $?
  gap_row "$css" "[$run] research -> outside directory" "$GAP_DIR_N"
  gap_row "$css" "[$run] team -> outside file" "$GAP_FILE_N"
}
# This run needs no strip, so it runs before the strip-dependent ones: a
# moved boundary shows here even when a later strip check stops the run.
gap_run gap-both "both layers" 0

# --- 5. CONTROL: both layers removed; every exclusion plant must LEAK -------
populate "$TMP/control"
strip_private_rules "$TMP/control"
strip_source_not "$TMP/control"
plant_rows "$TMP/control" "$ALL_ROWS"
CONTROL_CSS=$(build "$TMP/control") || bail $?
blind=0
while IFS='|' read -r n p label; do
  [ -n "$n" ] || continue
  if ! in_css "$CONTROL_CSS" "$n"; then
    printf 'FAIL  control: %s stays hidden with both layers removed (another rule covers it, or the scan does not reach it)\n' "$label" >&2
    blind=1
  fi
done <<EOF
$ABSENT
EOF
[ "$blind" -eq 0 ] || die "control build: the layer test is blind for the row(s) above. If a new ignore rule is intended, add it to (PRIVATE_RULES, PRIVATE_RULE_COUNT and EXPECTED_GAPS in this script move together)"
pass "CONTROL every exclusion plant leaks with both layers removed (the layer test can see)"

# --- 6. planted build with the private .gitignore rules removed -------------
populate "$TMP/layer2"
strip_private_rules "$TMP/layer2"
plant_rows "$TMP/layer2" "$ALL_ROWS"
L2_CSS=$(build "$TMP/layer2") || bail $?
check_rows "$L2_CSS" "@source not only" "$PRESENT" "$ABSENT"

gap_run gap-layer2 "@source not only" 1

echo
if [ "$FAILS" -gt 0 ]; then
  summary_failed
  exit 1
fi
echo "check-tailwind-scan: all rows passed. $GAPS pinned gap(s) reported, not counted as passes."
exit 0
