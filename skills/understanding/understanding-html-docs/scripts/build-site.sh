#!/usr/bin/env bash
# build-site.sh — render every ir/*.md into a multi-page site sharing one asset
# set. Inter-page nav is authored as links in the IR; no manifest is generated.
#
# Usage:
#   build-site.sh <ir-dir> <out-dir> --assets <base-assets-dir> [--context <dir>]
set -euo pipefail
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

irdir=""; out=""; passthru=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --assets|--context) passthru+=("$1" "$2"); shift 2 ;;
    *) if [[ -z "$irdir" ]]; then irdir="$1"; elif [[ -z "$out" ]]; then out="$1"; fi; shift ;;
  esac
done

[[ -d "$irdir" ]] || { echo "build-site.sh: ir-dir not found: $irdir" >&2; exit 2; }
[[ -n "$out" ]]   || { echo "build-site.sh: missing <out-dir>" >&2; exit 2; }

shopt -s nullglob
for md in "$irdir"/*.md; do
  "$SKILL_DIR/scripts/build.sh" "$md" "$out" "${passthru[@]}"
done

echo
echo "Site built under $out:"
ls -1 "$out"/*.html | sed "s#$out/#  #"
