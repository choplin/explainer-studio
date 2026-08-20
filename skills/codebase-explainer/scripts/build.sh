#!/usr/bin/env bash
# Build one codebase explanation or a multi-page codebase reading site.
#
# Usage:
#   build.sh <src.md|src-dir> <out-dir> [--copy]
#
# A file input emits one inlined HTML file by default. A directory input requires
# index.md and nav-manifest.js and emits a copy-mode site with shared assets.
set -euo pipefail

readonly HERE="$(cd "$(dirname "$0")" && pwd)"
readonly SKILL_DIR="$(cd "${HERE}/.." && pwd)"
readonly SKILLS_ROOT="$(cd "${SKILL_DIR}/.." && pwd)"
readonly GENERATOR="${SKILLS_ROOT}/explainer/explainer-html-docs"
readonly BASE_ASSETS="${GENERATOR}/assets"
readonly TEMPLATE="${SKILL_DIR}/assets/template-codebase-explainer.html"
readonly FILTER="${SKILL_DIR}/filters/codebase-explainer.lua"

src=""
out=""
copy_mode=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --copy)
      copy_mode="1"
      shift
      ;;
    *)
      if [[ -z "${src}" ]]; then
        src="$1"
      elif [[ -z "${out}" ]]; then
        out="$1"
      else
        echo "build.sh: unexpected argument: $1" >&2
        exit 2
      fi
      shift
      ;;
  esac
done

[[ -e "${src}" ]] || { echo "build.sh: source not found: ${src}" >&2; exit 2; }
[[ -n "${out}" ]] || { echo "build.sh: missing <out-dir>" >&2; exit 2; }
[[ -x "${GENERATOR}/scripts/build.sh" ]] || {
  echo "build.sh: shared explainer-html-docs skill not found: ${GENERATOR}" >&2
  exit 2
}

context_dir="$(mktemp -d /tmp/codebase-explainer.XXXXXX)"
site_stage=""
cleanup() {
  rm -rf "${context_dir}"
  if [[ -n "${site_stage}" ]]; then
    rm -rf "${site_stage}"
  fi
}
trap cleanup EXIT

build_page() {
  local source_file="$1"
  local inline_arg="${2:-}"
  local site_arg="${3:-}"
  local args=(
    "${GENERATOR}/scripts/build.sh"
    "${source_file}"
    "${out}"
    --assets "${BASE_ASSETS}"
    --context "${context_dir}"
    --template "${TEMPLATE}"
    --filter "${FILTER}"
    --component highlight
    --component diagram
  )

  if [[ -n "${site_arg}" ]]; then
    args+=(--component reading-nav)
  fi
  if [[ -n "${inline_arg}" ]]; then
    args+=(--inline)
  fi

  bash "${args[@]}"
}

requires_site_mode() {
  awk '
    NR == 1 && $0 != "---" { exit 1 }
    NR > 1 && $0 == "---" { closed = 1; exit }
    NR > 1 && $0 ~ /^site-mode:[[:space:]]*true[[:space:]]*$/ { found = 1 }
    END { if (!closed || !found) exit 1 }
  ' "$1"
}

if [[ -f "${src}" ]]; then
  inline="--inline"
  [[ -z "${copy_mode}" ]] || inline=""
  build_page "${src}" "${inline}"
  exit 0
fi

[[ -z "${copy_mode}" ]] || {
  echo "build.sh: --copy is implicit and unnecessary for directory input" >&2
  exit 2
}
[[ -f "${src}/index.md" ]] || {
  echo "build.sh: site source requires ${src}/index.md" >&2
  exit 2
}
[[ -f "${src}/nav-manifest.js" ]] || {
  echo "build.sh: site source requires ${src}/nav-manifest.js" >&2
  exit 2
}

cp "${src}/nav-manifest.js" "${context_dir}/nav-manifest.js"

shopt -s nullglob
pages=("${src}"/*.md)
[[ ${#pages[@]} -gt 0 ]] || {
  echo "build.sh: no Markdown pages found under ${src}" >&2
  exit 2
}

for page in "${pages[@]}"; do
  requires_site_mode "${page}" || {
    echo "build.sh: site page must set 'site-mode: true': ${page}" >&2
    exit 2
  }
done

readonly final_out="${out}"
if [[ -e "${final_out}" ]]; then
  [[ -d "${final_out}" ]] || {
    echo "build.sh: site output exists and is not a directory: ${final_out}" >&2
    exit 2
  }
  [[ -z "$(ls -A "${final_out}")" ]] || {
    echo "build.sh: site output must be absent or empty: ${final_out}" >&2
    exit 2
  }
fi

# Build the complete site away from the destination. A bad later page must not
# leave a publishable-looking partial site at the requested output path.
site_stage="$(mktemp -d /tmp/codebase-explainer-site.XXXXXX)"
out="${site_stage}"
for page in "${pages[@]}"; do
  build_page "${page}" "" "--site"
done

mkdir -p "$(dirname "${final_out}")"
if [[ -d "${final_out}" ]]; then
  rmdir "${final_out}"
fi
mv "${site_stage}" "${final_out}"
site_stage=""
out="${final_out}"

echo "Site built under ${final_out}"
