#!/usr/bin/env bash
# run-pi.test.sh — Tests for scripts/run-pi.sh
# Deterministic tests for argument/env validation and script structure.

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

echo "=== run-pi.test.sh ==="
SCRIPT_CONTENT=$(cat "$REPO_ROOT/scripts/run-pi.sh")

# ---- Deterministic: argument validation ----

# Test: fails without prompt
output=$(SANDBOX_ID="fake" E2B_API_KEY="test" \
  bash "$REPO_ROOT/scripts/run-pi.sh" 2>&1)
ec=$?
assert_eq "fails without prompt" "1" "$ec"
assert_contains "usage message on no prompt" "Usage" "$output"

# Test: fails without sandbox ID
output=$(SANDBOX_ID="" E2B_API_KEY="test" \
  bash "$REPO_ROOT/scripts/run-pi.sh" "test prompt" 2>&1)
ec=$?
assert_eq "fails without sandbox ID" "1" "$ec"
assert_contains "error mentions sandbox ID" "sandbox" "$output"

# ---- Deterministic: script structure ----

# Test: sources Phase 1+2 libraries
assert_contains "sources pi-invoke.sh" "pi-invoke.sh" "$SCRIPT_CONTENT"
assert_contains "sources e2b-exec.sh" "e2b-exec.sh" "$SCRIPT_CONTENT"
assert_contains "sources e2b-lifecycle.sh" "e2b-lifecycle.sh" "$SCRIPT_CONTENT"

# Test: uses build_pi_command (Phase 2 library)
assert_contains "uses build_pi_command" "build_pi_command" "$SCRIPT_CONTENT"

# Test: uses exec_and_capture (not raw e2b sandbox exec)
assert_contains "uses exec_and_capture" "exec_and_capture" "$SCRIPT_CONTENT"

# Test: uses is_sandbox_alive (health check before exec)
assert_contains "uses is_sandbox_alive" "is_sandbox_alive" "$SCRIPT_CONTENT"

# Test: reads sandbox ID from .sandbox-id as fallback
assert_contains "reads from .sandbox-id" ".sandbox-id" "$SCRIPT_CONTENT"

# Test: supports --continue flag
assert_contains "supports --continue" "--continue" "$SCRIPT_CONTENT"

# Test: supports --json flag
assert_contains "supports --json" "--json" "$SCRIPT_CONTENT"

# Test: supports --status-only flag (Phase 4)
assert_contains "supports --status-only" "--status-only" "$SCRIPT_CONTENT"

# Test: sources pi-parse.sh (Phase 4 — needed for extract/validate)
assert_contains "sources pi-parse.sh" "pi-parse.sh" "$SCRIPT_CONTENT"

# Test: sets PROJECT_DIR default to /home/user/project
assert_contains "default PROJECT_DIR" "/home/user/project" "$SCRIPT_CONTENT"

# Test: sets NO_COLOR=1
assert_contains "sets NO_COLOR=1" "NO_COLOR=1" "$SCRIPT_CONTENT"

# Test: does NOT pass --no-context-files
assert_not_contains "never passes --no-context-files" "--no-context-files" "$SCRIPT_CONTENT"

# Test: does NOT pass --no-skills
assert_not_contains "never passes --no-skills" "--no-skills" "$SCRIPT_CONTENT"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] || exit 1
