#!/usr/bin/env bash
# exec-output.test.sh — Tests for exec_and_capture()
# Tests output routing and exit code forwarding.
# Requires a live E2B sandbox (integration test).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source library (sets -euo pipefail internally), then relax for test control
source "$REPO_ROOT/scripts/lib/e2b-exec.sh"
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

echo "=== exec-output.test.sh (integration) ==="
SBX="$TEST_SANDBOX_ID"

# Test: stdout goes to stdout
stdout_result=$(exec_and_capture "$SBX" "echo hello-stdout" "/tmp" 2>/dev/null)
assert_eq "stdout from exec goes to stdout" "hello-stdout" "$stdout_result"

# Test: stderr goes to stderr
stderr_result=$(exec_and_capture "$SBX" "echo hello-stderr >&2" "/tmp" 2>&1 1>/dev/null)
assert_contains "stderr from exec goes to stderr" "hello-stderr" "$stderr_result"

# Test: exit code 0 forwarded
exec_and_capture "$SBX" "exit 0" "/tmp" >/dev/null 2>&1
assert_eq "exit code 0 forwarded" "0" "$?"

# Test: exit code 1 forwarded
exec_and_capture "$SBX" "exit 1" "/tmp" >/dev/null 2>&1
ec=$?
assert_eq "exit code 1 forwarded" "1" "$ec"

# Test: exit code > 1 forwarded
exec_and_capture "$SBX" "exit 42" "/tmp" >/dev/null 2>&1
ec=$?
assert_eq "exit code 42 forwarded" "42" "$ec"

# Test: cwd parameter works
cwd_result=$(exec_and_capture "$SBX" "pwd" "/" 2>/dev/null)
assert_eq "cwd parameter sets working directory" "/" "$cwd_result"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] || exit 1
