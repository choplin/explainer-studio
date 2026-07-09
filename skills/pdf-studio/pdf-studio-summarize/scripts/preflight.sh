#!/usr/bin/env bash
# preflight.sh — resolve this skill's runtime environment once, then exec the
# given command inside it. Entry point for both env-dependent scripts —
# figure_harvest.sh (poppler + a MinerU source) and text_layer.sh (poppler) —
# so both work even when nothing is on the host PATH (policy:
# docs/skill-runtime-and-dependencies.md).
#
# Usage: preflight.sh <command> [args...]
#   e.g. preflight.sh bash "$SKILL_DIR/scripts/figure_harvest.sh" <pdf> <ocr-dir>
#        preflight.sh bash "$SKILL_DIR/scripts/text_layer.sh" <pdf> <out> <s> <e>
#
# The heavier path (figure harvest) needs poppler (pdftotext/pdfinfo/pdftoppm)
# plus a way to run MinerU and the stdlib converter. MinerU is resolved
# PATH-first by that worker: an installed `mineru` is used as-is, else `uv`
# provisions it from pyproject.toml / uv.lock. So the PATH is enough when poppler
# is present AND either `uv` is there (it supplies both mineru and a python) OR
# both `mineru` and `python3` are. Resolution order:
#   1. PATH already sufficient  -> exec the command directly;
#   2. else, if a flake.lock is bundled and nix is available -> run inside `nix develop`;
#   3. else -> fail with both setup options.
# The text-layer path needs only poppler; routing it through here too means it
# still works when poppler lives only in the bundled flake (a nix-only host).
set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "usage: $0 <command> [args...]" >&2
  exit 2
fi

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

has() { command -v "$1" >/dev/null; }

if has pdftotext && { has uv || { has mineru && has python3; }; }; then
  exec "$@" # PATH mode — the runtime is already available.
elif [[ -f "$SKILL_DIR/flake.lock" ]] && has nix; then
  exec nix develop "$SKILL_DIR" --command "$@" # nix mode — run inside the dev shell.
else
  cat >&2 <<EOF
error: runtime not found on PATH. Figure harvest needs poppler (pdftotext/pdfinfo/pdftoppm)
plus a MinerU source — either 'uv' (resolves MinerU in-repo) or an installed 'mineru' + 'python3'.
Provision them either way, then re-run:
  A) nix (all-in-one, no other setup): run the command inside the bundled dev shell —
       nix develop "$SKILL_DIR" --command <command> [args...]
     (requires nix with the nix-command & flakes features enabled)
  B) manual: install poppler + uv yourself —
       uv      -> https://docs.astral.sh/uv/
       poppler -> macOS: brew install poppler | Debian: apt-get install poppler-utils
EOF
  exit 1
fi
