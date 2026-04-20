#!/usr/bin/env bash
set -euo pipefail

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo 'No git work tree detected; falling back to full check.'
  bun run check
  exit 0
fi

mapfile -t files < <(
  if [[ "$#" -gt 0 ]]; then
    printf '%s\n' "$@"
  else
    {
      git diff --name-only --diff-filter=ACMR HEAD -- .
      git ls-files --others --exclude-standard
    } | sort -u
  fi
)

if [[ "${#files[@]}" -eq 0 ]]; then
  echo 'No changed files detected; falling back to full check.'
  bun run check
  exit 0
fi

mapfile -t biome_files < <(printf '%s\n' "${files[@]}" | rg '\.(cjs|cts|js|json|jsx|md|mjs|mts|ts|tsx)$')

if [[ "${#biome_files[@]}" -gt 0 ]]; then
  echo 'Running format/lint on changed files only:'
  printf ' - %s\n' "${biome_files[@]}"
  bunx biome check --formatter-enabled=true --linter-enabled=false --assist-enabled=false "${biome_files[@]}"
  bunx biome check --formatter-enabled=false --linter-enabled=true --assist-enabled=false "${biome_files[@]}"
else
  echo 'No Biome-supported changed files detected.'
fi

echo 'Running full typecheck and full test suite as the current safe fallback.'
bun run typecheck
bun run test
