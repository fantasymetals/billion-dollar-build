#!/usr/bin/env bash
# verify.test.sh — Tests for scripts/verify.sh
# Deterministic tests for argument validation and script structure.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

set +e

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

echo "=== verify.test.sh ==="
SCRIPT_CONTENT=$(cat "$REPO_ROOT/scripts/verify.sh")

# ---- Deterministic: argument validation ----

# Test: fails without sandbox ID (no .sandbox-id file, no env var, no arg)
output=$(SANDBOX_ID="" bash "$REPO_ROOT/scripts/verify.sh" 2>&1)
ec=$?
assert_eq "fails without sandbox ID" "1" "$ec"
assert_contains "error mentions sandbox" "sandbox" "$output"

# ---- Deterministic: script structure ----

# Test: sources Phase 1+2 libraries
assert_contains "sources e2b-exec.sh" "e2b-exec.sh" "$SCRIPT_CONTENT"
assert_contains "sources e2b-lifecycle.sh" "e2b-lifecycle.sh" "$SCRIPT_CONTENT"
assert_contains "sources pi-invoke.sh" "pi-invoke.sh" "$SCRIPT_CONTENT"

# Test: uses is_sandbox_alive
assert_contains "uses is_sandbox_alive" "is_sandbox_alive" "$SCRIPT_CONTENT"

# Test: uses exec_and_capture
assert_contains "uses exec_and_capture" "exec_and_capture" "$SCRIPT_CONTENT"

# Test: uses build_pi_command for Pi diagnostic
assert_contains "uses build_pi_command" "build_pi_command" "$SCRIPT_CONTENT"

# Test: checks bun is installed
assert_contains "checks bun" "bun --version" "$SCRIPT_CONTENT"

# Test: checks pi is installed
assert_contains "checks pi" "pi --version" "$SCRIPT_CONTENT"

# Test: checks project directory exists
assert_contains "checks project dir" "/home/user/project" "$SCRIPT_CONTENT"

# Test: checks .pi/SYSTEM.md exists
assert_contains "checks SYSTEM.md" "SYSTEM.md" "$SCRIPT_CONTENT"

# Test: checks AGENTS.md exists
assert_contains "checks AGENTS.md" "AGENTS.md" "$SCRIPT_CONTENT"

# Test: checks git credentials
assert_contains "checks git credentials" ".git-credentials" "$SCRIPT_CONTENT"

# Test: checks Pi auth
assert_contains "checks Pi auth" "auth.json" "$SCRIPT_CONTENT"

# Test: reports PASS/FAIL for each check
assert_contains "reports PASS" "PASS:" "$SCRIPT_CONTENT"
assert_contains "reports FAIL" "FAIL:" "$SCRIPT_CONTENT"

# Test: exit 1 on failures
assert_contains "exits 1 on failures" "exit 1" "$SCRIPT_CONTENT"

# Test: sets NO_COLOR=1
assert_contains "sets NO_COLOR=1" "NO_COLOR=1" "$SCRIPT_CONTENT"

# Test: supports SKIP_PI_DIAGNOSTIC env var
assert_contains "supports SKIP_PI_DIAGNOSTIC" "SKIP_PI_DIAGNOSTIC" "$SCRIPT_CONTENT"

# Test: reads sandbox ID from .sandbox-id as fallback
assert_contains "reads from .sandbox-id" ".sandbox-id" "$SCRIPT_CONTENT"

# Test: accepts sandbox ID as positional arg
# The script uses ${1:-...} pattern
assert_contains "accepts positional arg" '${1:-' "$SCRIPT_CONTENT"

# Test: does NOT directly read files in /home/user/project (uses exec_and_capture)
# verify.sh should use exec to check files inside the sandbox, not read them directly
assert_not_contains "does not cat project files directly" "cat /home/user/project" "$SCRIPT_CONTENT"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] || exit 1
