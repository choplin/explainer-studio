#!/usr/bin/env bash

set -u
set -o pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REQUIRED_VALIDATOR_VERSION="v1.5.6"
readonly VALIDATOR_ARGS=(
  validate structure
  --allow-extra-frontmatter
  --skip-orphans
  --allow-flat-layouts
  --allow-dirs=docs,examples,filters,site,src
  --allow-nested-paths=assets/components
  --exclude-token-paths=site
)
readonly INVALID_FIXTURE="tests/fixtures/invalid-skill-frontmatter"

cd "${REPO_ROOT}" || exit 1

if ! command -v skill-validator >/dev/null 2>&1; then
  echo "error: skill-validator is required (expected ${REQUIRED_VALIDATOR_VERSION})" >&2
  echo "install it with: brew install agent-ecosystem/tap/skill-validator" >&2
  exit 1
fi

actual_version="$(skill-validator --version)"
expected_version="skill-validator version ${REQUIRED_VALIDATOR_VERSION}"
if [[ "${actual_version}" != "${expected_version}" ]]; then
  echo "error: expected '${expected_version}', got '${actual_version}'" >&2
  exit 1
fi

validator_help="$(skill-validator validate structure --help)"
for required_flag in allow-nested-paths exclude-token-paths; do
  if [[ "${validator_help}" != *"--${required_flag}"* ]]; then
    echo "error: skill-validator ${REQUIRED_VALIDATOR_VERSION} lacks required --${required_flag} support" >&2
    exit 1
  fi
done

validation_failed=0
skill_count=0
while IFS= read -r -d '' skill_md; do
  skill_dir="${skill_md%/SKILL.md}"
  skill_count=$((skill_count + 1))

  echo "==> Validating ${skill_dir}"
  skill-validator "${VALIDATOR_ARGS[@]}" "${skill_dir}"
  exit_code=$?

  case "${exit_code}" in
    0)
      ;;
    2)
      echo "error: ${skill_dir} has advisory findings" >&2
      validation_failed=1
      ;;
    *)
      validation_failed=1
      ;;
  esac
done < <(find skills -type f -name SKILL.md -print0)

if [[ "${skill_count}" -eq 0 ]]; then
  echo "error: no skills/**/SKILL.md files found" >&2
  validation_failed=1
fi

fixture_output="$(mktemp /tmp/explainer-studio-skill-check.XXXXXX)"
trap 'rm -f "${fixture_output}"' EXIT

echo "==> Verifying invalid-frontmatter regression fixture"
skill-validator validate structure "${INVALID_FIXTURE}" >"${fixture_output}" 2>&1
fixture_exit_code=$?
cat "${fixture_output}"

if [[ "${fixture_exit_code}" -ne 1 ]] ||
  ! grep -q "frontmatter YAML" "${fixture_output}"; then
  echo "error: invalid-frontmatter fixture was not rejected as a YAML error" >&2
  validation_failed=1
fi

if [[ "${validation_failed}" -ne 0 ]]; then
  echo "Agent Skill validation failed" >&2
  exit 1
fi

echo "Agent Skill validation passed for ${skill_count} skill packages with no warnings"
