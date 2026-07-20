#!/usr/bin/env bash
# build.sh — render one semantic IR file into an understanding-html-docs page.
#
# Usage:
#   build.sh <ir.md> <out-dir> --assets <base-assets-dir> [--context <context-css-dir>]
#
#   <ir.md>              the semantic IR (Markdown + fenced divs) to render
#   <out-dir>            site output root; the page lands at <out-dir>/<name>.html
#   --assets <dir>       dir holding base.css / base.js (understanding-html-docs/assets)
#   --context <dir>      optional dir of consumer context stylesheets (*.css)
#
# base.css / base.js and any context *.css are copied verbatim into <out-dir>/assets/.
# The page is a no-build static file; only THIS step needs pandoc.
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

src=""; out=""; assets=""; context=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --assets)  assets="$2"; shift 2 ;;
    --context) context="$2"; shift 2 ;;
    *) if [[ -z "$src" ]]; then src="$1"; elif [[ -z "$out" ]]; then out="$1"; fi; shift ;;
  esac
done

[[ -f "$src" ]]      || { echo "build.sh: IR file not found: $src" >&2; exit 2; }
[[ -n "$out" ]]      || { echo "build.sh: missing <out-dir>" >&2; exit 2; }
[[ -d "$assets" ]]   || { echo "build.sh: --assets dir not found: $assets" >&2; exit 2; }

page="$(basename "${src%.md}").html"
mkdir -p "$out/assets"
cp "$assets/base.css" "$assets/base.js" "$out/assets/"
[[ -n "$context" && -d "$context" ]] && cp "$context/"*.css "$out/assets/" 2>/dev/null || true

# -f markdown-raw_html closes the escape hatch: the AUTHOR cannot inject raw HTML
# (invented classes / inline style), but the trusted filter still emits it.
"$SKILL_DIR/scripts/preflight.sh" pandoc "$src" \
  --template "$SKILL_DIR/assets/template.html" \
  --lua-filter "$SKILL_DIR/filters/htmldocs.lua" \
  -f markdown-raw_html \
  -o "$out/$page"

echo "wrote $out/$page"
