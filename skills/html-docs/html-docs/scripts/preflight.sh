#!/usr/bin/env bash
# preflight.sh — resolve this skill's runtime (pandoc) once, then exec the given
# command inside it. Entry point for build.sh so it works even when nothing is on
# the host PATH (policy: docs/skill-runtime-and-dependencies.md).
#
# Usage: preflight.sh <command> [args...]
#   e.g. preflight.sh pandoc --version
#
# Resolution order:
#   1. pandoc already on PATH        -> exec the command directly;
#   2. else, bundled flake + nix     -> run inside `nix develop`;
#   3. else                          -> fail with both setup options.
set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "usage: $0 <command> [args...]" >&2
  exit 2
fi

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

has() { command -v "$1" >/dev/null; }

if has pandoc; then
  exec "$@" # PATH mode — pandoc is already available.
elif [[ -f "$SKILL_DIR/flake.lock" ]] && has nix; then
  exec nix develop "$SKILL_DIR" --command "$@" # nix mode — run inside the dev shell.
else
  cat >&2 <<EOF
error: pandoc not found on PATH. This generator needs pandoc.
Provision it either way, then re-run:
  A) nix (all-in-one, no other setup): run the command inside the bundled dev shell —
       nix develop "$SKILL_DIR" --command <command> [args...]
     (requires nix with the nix-command & flakes features enabled)
  B) manual: install pandoc yourself —
       macOS: brew install pandoc | Debian: apt-get install pandoc | https://pandoc.org/installing.html
EOF
  exit 1
fi
