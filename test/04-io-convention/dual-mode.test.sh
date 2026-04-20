#!/usr/bin/env bash
# dual-mode.test.sh — Tests for dual-mode execution and --status-only flag
# Deterministic tests for script structure and flag support.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

set +e

PASS=0
FAIL=0

assert_contains() {
  local desc="$1" needle="$2" haystack="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    echo "  PASS: $desc"
    ((PASS++))
  else
    echo "  FAIL: $desc"
    echo "    expected to contain: $needle"
    echo "    actual: $haystack"
    ((FAIL++))
  fi
}

assert_not_contains() {
  local desc="$1" needle="$2" haystack="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    echo "  PASS: $desc"
    ((PASS++))
  else
    echo "  FAIL: $desc"
    echo "    should NOT contain: $needle"
    echo "    actual: $haystack"
    ((FAIL++))
  fi
}

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

echo "=== dual-mode.test.sh ==="

SCRIPT_CONTENT=$(cat "$REPO_ROOT/scripts/run-pi.sh")

# ---- run-pi.sh supports both modes ----

# Test: default is text mode (uses pi -p)
assert_contains "sources pi-invoke.sh for text mode" "pi-invoke.sh" "$SCRIPT_CONTENT"

# Test: --json flag exists
assert_contains "supports --json flag" "--json" "$SCRIPT_CONTENT"

# Test: --json short form -j exists
assert_contains "supports -j short flag" "|-j)" "$SCRIPT_CONTENT"

# Test: --status-only flag exists
assert_contains "supports --status-only flag" "--status-only" "$SCRIPT_CONTENT"

# Test: --status-only short form -s exists
assert_contains "supports -s short flag" "|-s)" "$SCRIPT_CONTENT"

# Test: --status-only uses extract_status_block
assert_contains "status-only uses extract_status_block" "extract_status_block" "$SCRIPT_CONTENT"

# Test: --status-only uses validate_status_block
assert_contains "status-only uses validate_status_block" "validate_status_block" "$SCRIPT_CONTENT"

# Test: sources pi-parse.sh (needed for extract/validate)
assert_contains "sources pi-parse.sh" "pi-parse.sh" "$SCRIPT_CONTENT"

# ---- pi-invoke.sh builds correct commands for each mode ----

source "$REPO_ROOT/scripts/lib/pi-invoke.sh"
set +e

# Test: default mode is text (no --mode flag)
result=$(build_pi_command "test prompt")
assert_not_contains "default mode omits --mode " "--mode " "$result"

# Test: json mode adds --mode json
result=$(build_pi_command "test prompt" --mode json)
assert_contains "json mode adds --mode json" "--mode json" "$result"

# Test: both modes use -p (print mode)
result=$(build_pi_command "test prompt")
assert_contains "text mode starts with pi -p" "pi -p" "$result"

result=$(build_pi_command "test prompt" --mode json)
assert_contains "json mode starts with pi -p" "pi -p" "$result"

# ---- --status-only validation path ----

# Test: usage message includes --status-only
output=$(SANDBOX_ID="fake" bash "$REPO_ROOT/scripts/run-pi.sh" 2>&1)
assert_contains "usage mentions --status-only" "status-only" "$output"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] || exit 1
