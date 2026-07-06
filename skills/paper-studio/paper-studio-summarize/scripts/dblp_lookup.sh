#!/usr/bin/env bash
# dblp_lookup.sh — look up a paper title on dblp and print candidate
# bibliographic records, one JSON object per line:
#   {key, type, title, authors, venue, year, doi, url}
# url prefers the electronic edition (usually a doi.org link). `key` is the
# dblp record key (e.g. conf/nips/VaswaniSPUJGKP17) — pass it to
# dblp_bibtex.sh to fetch the canonical BibTeX. `type` distinguishes a
# peer-reviewed venue from a preprint ("Informal and Other Publications").
#
# Usage: dblp_lookup.sh "<paper title> <first-author surname>"
#
# Include the first author's surname in the query: dblp ranks by term match,
# and a title-only query for a generic title (e.g. "Attention Is All You
# Need") does NOT surface the right paper. Retry with the title alone only
# if the combined query returns nothing.
#
# No API key required (public dblp API). Empty output means no dblp hit —
# report the reference as "dblp未確認" rather than inventing bibliography.

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 \"<paper title>\"" >&2
  exit 2
fi

command -v curl >/dev/null || { echo "error: curl not found" >&2; exit 1; }
command -v jq >/dev/null || { echo "error: jq not found" >&2; exit 1; }

curl -sSG 'https://dblp.org/search/publ/api' \
  --data-urlencode "q=$*" \
  --data-urlencode 'format=json' \
  --data-urlencode 'h=5' |
  jq -c '
    (.result.hits.hit // [])[]
    | .info
    | {
        key: (.key // null),
        type: (.type // null),
        title,
        authors: ((.authors.author // []) | if type == "array" then map(.text) else [.text] end),
        venue,
        year,
        doi: (.doi // null),
        url: (.ee // .url // null)
      }
  '
