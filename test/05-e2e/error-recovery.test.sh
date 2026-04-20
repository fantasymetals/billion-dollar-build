#!/usr/bin/env bash
# error-recovery.test.sh — Tests for failure scenarios
# Mix of deterministic + integration tests (gated).

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

echo "=== error-recovery.test.sh ==="

# ---- Deterministic: run-pi.sh reports error for fake sandbox ----

output=$(SANDBOX_ID="nonexistent_sandbox_id" E2B_API_KEY="${E2B_API_KEY:-fake}" \
  bash "$REPO_ROOT/scripts/run-pi.sh" "test prompt" 2>&1)
ec=$?
assert_eq "run-pi fails for nonexistent sandbox" "1" "$ec"
assert_contains "error mentions sandbox not running" "not running" "$output"

# ---- Deterministic: bootstrap fails with invalid E2B_API_KEY ----

output=$(E2B_API_KEY="e2b_invalid_key_12345" APP_INSTALLATION_TOKEN="x" PI_AUTH_JSON="{}" \
  bash "$REPO_ROOT/scripts/bootstrap.sh" "fake-template" "https://github.com/test/repo" 2>&1)
ec=$?
assert_eq "bootstrap fails with invalid API key" "1" "$ec"

# ---- Deterministic: verify fails for nonexistent sandbox ----

output=$(SANDBOX_ID="nonexistent_sandbox_id" E2B_API_KEY="${E2B_API_KEY:-fake}" SKIP_PI_DIAGNOSTIC=1 \
  bash "$REPO_ROOT/scripts/verify.sh" 2>&1)
ec=$?
assert_eq "verify fails for nonexistent sandbox" "1" "$ec"

# ---- Integration: sandbox dead after kill (gated) ----

if [[ -n "${E2B_API_KEY:-}" ]]; then
  echo ""
  echo "Integration tests (live):"

  source "$REPO_ROOT/scripts/lib/e2b-lifecycle.sh"
  source "$REPO_ROOT/scripts/lib/e2b-parse.sh"
  set +e
  export NO_COLOR=1

  # Create a sandbox just to kill it
  create_output=$(e2b sandbox create "hqaeeabrc1z06vguyx00" --detach 2>&1)
  SBX=$(parse_sandbox_id "$create_output")

  if [[ -n "$SBX" ]]; then
    # Kill it
    kill_sandbox "$SBX" 2>/dev/null

    sleep 1

    # run-pi.sh should fail for killed sandbox
    output=$(SANDBOX_ID="$SBX" bash "$REPO_ROOT/scripts/run-pi.sh" "test" 2>&1)
    ec=$?
    assert_eq "run-pi fails after sandbox killed" "1" "$ec"
    assert_contains "reports sandbox not running" "not running" "$output"
  else
    echo "  SKIP: Could not create sandbox for kill test"
  fi
else
  echo ""
  echo "Integration tests: SKIPPED (no E2B_API_KEY)"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] || exit 1
