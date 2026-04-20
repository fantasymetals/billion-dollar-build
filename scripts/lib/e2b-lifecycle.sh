#!/usr/bin/env bash
# e2b-lifecycle.sh — Sandbox lifecycle management.
#
# Provides state checking, health monitoring, and cleanup helpers.
#
# Usage:
#   source scripts/lib/e2b-lifecycle.sh
#   state=$(get_sandbox_state <sandbox_id>)
#   is_sandbox_alive <sandbox_id> && echo "running"

set -euo pipefail

# Strip ANSI escape codes from text
_strip_ansi() {
  sed 's/\x1b\[[0-9;]*m//g'
}

get_sandbox_state() {
  local sandbox_id="${1:?Usage: get_sandbox_state <sandbox_id>}"

  local raw
  raw=$(e2b sandbox list 2>/dev/null | _strip_ansi) || {
    echo "not_found"
    return 0
  }

  # Find line containing our sandbox ID, then extract the state field
  # After stripping ANSI, table lines look like:
  #   ikkbhsxkhcwvpww52thtg  hqaeeabrc1z06vguyx00  pi-bun-sandbox  4/16/2026, 9:22:18 PM  4/16/2026, 9:27:19 PM  Running  2      4096     0.5.11        {}
  local line
  line=$(echo "$raw" | grep "$sandbox_id" || true)

  if [[ -z "$line" ]]; then
    echo "not_found"
    return 0
  fi

  # Extract state by matching known state words
  local state
  state=$(echo "$line" | grep -oP '\b(Running|Paused|Stopped)\b' | head -1)

  if [[ -z "$state" ]]; then
    echo "not_found"
    return 0
  fi

  # Normalize to lowercase
  echo "${state,,}"
}

is_sandbox_alive() {
  local state
  state=$(get_sandbox_state "$1")
  [[ "$state" == "running" ]]
}

# Kill a sandbox
kill_sandbox() {
  local sandbox_id="${1:?Usage: kill_sandbox <sandbox_id>}"
  e2b sandbox kill "$sandbox_id" 2>/dev/null || true
}

# List all running sandboxes, optionally filtered by template
list_sandboxes() {
  local template_id="${1:-}"
  local raw
  raw=$(e2b sandbox list 2>/dev/null | _strip_ansi) || return 0

  # Skip header lines (first 2 lines are title + column headers)
  local data
  data=$(echo "$raw" | tail -n +3 | grep -v '^\s*$')

  if [[ -n "$template_id" ]]; then
    echo "$data" | grep "$template_id" | awk '{print $1}'
  else
    echo "$data" | awk '{print $1}' | grep -v '^$'
  fi
}
