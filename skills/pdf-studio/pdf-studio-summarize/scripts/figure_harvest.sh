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
# Launch through scripts/preflight.sh, which resolves the runtime env (poppler +
# a MinerU source, from PATH or the bundled flake). MinerU is resolved PATH-first
# here: an installed `mineru` is used as-is, else `uv run --project` provisions it
# from pyproject.toml / uv.lock (no manual/global install; first run auto-syncs a
# project-local .venv and downloads model weights, several GB — slow).

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

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# This worker assumes its runtime env is already resolved — launch it through
# scripts/preflight.sh. Guard poppler anyway so a direct call fails with a pointer.
command -v pdftotext >/dev/null || { echo "error: pdftotext not found (poppler) — launch via scripts/preflight.sh" >&2; exit 1; }

# Resolve MinerU PATH-first: use an already-installed `mineru` if present,
# otherwise resolve it in-repo via uv (auto-syncs a project-local .venv from
# pyproject.toml / uv.lock on first use).
if command -v mineru >/dev/null; then
  MINERU=(mineru)
elif command -v uv >/dev/null; then
  MINERU=(uv run --project "$SKILL_DIR" mineru)
else
  echo "error: need 'mineru' or 'uv' on PATH — launch via scripts/preflight.sh" >&2; exit 1
fi

# The converter is stdlib-only, so any python3 runs it; prefer one on PATH, else
# borrow uv's project interpreter.
if command -v python3 >/dev/null; then
  PY=(python3)
elif command -v uv >/dev/null; then
  PY=(uv run --project "$SKILL_DIR" python)
else
  echo "error: need 'python3' or 'uv' on PATH — launch via scripts/preflight.sh" >&2; exit 1
fi

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

echo "running MinerU (-b pipeline -m $METHOD; first run downloads models — slow; +venv sync if resolved via uv)..." >&2
"${MINERU[@]}" -p "$PDF" -o "$TMP/out" -b pipeline -m "$METHOD" "${RANGE[@]}"

MIDDLE=$(find "$TMP/out" -name '*_middle.json' -print | head -1)
if [[ -z "$MIDDLE" ]]; then
  echo "error: no *_middle.json under $TMP/out — MinerU output layout changed?" >&2
  exit 1
fi

"${PY[@]}" "$SKILL_DIR/scripts/mineru_figures.py" \
  "$(dirname "$MIDDLE")" "$OUT" "$START"
