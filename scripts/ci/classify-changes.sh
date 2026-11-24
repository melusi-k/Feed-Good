#!/usr/bin/env bash
# Classify a pull request as documentation-only using a conservative path allowlist.
# Usage: classify-changes.sh EVENT_NAME BASE_SHA HEAD_SHA
set -euo pipefail

event_name="${1:-}"
base_sha="${2:-}"
head_sha="${3:-}"
docs_only=false
changed_files=()

if [[ "$event_name" == "pull_request" ]] && [[ -n "$base_sha" ]] && [[ -n "$head_sha" ]] &&
   git cat-file -e "${base_sha}^{commit}" 2>/dev/null &&
   git cat-file -e "${head_sha}^{commit}" 2>/dev/null; then
  if mapfile -d '' -t changed_files < <(git diff --no-renames --name-only -z "${base_sha}...${head_sha}"); then
    if (( ${#changed_files[@]} > 0 )); then
      docs_only=true
      for path in "${changed_files[@]}"; do
        case "$path" in
          docs/*|README.md|CONTRIBUTING.md|CHANGELOG.md|LICENSE|LICENSE.md)
            ;;
          *)
            docs_only=false
            break
            ;;
        esac
      done
    fi
  else
    docs_only=false
  fi
fi

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  printf 'docs_only=%s\n' "$docs_only" >> "$GITHUB_OUTPUT"
fi

printf 'Documentation-only change: %s\n' "$docs_only"
if (( ${#changed_files[@]} > 0 )); then
  printf 'Changed paths:\n'
  printf ' - %s\n' "${changed_files[@]}"
fi
