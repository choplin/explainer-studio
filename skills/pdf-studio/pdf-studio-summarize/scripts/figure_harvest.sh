#!/usr/bin/env bash
# figure_harvest.sh — harvest figure/chart crops from a PDF with local MinerU and
# materialize:
#   <ocr-dir>/figures/fig-pNNN-K.ext   figures (diagrams/plots/photos), named by
#                                      absolute PDF page
#   <ocr-dir>/figures.md               metadata index: label / file / page / caption
#
# Usage: figure_harvest.sh <pdf-path> <ocr-dir> [start-page] [end-page]
#   start-page / end-page  1-based PDF page range to harvest (inclusive).
#                          Omit to harvest the whole PDF.
#
# This is the pdf-studio figure-extraction phase. It complements the visual text
# extraction (which the no-Bash workers do): MinerU pulls the genuine figures
# that visual reading cannot hold as text. Tables and console output are left to
# the text stream (see mineru_figures.py). Nothing is uploaded — MinerU's
# pipeline backend runs fully locally.
#
# IMPORTANT: MinerU 3.x starts a local service and uses multiprocessing, which
# the command sandbox blocks (semaphore limit -> "Operation not permitted"). Run
# this WITHOUT the sandbox. It is local-only, so that is safe.
#
# Requires the `mineru` CLI (NOT installed by this script) and poppler's
# `pdfinfo`. If `mineru` is missing this exits non-zero with the setup command;
# the caller should relay it and continue without figures (figure harvest is an
# enhancement, not a hard dependency of the pipeline).

set -euo pipefail

if [[ $# -lt 2 || $# -gt 4 ]]; then
  echo "usage: $0 <pdf-path> <ocr-dir> [start-page] [end-page]" >&2
  exit 2
fi

PDF=$1
OUT=$2
START=${3:-1}
END=${4:-}

[[ -f "$PDF" ]] || { echo "error: PDF not found: $PDF" >&2; exit 1; }

if ! command -v mineru >/dev/null; then
  cat >&2 <<'EOF'
mineru not installed — skipping figure harvest (the pipeline continues without
extracted figure crops). To enable it, install MinerU once:

    uv tool install "mineru[core]"

The first run then downloads model weights (several GB).
EOF
  exit 3
fi
command -v python3 >/dev/null || { echo "error: python3 not found" >&2; exit 1; }

# Pick the reading method from the text layer (born-digital -> txt, scanned ->
# ocr). This only affects MinerU's text recognition, not the crops, but keeps
# behavior consistent with a born-digital book. `-b pipeline` is required.
TEXT_CHARS=$(pdftotext -f "$START" -l "$((START + 4))" "$PDF" - 2>/dev/null \
  | tr -cd '[:alnum:]' | wc -c | tr -d ' ')
if [[ "${TEXT_CHARS:-0}" -ge 200 ]]; then METHOD=txt; else METHOD=ocr; fi

# MinerU page range is 0-based, inclusive.
RANGE=(-s "$((START - 1))")
[[ -n "$END" ]] && RANGE+=(-e "$((END - 1))")

TMP=$(mktemp -d "${TMPDIR:-/tmp}/pdf-studio-mineru.XXXXXX")
trap 'rm -rf "$TMP"' EXIT

echo "running MinerU (-b pipeline -m $METHOD; first run downloads models)..." >&2
mineru -p "$PDF" -o "$TMP/out" -b pipeline -m "$METHOD" "${RANGE[@]}"

MIDDLE=$(find "$TMP/out" -name '*_middle.json' -print | head -1)
if [[ -z "$MIDDLE" ]]; then
  echo "error: no *_middle.json under $TMP/out — MinerU output layout changed?" >&2
  exit 1
fi

python3 "$(cd "$(dirname "$0")" && pwd)/mineru_figures.py" \
  "$(dirname "$MIDDLE")" "$OUT" "$START"
