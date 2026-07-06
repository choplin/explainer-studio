#!/usr/bin/env bash
# mineru_ocr.sh — OCR a paper PDF locally with MinerU and materialize:
#   <ocr-dir>/paper.md               full text as Markdown (LaTeX math), one
#                                    [pNN] anchor line per PDF page
#   <ocr-dir>/figures/fig-NN.ext     extracted figures, named by paper number
#   <ocr-dir>/figures/table-NN.ext   extracted tables, named by paper number
#
# Usage: mineru_ocr.sh <pdf-path> <ocr-dir>
#
# Fully local — nothing leaves the machine, so no upload consent is needed
# (safe for under-review / confidential manuscripts).
#
# Requires the `mineru` CLI (NOT installed by this script):
#   uv tool install "mineru[core]"
# The first run downloads model weights (several GB) automatically and is slow.

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: $0 <pdf-path> <ocr-dir>" >&2
  exit 2
fi

PDF=$1
OUT=$2

[[ -f "$PDF" ]] || { echo "error: PDF not found: $PDF" >&2; exit 1; }

if ! command -v mineru >/dev/null; then
  cat >&2 <<'EOF'
error: `mineru` is not installed — this skill requires it and does not fall back.

Set it up once with uv:

    uv tool install "mineru[core]"

Then re-run. The first run downloads model weights (several GB).
EOF
  exit 1
fi
command -v python3 >/dev/null || { echo "error: python3 not found" >&2; exit 1; }

# Explicit template: macOS mktemp ignores $TMPDIR without one, which breaks
# under sandboxes that only whitelist $TMPDIR for writes.
TMP=$(mktemp -d "${TMPDIR:-/tmp}/paper-studio-mineru.XXXXXX")
trap 'rm -rf "$TMP"' EXIT

echo "running MinerU (first run downloads models and can take a while)..." >&2
mineru -p "$PDF" -o "$TMP/out"

CONTENT_LIST=$(find "$TMP/out" -name '*_content_list.json' -print | head -1)
if [[ -z "$CONTENT_LIST" ]]; then
  echo "error: unexpected MinerU output layout (no *_content_list.json under $TMP/out)" >&2
  echo "       MinerU may have changed its output format — inspect that directory." >&2
  exit 1
fi

python3 "$(cd "$(dirname "$0")" && pwd)/mineru_to_paper_md.py" \
  "$(dirname "$CONTENT_LIST")" "$OUT"
