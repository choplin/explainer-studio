#!/usr/bin/env bash
# mineru_ocr.sh — read a paper PDF locally with MinerU and materialize:
#   <ocr-dir>/paper.md               full text as Markdown (LaTeX math), one
#                                    [pNN] anchor line per PDF page
#   <ocr-dir>/figures/fig-NN.ext     extracted figures, named by paper number
#   <ocr-dir>/figures/table-NN.ext   extracted tables, named by paper number
#
# Usage: mineru_ocr.sh <pdf-path> <ocr-dir>
#
# For born-digital PDFs (the norm for CS papers) the body text is taken from the
# PDF's own text layer, using MinerU only for the layout skeleton — block order,
# figure/table crops, and formula LaTeX. This is materially more faithful than
# image OCR on the ACM/LinLibertine font class (no dropped descenders, no
# collapsed ff/fi ligatures, no spurious <sub>/<sup> tags). MinerU runs with the
# `pipeline` backend in text mode (`-b pipeline -m txt`); a scanned PDF with no
# text layer falls back to OCR mode (`-m ocr`) and the converter then uses
# MinerU's own recognized text.
#
# Fully local — nothing leaves the machine (MinerU pipeline backend + poppler's
# pdftotext are both local), so no upload consent is needed (safe for
# under-review / confidential manuscripts).
#
# Requires the `mineru` CLI (NOT installed by this script):
#   uv tool install "mineru[core]"
# The first run downloads model weights (several GB) automatically and is slow.
# Also requires poppler's `pdftotext` (same package as `pdfinfo`).

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
command -v pdftotext >/dev/null || { echo "error: pdftotext not found (install poppler)" >&2; exit 1; }

# Choose the reading method from whether the PDF has a usable text layer. A
# born-digital PDF (essentially every CS paper) is read in text mode so the body
# text comes from the authoritative text layer; a scanned PDF with no text layer
# falls back to image OCR. `-b pipeline` is required because the default backend
# (hybrid/VLM) image-recognizes every page and would garble the text.
TEXT_CHARS=$(pdftotext -f 1 -l 5 "$PDF" - 2>/dev/null | tr -cd '[:alnum:]' | wc -c | tr -d ' ')
if [[ "${TEXT_CHARS:-0}" -ge 200 ]]; then
  METHOD=txt
else
  METHOD=ocr
  echo "no usable text layer (${TEXT_CHARS:-0} chars) — falling back to image OCR" >&2
fi

# Explicit template: macOS mktemp ignores $TMPDIR without one, which breaks
# under sandboxes that only whitelist $TMPDIR for writes.
TMP=$(mktemp -d "${TMPDIR:-/tmp}/paper-studio-mineru.XXXXXX")
trap 'rm -rf "$TMP"' EXIT

echo "running MinerU (-b pipeline -m $METHOD; first run downloads models and can take a while)..." >&2
mineru -p "$PDF" -o "$TMP/out" -b pipeline -m "$METHOD"

MIDDLE=$(find "$TMP/out" -name '*_middle.json' -print | head -1)
if [[ -z "$MIDDLE" ]]; then
  echo "error: unexpected MinerU output layout (no *_middle.json under $TMP/out)" >&2
  echo "       MinerU may have changed its output format — inspect that directory." >&2
  exit 1
fi

python3 "$(cd "$(dirname "$0")" && pwd)/mineru_to_paper_md.py" \
  "$(dirname "$MIDDLE")" "$OUT" "$PDF"
