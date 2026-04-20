#!/usr/bin/env bash
# sandbox-lifecycle.test.sh — Tests for get_sandbox_state() and is_sandbox_alive()
# Requires a live E2B sandbox (integration test).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source library (sets -euo pipefail internally), then relax for test control
source "$REPO_ROOT/scripts/lib/e2b-lifecycle.sh"
set +e

: "${E2B_API_KEY:?E2B_API_KEY required for integration tests}"
: "${TEST_SANDBOX_ID:?TEST_SANDBOX_ID required — create a sandbox first}"

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

echo "=== sandbox-lifecycle.test.sh (integration) ==="
SBX="$TEST_SANDBOX_ID"

# Test: running sandbox returns "running"
state=$(get_sandbox_state "$SBX")
assert_eq "get_sandbox_state returns 'running' for active sandbox" "running" "$state"

# Test: is_sandbox_alive returns 0 for running
if is_sandbox_alive "$SBX"; then
  echo "  PASS: is_sandbox_alive returns 0 for running sandbox"
  ((PASS++))
else
  echo "  FAIL: is_sandbox_alive should return 0 for running sandbox"
  ((FAIL++))
fi

# Test: nonexistent sandbox returns "not_found"
state=$(get_sandbox_state "nonexistent_sandbox_id_xyz")
assert_eq "get_sandbox_state returns 'not_found' for missing sandbox" "not_found" "$state"

# Test: is_sandbox_alive returns 1 for missing sandbox
if is_sandbox_alive "nonexistent_sandbox_id_xyz"; then
  echo "  FAIL: is_sandbox_alive should return 1 for missing sandbox"
  ((FAIL++))
else
  echo "  PASS: is_sandbox_alive returns 1 for missing sandbox"
  ((PASS++))
fi

# Test: list_sandboxes returns at least our sandbox
sandboxes=$(list_sandboxes)
if echo "$sandboxes" | grep -q "$SBX"; then
  echo "  PASS: list_sandboxes includes our active sandbox"
  ((PASS++))
else
  echo "  FAIL: list_sandboxes should include $SBX"
  echo "    got: $sandboxes"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] || exit 1
