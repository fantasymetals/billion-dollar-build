#!/usr/bin/env bash
# e2b-parse.sh — Parse sandbox ID from E2B CLI output.
#
# Source-verified against e2b-dev/E2B packages/cli/src/commands/sandbox/create.ts:
#   Output format: "Sandbox created with ID <id> using template <template>"
#   The ID is a 20-21 character lowercase alphanumeric string.
#
# Usage:
#   source scripts/lib/e2b-parse.sh
#   sandbox_id=$(parse_sandbox_id "$raw_output")

set -euo pipefail

parse_sandbox_id() {
  local output="${1:-}"

  if [[ -z "$output" ]]; then
    echo "ERROR: Empty output — cannot parse sandbox ID" >&2
    return 1
  fi

  # Strip ANSI escape codes
  local clean
  clean=$(echo "$output" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/\x1b\]8;;[^\x1b]*\x1b\\//g')

  # Extract ID from "Sandbox created with ID <id>"
  local id
  id=$(echo "$clean" | grep -oP 'Sandbox created with ID \K[a-z0-9]+' | head -1)

  if [[ -z "$id" ]]; then
    echo "ERROR: Failed to parse sandbox ID from output" >&2
    echo "Output was: $clean" >&2
    return 1
  fi

  # Validate ID format (20-21 lowercase alphanumeric chars)
  if [[ ! "$id" =~ ^[a-z0-9]{15,25}$ ]]; then
    echo "ERROR: Parsed ID '$id' does not match expected format" >&2
    return 1
  fi

  echo "$id"
}
