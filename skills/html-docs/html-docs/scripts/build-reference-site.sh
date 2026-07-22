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

# Page-nav data for the reading-nav live demo on the tier2 showcase page. Only the
# tier2 template loads it (assets/nav-manifest.js), so page-to-page nav is shown on
# that one page — like every other Tier 2 bundle, which is live only on tier2. The
# landing (index) is home and is not listed.
cat > "$out/assets/nav-manifest.js" <<'EOF'
/* reference-site page navigation manifest — demonstrates the reading-nav component's
   page-to-page nav on the tier2 showcase page. */
window.__HTMLDOCS_NAV = {
  "pages": [
    { "slug": "foundation",  "href": "foundation.html",  "kicker": "Foundation",  "title": "Foundation" },
    { "slug": "color",       "href": "color.html",       "kicker": "Color",       "title": "Color model" },
    { "slug": "components",   "href": "components.html",  "kicker": "Components",  "title": "Components" },
    { "slug": "enhancement",  "href": "enhancement.html", "kicker": "Enhancement", "title": "Enhancement kit" },
    { "slug": "tier2",        "href": "tier2.html",       "kicker": "Tier 2",      "title": "Tier 2 components" },
    { "slug": "contract",     "href": "contract.html",    "kicker": "Contract",    "title": "The contract" }
  ]
};
EOF

echo "Reference site built under $out (7 pages)"
