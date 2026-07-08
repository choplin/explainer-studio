#!/usr/bin/env bash
# text_layer.sh — faithful body text for a born-digital PDF page range, using
# poppler's `pdftotext -layout`. Each page is prefixed with a `[pNN]` anchor
# (PDF page number). Writes to <out-file>.
#
# Usage: text_layer.sh <pdf-path> <out-file> <start-page> <end-page>
#   start-page / end-page  1-based PDF page range (inclusive)
#
# This is the opt-in text-layer path of pdf-studio: for a purchased/born-digital
# ebook, `-layout` preserves code listings, commands, numbers, and console
# output (box-drawing tables, column alignment) far more faithfully than visual
# OCR reading — and needs only poppler, which pdf-studio already requires. It is
# NOT for scanned/captured PDFs (no text layer): probe first (see --probe) and
# fall back to visual reading when the text layer is empty.
#
# --probe mode: `text_layer.sh --probe <pdf-path> <start-page>` prints the
# alphanumeric character count of a 5-page sample starting at <start-page> and
# exits 0 if it looks born-digital (>= 200) or 1 if not, so the orchestrator can
# gate the text-layer option.

set -euo pipefail

command -v pdftotext >/dev/null || { echo "error: pdftotext not found (install poppler)" >&2; exit 2; }

if [[ "${1:-}" == "--probe" ]]; then
  PDF=${2:?usage: text_layer.sh --probe <pdf-path> <start-page>}
  START=${3:-1}
  CHARS=$(pdftotext -layout -f "$START" -l "$((START + 4))" "$PDF" - 2>/dev/null \
    | tr -cd '[:alnum:]' | wc -c | tr -d ' ')
  echo "${CHARS:-0}"
  [[ "${CHARS:-0}" -ge 200 ]]
  exit $?
fi

if [[ $# -ne 4 ]]; then
  echo "usage: $0 <pdf-path> <out-file> <start-page> <end-page>" >&2
  echo "       $0 --probe <pdf-path> <start-page>" >&2
  exit 2
fi

PDF=$1
OUT=$2
START=$3
END=$4

[[ -f "$PDF" ]] || { echo "error: PDF not found: $PDF" >&2; exit 1; }

: > "$OUT"
# One pdftotext call per page keeps the [pNN] anchor exact (no form-feed
# parsing). poppler calls are milliseconds, so a chunk of pages is cheap.
for ((p = START; p <= END; p++)); do
  printf '[p%02d]\n\n' "$p" >> "$OUT"
  pdftotext -layout -f "$p" -l "$p" "$PDF" - 2>/dev/null >> "$OUT" || true
  printf '\n' >> "$OUT"
done

echo "text layer: pages $START-$END -> $OUT"
