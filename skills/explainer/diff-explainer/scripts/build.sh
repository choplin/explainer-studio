#!/usr/bin/env bash
# build.sh — render a diff-explainer source file into a single self-contained
# explainer-html-docs page (inline mode, the default).
#
# It assembles the context assets diff-explainer always uses (its own
# diff-explainer.css plus the diff / diagram / comments components) and delegates
# the actual generation to explainer-html-docs's build.sh with the
# diff-explainer template variant and consumer filter.
#
# Usage:
#   build.sh <src.md> <out-dir> [--copy]
#     <src.md>   the diff-explainer semantic Markdown
#     <out-dir>  output root; the page lands at <out-dir>/<name>.html
#     --copy     emit copy-mode (external assets/ dir) instead of one inline file
#
# Runtime is pandoc, resolved by the generator's preflight (PATH -> nix -> fail).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ED="$(cd "$HERE/.." && pwd)"
EXPLAINER_ROOT="$(cd "$ED/.." && pwd)"
GEN="$EXPLAINER_ROOT/explainer-html-docs"
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

# Stage the context dir: diff-explainer's stylesheet + the opt-in components it
# always uses. The generator copies every *.css / *.js from here into the page's
# assets/, and (in inline mode) folds them into the single file.
ctx="$(mktemp -d)"
trap 'rm -rf "$ctx"' EXIT
cp "$ED/assets/diff-explainer.css" "$ctx/"
cp "$COMP/diff/diff.css"       "$COMP/diff/diff.js" \
   "$COMP/diagram/diagram.css" "$COMP/diagram/diagram.js" \
   "$COMP/comments/comments.css" "$COMP/comments/comments.js" "$ctx/"

bash "$GEN/scripts/build.sh" "$src" "$out" \
  --assets "$BASE" --context "$ctx" \
  --template "$ED/assets/template-diff-explainer.html" \
  --filter "$ED/filters/diff-explainer.lua" \
  $inline
