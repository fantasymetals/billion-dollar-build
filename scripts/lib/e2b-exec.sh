#!/usr/bin/env bash
# e2b-exec.sh — Execute commands in E2B sandboxes with proper output routing.
#
# Source-verified against e2b-dev/E2B packages/cli/src/commands/sandbox/exec.ts:
#   - Lines 112-119: stdout callback writes to process.stdout
#   - Lines 120-127: stderr callback writes to process.stderr
#   - Lines 141-143: exit code forwarded from handle.wait().exitCode
#
# Usage:
#   source scripts/lib/e2b-exec.sh
#   exec_and_capture <sandbox_id> <command> [cwd]

set -euo pipefail

exec_and_capture() {
  local sandbox_id="${1:?Usage: exec_and_capture <sandbox_id> <command> [cwd]}"
  local command="${2:?Usage: exec_and_capture <sandbox_id> <command> [cwd]}"
  local cwd="${3:-/home/user/project}"

  local stdout_file stderr_file
  stdout_file=$(mktemp)
  stderr_file=$(mktemp)

  local exit_code=0
  NO_COLOR=1 e2b sandbox exec -c "$cwd" "$sandbox_id" "$command" \
    > "$stdout_file" 2> "$stderr_file" || exit_code=$?

  # Route outputs to correct streams
  cat "$stdout_file"
  cat "$stderr_file" >&2

  rm -f "$stdout_file" "$stderr_file"

  return $exit_code
}

# Exec with timeout (watchdog process)
exec_with_timeout() {
  local sandbox_id="${1:?}"
  local command="${2:?}"
  local timeout_seconds="${3:-300}"
  local cwd="${4:-/home/user/project}"

  local stdout_file stderr_file
  stdout_file=$(mktemp)
  stderr_file=$(mktemp)

  local exit_code=0
  timeout "$timeout_seconds" \
    bash -c "NO_COLOR=1 e2b sandbox exec -c '$cwd' '$sandbox_id' '$command'" \
    > "$stdout_file" 2> "$stderr_file" || exit_code=$?

  cat "$stdout_file"
  cat "$stderr_file" >&2

  rm -f "$stdout_file" "$stderr_file"

  # timeout command returns 124 on timeout
  if [[ $exit_code -eq 124 ]]; then
    echo "ERROR: Command timed out after ${timeout_seconds}s" >&2
  fi

  return $exit_code
}
