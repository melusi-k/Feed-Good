#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
classifier="$repo_root/scripts/ci/classify-changes.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

git -C "$tmp" init -q
git -C "$tmp" config user.name "CI classifier test"
git -C "$tmp" config user.email "ci-classifier@example.invalid"
mkdir -p "$tmp/docs"
printf 'baseline\n' > "$tmp/docs/guide.md"
printf 'baseline\n' > "$tmp/README.md"
printf 'baseline\n' > "$tmp/FeedGood.swift"
git -C "$tmp" add .
git -C "$tmp" commit -qm "baseline"
base="$(git -C "$tmp" rev-parse HEAD)"

assert_classification() {
  local expected="$1"
  local actual
  actual="$(cd "$tmp" && bash "$classifier" pull_request "$base" "$(git rev-parse HEAD)" | sed -n 's/^Documentation-only change: //p')"
  if [[ "$actual" != "$expected" ]]; then
    echo "Expected docs_only=$expected, got docs_only=$actual" >&2
    exit 1
  fi
}

printf 'updated docs\n' >> "$tmp/docs/guide.md"
git -C "$tmp" commit -qam "docs update"
assert_classification true

printf 'mixed source change\n' >> "$tmp/FeedGood.swift"
git -C "$tmp" commit -qam "mixed source and docs change"
assert_classification false

mkdir -p "$tmp/.github/workflows"
printf 'name: workflow change\n' > "$tmp/.github/workflows/test.yml"
git -C "$tmp" add .
git -C "$tmp" commit -qm "workflow change"
assert_classification false

actual="$(cd "$tmp" && bash "$classifier" push "" "" | sed -n 's/^Documentation-only change: //p')"
[[ "$actual" == false ]]

actual="$(cd "$tmp" && bash "$classifier" pull_request missing missing | sed -n 's/^Documentation-only change: //p')"
[[ "$actual" == false ]]

echo "Change-classifier tests passed."
