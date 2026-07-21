#!/usr/bin/env bash
# build.sh — render an explain-diff source file into a single self-contained
# understanding-html-docs page (inline mode, the default).
#
# It assembles the context assets explain-diff always uses (its own
# explain-diff.css plus the diff / diagram / comments components) and delegates
# the actual generation to understanding-html-docs's build.sh with the
# explain-diff template variant and consumer filter.
#
# Usage:
#   build.sh <src.md> <out-dir> [--copy]
#     <src.md>   the explain-diff semantic Markdown
#     <out-dir>  output root; the page lands at <out-dir>/<name>.html
#     --copy     emit copy-mode (external assets/ dir) instead of one inline file
#
# Runtime is pandoc, resolved by the generator's preflight (PATH -> nix -> fail).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ED="$(cd "$HERE/.." && pwd)"
UNDERSTANDING="$(cd "$ED/.." && pwd)"
GEN="$UNDERSTANDING/understanding-html-docs"
BASE="$GEN/assets"
COMP="$BASE/components"

src=""; out=""; inline="--inline"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --copy) inline=""; shift ;;
    *) if [[ -z "$src" ]]; then src="$1"; elif [[ -z "$out" ]]; then out="$1"; fi; shift ;;
  esac
done
[[ -f "$src" ]] || { echo "build.sh: source file not found: $src" >&2; exit 2; }
[[ -n "$out" ]] || { echo "build.sh: missing <out-dir>" >&2; exit 2; }

# Stage the context dir: explain-diff's stylesheet + the opt-in components it
# always uses. The generator copies every *.css / *.js from here into the page's
# assets/, and (in inline mode) folds them into the single file.
ctx="$(mktemp -d)"
trap 'rm -rf "$ctx"' EXIT
cp "$ED/assets/explain-diff.css" "$ctx/"
cp "$COMP/diff/diff.css"       "$COMP/diff/diff.js" \
   "$COMP/diagram/diagram.css" "$COMP/diagram/diagram.js" \
   "$COMP/comments/comments.css" "$COMP/comments/comments.js" "$ctx/"

bash "$GEN/scripts/build.sh" "$src" "$out" \
  --assets "$BASE" --context "$ctx" \
  --template "$ED/assets/template-explain-diff.html" \
  --filter "$ED/filters/explain-diff.lua" \
  $inline
