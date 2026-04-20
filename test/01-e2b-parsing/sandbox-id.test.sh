#!/usr/bin/env bash
# sandbox-id.test.sh — Tests for parse_sandbox_id()
# Uses deterministic fixtures, no live E2B calls.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source the library but override set -e for test control
set +e
source "$REPO_ROOT/scripts/lib/e2b-parse.sh"
set +e  # Re-disable after source

PASS=0
FAIL=0

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "  PASS: $desc"
    ((PASS++))
  else
    echo "  FAIL: $desc"
    echo "    expected: $expected"
    echo "    actual:   $actual"
    ((FAIL++))
  fi
}

assert_fails() {
  local desc="$1"
  shift
  local output
  output=$("$@" 2>/dev/null)
  local ec=$?
  if [[ $ec -ne 0 ]]; then
    echo "  PASS: $desc"
    ((PASS++))
  else
    echo "  FAIL: $desc (should have failed but returned 0, output: $output)"
    ((FAIL++))
  fi
}

echo "=== sandbox-id.test.sh ==="

# Fixture: clean output (source: e2b CLI create.ts)
CLEAN_OUTPUT="Sandbox created with ID abc123def456ghi789jk using template pi-bun-sandbox"
result=$(parse_sandbox_id "$CLEAN_OUTPUT")
assert_eq "extracts ID from clean output" "abc123def456ghi789jk" "$result"

# Fixture: output with ANSI escape codes
ANSI_OUTPUT=$'\e[1m\e[34mSandbox created with ID abc123def456ghi789jk using template pi-bun-sandbox\e[0m'
result=$(parse_sandbox_id "$ANSI_OUTPUT")
assert_eq "extracts ID from ANSI output" "abc123def456ghi789jk" "$result"

# Fixture: real-world output with dashboard link and OSC-8 hyperlinks
REAL_OUTPUT='Use the following link to inspect this Sandbox live inside the E2B Dashboard:
https://e2b.dev/dashboard/inspect/sandbox/ijhf19l8sq72pm7al35d5

Sandbox created with ID ijhf19l8sq72pm7al35d5 using template hqaeeabrc1z06vguyx00'
result=$(parse_sandbox_id "$REAL_OUTPUT")
assert_eq "extracts ID from real CLI output with dashboard link" "ijhf19l8sq72pm7al35d5" "$result"

# Fixture: 21-char ID
LONG_ID_OUTPUT="Sandbox created with ID abcdefghijklmnopqrstu using template test"
result=$(parse_sandbox_id "$LONG_ID_OUTPUT")
assert_eq "extracts 21-char ID" "abcdefghijklmnopqrstu" "$result"

# Empty output
assert_fails "fails on empty output" parse_sandbox_id ""

# Malformed output (no sandbox ID pattern)
assert_fails "fails on malformed output" parse_sandbox_id "Error: something went wrong"

# Output with no ID at all
assert_fails "fails on output with no ID" parse_sandbox_id "Some random text without the expected pattern"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] || exit 1
