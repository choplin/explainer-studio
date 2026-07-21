#!/usr/bin/env bash
# build-reference-site.sh — regenerate this skill's own reference site from
# src/*.md into site/ (the committed artifact). The six base pages build with the
# default template/filter; tier2 is the one page that needs the Tier 2 component
# wiring, so it builds with the tier2 template + filter and the components/ tree is
# copied in for its <head> references.
#
# Usage: scripts/build-reference-site.sh [out-dir]
# Defaults to <skill>/site — the self-contained, committed pages plus site/assets/.
# Pass an out-dir only to render a throwaway preview elsewhere.
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
out="${1:-$SKILL_DIR/site}"
rm -rf "$out"
mkdir -p "$out"

for md in "$SKILL_DIR"/src/*.md; do
  name="$(basename "$md" .md)"
  if [[ "$name" == "tier2" ]]; then
    bash "$SKILL_DIR/scripts/build.sh" "$md" "$out" \
      --assets "$SKILL_DIR/assets" --context "$SKILL_DIR/assets" \
      --template "$SKILL_DIR/assets/template-tier2.html" \
      --filter "$SKILL_DIR/filters/tier2.lua"
  else
    bash "$SKILL_DIR/scripts/build.sh" "$md" "$out" \
      --assets "$SKILL_DIR/assets" --context "$SKILL_DIR/assets"
  fi
done

# The Tier 2 bundles live under assets/components/<name>/; build.sh --context
# copies only flat css/js, so bring the components tree over for tier2's head.
cp -R "$SKILL_DIR/assets/components" "$out/assets/"

echo "Reference site built under $out (7 pages)"
