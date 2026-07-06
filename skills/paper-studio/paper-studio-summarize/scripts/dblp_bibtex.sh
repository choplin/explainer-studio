#!/usr/bin/env bash
# dblp_bibtex.sh — fetch the canonical BibTeX for a dblp record key.
#
# Usage: dblp_bibtex.sh <dblp-key>
#   e.g. dblp_bibtex.sh conf/nips/VaswaniSPUJGKP17
#
# The key comes from dblp_lookup.sh's `key` field. Prints the BibTeX entry
# (dblp's `param=1` standard format) to stdout. No API key required.
#
# dblp's .bib endpoint returns transient 503s under load — this retries a few
# times. If it still fails, exit non-zero and print nothing so the caller can
# fall back to a hand-built entry (never fabricate one silently).

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <dblp-key>" >&2
  exit 2
fi

command -v curl >/dev/null || { echo "error: curl not found" >&2; exit 1; }

KEY=$1
URL="https://dblp.org/rec/${KEY}.bib?param=1"

for attempt in 1 2 3 4; do
  body=$(curl -sS --max-time 25 "$URL" || true)
  if printf '%s' "$body" | grep -q '^@'; then
    printf '%s\n' "$body"
    exit 0
  fi
  sleep $((attempt * 2))
done

echo "error: could not fetch BibTeX for '$KEY' from dblp (last response was not a BibTeX entry)" >&2
exit 1
