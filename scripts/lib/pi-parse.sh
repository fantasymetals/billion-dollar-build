#!/usr/bin/env bash
# pi-parse.sh — Parse Pi text mode output.
#
# Source-verified against badlogic/pi-mono packages/coding-agent/src/modes/print-mode.ts:
#   - Text mode: iterates assistantMsg.content, writes each text block + \n (lines ~147-151)
#   - stopReason "error" or "aborted" → stderr + exit 1 (lines ~143-145)
#   - Exit code 0 = success, 1 = Pi error, >1 = infrastructure error
#   - Multiple text content blocks concatenated with newlines
#
# Usage:
#   source scripts/lib/pi-parse.sh
#   parse_pi_text_response "$stdout" "$stderr" "$exit_code"
#   status_json=$(extract_status_block "$stdout")

set -euo pipefail

# Parse Pi's text mode response.
# Args: stdout, stderr, exit_code
# Returns: 0 on success (stdout echoed), 1 on Pi error (stderr echoed to stderr)
parse_pi_text_response() {
  local stdout="${1:-}"
  local stderr="${2:-}"
  local exit_code="${3:-0}"

  # Pi error: stopReason "error" or "aborted" → exit 1
  # Source: print-mode.ts lines 143-145
  if [[ "$exit_code" -ne 0 ]]; then
    if [[ -n "$stderr" ]]; then
      echo "$stderr" >&2
    else
      echo "ERROR: Pi exited with code $exit_code (no stderr)" >&2
    fi
    return 1
  fi

  # Success: output Pi's text response
  # Source: print-mode.ts lines 147-151 — for loop writes each text block + \n
  echo "$stdout"
  return 0
}

# Extract structured status block from Pi's output.
# Convention from AGENTS.md: Pi ends responses with ```json:status ... ```
# Returns: JSON string if valid block found, empty string otherwise
extract_status_block() {
  local output="${1:-}"

  if [[ -z "$output" ]]; then
    echo ""
    return 0
  fi

  # Extract content between ```json:status and closing ```
  local block
  block=$(echo "$output" | sed -n '/^```json:status$/,/^```$/p' | sed '1d;$d')

  if [[ -z "$block" ]]; then
    echo ""
    return 0
  fi

  # Validate it's parseable JSON
  if echo "$block" | jq . >/dev/null 2>&1; then
    echo "$block"
  else
    echo "" 
  fi
}

# Get a field from the last extracted status block.
# Args: json_string, field_name
# Returns: field value or empty string
get_status_field() {
  local json="${1:-}"
  local field="${2:-}"

  if [[ -z "$json" ]] || [[ -z "$field" ]]; then
    echo ""
    return 0
  fi

  echo "$json" | jq -r ".$field // empty" 2>/dev/null || echo ""
}

# Validate a status block has all required fields with correct types.
# Convention from AGENTS.md Section 11: Output format for print mode.
# Required fields: phase, gates_passing, gates_failing, files_changed,
#                  git_commit, git_pushed, next_step
# Returns: 0 if valid, 1 if invalid. Errors printed to stderr.
validate_status_block() {
  local json="${1:-}"

  if [[ -z "$json" ]]; then
    echo "ERROR: Empty status block" >&2
    return 1
  fi

  # Validate it's parseable JSON
  if ! echo "$json" | jq . >/dev/null 2>&1; then
    echo "ERROR: Status block is not valid JSON" >&2
    return 1
  fi

  local errors=0

  # Required fields existence check
  local required_fields=("phase" "gates_passing" "gates_failing" "files_changed" "git_commit" "git_pushed" "next_step")
  for field in "${required_fields[@]}"; do
    if ! echo "$json" | jq -e "has(\"$field\")" >/dev/null 2>&1; then
      echo "ERROR: Missing required field: $field" >&2
      ((errors++))
    fi
  done

  # Phase must be a valid enum value
  local phase
  phase=$(echo "$json" | jq -r '.phase // empty' 2>/dev/null)
  case "$phase" in
    BOOTSTRAP|RED|GREEN|REFACTOR|ANALYSIS) ;;
    *)
      echo "ERROR: Invalid phase '$phase' — must be BOOTSTRAP, RED, GREEN, REFACTOR, or ANALYSIS" >&2
      ((errors++))
      ;;
  esac

  # gates_passing and gates_failing must be arrays
  if ! echo "$json" | jq -e '.gates_passing | type == "array"' >/dev/null 2>&1; then
    echo "ERROR: gates_passing must be an array" >&2
    ((errors++))
  fi
  if ! echo "$json" | jq -e '.gates_failing | type == "array"' >/dev/null 2>&1; then
    echo "ERROR: gates_failing must be an array" >&2
    ((errors++))
  fi

  # files_changed must be an array
  if ! echo "$json" | jq -e '.files_changed | type == "array"' >/dev/null 2>&1; then
    echo "ERROR: files_changed must be an array" >&2
    ((errors++))
  fi

  # git_commit must be a string or null
  local commit_type
  commit_type=$(echo "$json" | jq -r '.git_commit | type' 2>/dev/null)
  if [[ "$commit_type" != "string" ]] && [[ "$commit_type" != "null" ]]; then
    echo "ERROR: git_commit must be a string or null, got $commit_type" >&2
    ((errors++))
  fi

  # git_pushed must be a boolean
  if ! echo "$json" | jq -e '.git_pushed | type == "boolean"' >/dev/null 2>&1; then
    echo "ERROR: git_pushed must be a boolean" >&2
    ((errors++))
  fi

  # next_step must be a non-empty string
  local next_step
  next_step=$(echo "$json" | jq -r '.next_step // empty' 2>/dev/null)
  if [[ -z "$next_step" ]]; then
    echo "ERROR: next_step must be a non-empty string" >&2
    ((errors++))
  fi

  [[ $errors -eq 0 ]] && return 0 || return 1
}
