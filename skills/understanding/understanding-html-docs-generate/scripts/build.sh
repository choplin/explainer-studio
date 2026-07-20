#!/usr/bin/env bash
# build.sh — render one semantic IR file into an understanding-html-docs page.
#
# Usage:
#   build.sh <ir.md> <out-dir> --assets <base-assets-dir> [--context <dir>]
#            [--template <file>] [--filter <file>]... [--inline]
#
#   <ir.md>              the semantic IR (Markdown + fenced divs) to render
#   <out-dir>            site output root; the page lands at <out-dir>/<name>.html
#   --assets <dir>       dir holding base.css / base.js (understanding-html-docs/assets)
#   --context <dir>      optional dir of consumer context stylesheets/scripts (*.css/*.js)
#   --template <file>    optional consumer template variant (default: assets/template.html)
#   --filter <file>      optional extra Lua filter, chained AFTER htmldocs.lua;
#                        repeatable (a consumer registers its own vocabulary this way)
#   --inline             opt-in: fold local assets into ONE self-contained file
#                        (default is copy-mode: base.css/js + context copied to assets/)
#
# base.css / base.js and any context *.css / *.js are copied verbatim into
# <out-dir>/assets/. The page is a no-build static file; only THIS step needs pandoc.
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

src=""; out=""; assets=""; context=""; template=""; inline=""
filters=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --assets)   assets="$2"; shift 2 ;;
    --context)  context="$2"; shift 2 ;;
    --template) template="$2"; shift 2 ;;
    --filter)   filters+=("$2"); shift 2 ;;
    --inline)   inline=1; shift ;;
    *) if [[ -z "$src" ]]; then src="$1"; elif [[ -z "$out" ]]; then out="$1"; fi; shift ;;
  esac
done

template="${template:-$SKILL_DIR/assets/template.html}"

[[ -f "$src" ]]      || { echo "build.sh: IR file not found: $src" >&2; exit 2; }
[[ -n "$out" ]]      || { echo "build.sh: missing <out-dir>" >&2; exit 2; }
[[ -d "$assets" ]]   || { echo "build.sh: --assets dir not found: $assets" >&2; exit 2; }

page="$(basename "${src%.md}").html"
mkdir -p "$out/assets"
cp "$assets/base.css" "$assets/base.js" "$out/assets/"
# context stylesheets (context-css) AND scripts (context-js) are copied verbatim,
# so a page that references assets/<name>.css / assets/<name>.js resolves.
if [[ -n "$context" && -d "$context" ]]; then
  cp "$context/"*.css "$out/assets/" 2>/dev/null || true
  cp "$context/"*.js  "$out/assets/" 2>/dev/null || true
fi

# Chain the base filter first, then any consumer filters (so consumer vocabulary
# is bound on top of the base binding, and base rules like .tablewrap still run).
filter_args=(--lua-filter "$SKILL_DIR/filters/htmldocs.lua")
for f in "${filters[@]:-}"; do
  [[ -n "$f" ]] && filter_args+=(--lua-filter "$f")
done

# -f markdown-raw_html closes the escape hatch: the AUTHOR cannot inject raw HTML
# (invented classes / inline style), but the trusted filter still emits it.
"$SKILL_DIR/scripts/preflight.sh" pandoc "$src" \
  --template "$template" \
  "${filter_args[@]}" \
  -f markdown-raw_html \
  -o "$out/$page"

# Inline mode (opt-in): fold the just-copied local assets into the single page,
# then drop the sidecar assets/ dir so the output is one self-contained file.
# Copy-mode (default) skips all of this and leaves external asset refs in place.
if [[ -n "$inline" ]]; then
  awk -v assetdir="$out/assets" -f "$SKILL_DIR/scripts/inline.awk" "$out/$page" > "$out/$page.inl"
  mv "$out/$page.inl" "$out/$page"
  rm -rf "$out/assets"
fi

echo "wrote $out/$page"
