#!/usr/bin/env bash
# build.sh — render one semantic Markdown file into an explainer-html-docs page.
#
# Usage:
#   build.sh <src.md> <out-dir> --assets <base-assets-dir> [--context <dir>]
#            [--template <file>] [--filter <file>]... [--inline]
#
#   <src.md>             the semantic Markdown (Markdown + fenced divs) to render
#   <out-dir>            site output root; the page lands at <out-dir>/<name>.html
#   --assets <dir>       dir holding base.css / base.js (explainer-html-docs/assets)
#   --layout <name>      DEFAULT column measure, emitted as a layout-<name> class
#                        on <body>: narrow (48rem) | standard (56rem, the default)
#                        | wide (64rem). A page's own `layout:` frontmatter wins
#                        over this, so a consumer sets the site-wide default here
#                        and a page that needs a different measure says so itself.
#   --context <dir>      optional dir of consumer context stylesheets/scripts (*.css/*.js)
#   --component <name>   optional Tier 2 opt-in bundle to copy in; repeatable. Copies
#                        the flat css/js from <assets>/components/<name>/ into
#                        <out>/assets/, so a copy-mode site can consume an explainer-html-docs
#                        component the same way it references a context asset. The page
#                        still selects it via context-css/context-js frontmatter.
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

src=""; out=""; assets=""; context=""; template=""; inline=""; layout=""
filters=(); components=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --assets)    assets="$2"; shift 2 ;;
    --layout)    layout="$2"; shift 2 ;;
    --context)   context="$2"; shift 2 ;;
    --component) components+=("$2"); shift 2 ;;
    --template)  template="$2"; shift 2 ;;
    --filter)    filters+=("$2"); shift 2 ;;
    --inline)    inline=1; shift ;;
    *) if [[ -z "$src" ]]; then src="$1"; elif [[ -z "$out" ]]; then out="$1"; fi; shift ;;
  esac
done

template="${template:-$SKILL_DIR/assets/template.html}"

[[ -f "$src" ]]      || { echo "build.sh: source file not found: $src" >&2; exit 2; }
[[ -n "$out" ]]      || { echo "build.sh: missing <out-dir>" >&2; exit 2; }
[[ -d "$assets" ]]   || { echo "build.sh: --assets dir not found: $assets" >&2; exit 2; }

# Closed vocabulary, same contract as the fenced-div variants: an unknown layout
# fails the build rather than silently emitting a class base.css has no rule for
# (which would render as `standard` and hide the typo).
if [[ -n "$layout" ]]; then
  case "$layout" in
    narrow|standard|wide) ;;
    *) echo "build.sh: unknown --layout: $layout (narrow|standard|wide)" >&2; exit 2 ;;
  esac
fi

page="$(basename "${src%.md}").html"
mkdir -p "$out/assets"
cp "$assets/base.css" "$assets/base.js" "$out/assets/"
# context stylesheets (context-css) AND scripts (context-js) are copied verbatim,
# so a page that references assets/<name>.css / assets/<name>.js resolves.
if [[ -n "$context" && -d "$context" ]]; then
  cp "$context/"*.css "$out/assets/" 2>/dev/null || true
  cp "$context/"*.js  "$out/assets/" 2>/dev/null || true
fi

# Tier 2 opt-in bundles (--component <name>): copy the flat css/js from
# <assets>/components/<name>/ into <out>/assets/. build.sh --context copies only a
# consumer's own flat dir, so a copy-mode site consumes an explainer-html-docs-owned component
# through this flag instead; the page still opts in via its context-css/js frontmatter.
for c in "${components[@]:-}"; do
  [[ -z "$c" ]] && continue
  cdir="$assets/components/$c"
  [[ -d "$cdir" ]] || { echo "build.sh: --component not found: $cdir" >&2; exit 2; }
  cp "$cdir/"*.css "$out/assets/" 2>/dev/null || true
  cp "$cdir/"*.js  "$out/assets/" 2>/dev/null || true
done

# Chain the base filter first, then any consumer filters (so consumer vocabulary
# is bound on top of the base binding, and base rules like .tablewrap still run).
pandoc_args=(--lua-filter "$SKILL_DIR/filters/htmldocs.lua")
for f in "${filters[@]:-}"; do
  [[ -n "$f" ]] && pandoc_args+=(--lua-filter "$f")
done

# Passed as `layout-default`, NOT `layout`: -M outranks frontmatter, and this
# flag is the site-wide default a page's own `layout:` must be able to override.
# The template picks layout -> layout-default -> standard, in that order.
# Appended to the same array so the expansion is never empty (a bare
# "${arr[@]:-}" on an empty array would hand pandoc a stray empty argument).
if [[ -n "$layout" ]]; then pandoc_args+=(-M "layout-default=$layout"); fi

# -f markdown-raw_html closes the escape hatch: the AUTHOR cannot inject raw HTML
# (invented classes / inline style), but the trusted filter still emits it.
"$SKILL_DIR/scripts/preflight.sh" pandoc "$src" \
  --template "$template" \
  "${pandoc_args[@]}" \
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
