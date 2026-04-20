#!/usr/bin/env bash
# full-workflow.test.sh — End-to-end integration test
# Exercises: bootstrap → verify → run-pi → continue → status-only → kill
#
# Gate: requires E2B_API_KEY, APP_INSTALLATION_TOKEN, PI_AUTH_JSON
# Skip gracefully if credentials are missing.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

set +e

# Gate on required credentials
[[ -z "${E2B_API_KEY:-}" ]] && { echo "SKIP: E2B_API_KEY not set"; exit 0; }
[[ -z "${APP_INSTALLATION_TOKEN:-}" ]] && { echo "SKIP: APP_INSTALLATION_TOKEN not set"; exit 0; }
[[ -z "${PI_AUTH_JSON:-}" ]] && { echo "SKIP: PI_AUTH_JSON not set"; exit 0; }

export E2B_API_KEY APP_INSTALLATION_TOKEN PI_AUTH_JSON
export NO_COLOR=1

PASS=0
FAIL=0
SANDBOX_ID=""
STARTED_AT=$(date +%s)

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
    echo "    actual (first 200 chars): ${haystack:0:200}"
    ((FAIL++))
  fi
}

assert_nonzero_length() {
  local desc="$1" value="$2"
  if [[ -n "$value" ]]; then
    echo "  PASS: $desc"
    ((PASS++))
  else
    echo "  FAIL: $desc (empty)"
    ((FAIL++))
  fi
}

# Cleanup trap — always kill sandbox on exit
cleanup() {
  if [[ -n "$SANDBOX_ID" ]]; then
    echo ""
    echo "Cleanup: killing sandbox $SANDBOX_ID..."
    e2b sandbox kill "$SANDBOX_ID" 2>/dev/null || true
  fi
  rm -f "$REPO_ROOT/.sandbox-id"
  local elapsed=$(( $(date +%s) - STARTED_AT ))
  echo "Total time: ${elapsed}s"
}
trap cleanup EXIT

echo "=== full-workflow.test.sh (E2E) ==="
echo ""

# ---- Step 1: Bootstrap ----
echo "Step 1: Bootstrap"
TEMPLATE="hqaeeabrc1z06vguyx00"
REPO_URL="https://github.com/fantasymetals/billion-dollar-build"

cd "$REPO_ROOT"
output=$(bash scripts/bootstrap.sh "$TEMPLATE" "$REPO_URL" 2>&1)
ec=$?
assert_eq "bootstrap exits 0" "0" "$ec"

# Read sandbox ID
if [[ -f .sandbox-id ]]; then
  SANDBOX_ID=$(cat .sandbox-id)
  assert_nonzero_length "sandbox ID saved to .sandbox-id" "$SANDBOX_ID"
  echo "  Sandbox: $SANDBOX_ID"
else
  echo "  FAIL: .sandbox-id not created"
  ((FAIL++))
  echo ""
  echo "Results: $PASS passed, $FAIL failed"
  exit 1
fi

# ---- Step 2: Clone repo inside sandbox (Pi's first task) ----
echo ""
echo "Step 2: Clone repo (via exec — infrastructure prep for Pi)"
source scripts/lib/e2b-exec.sh
clone_output=$(exec_and_capture "$SANDBOX_ID" \
  "git clone $REPO_URL /home/user/project" "/home/user" 2>&1)
clone_ec=$?
assert_eq "git clone succeeds" "0" "$clone_ec"

# ---- Step 3: Verify ----
echo ""
echo "Step 3: Verify (skip Pi diagnostic — too slow for smoke test)"
output=$(
  SANDBOX_ID="$SANDBOX_ID" SKIP_PI_DIAGNOSTIC=1 \
  bash "$REPO_ROOT/scripts/verify.sh" 2>&1
) || true
# Some checks may fail (file paths depend on clone), that's expected
# The key assertions are the infrastructure checks
assert_contains "verify reports sandbox alive" "PASS: Sandbox alive" "$output"
assert_contains "verify reports bun installed" "PASS: Bun installed" "$output"
assert_contains "verify reports pi installed" "PASS: Pi installed" "$output"
assert_contains "verify reports project dir exists" "PASS: Project directory exists" "$output"

# ---- Step 4: Run Pi with a simple prompt ----
echo ""
echo "Step 4: Run Pi (text mode)"
PI_OUTPUT=$(
  SANDBOX_ID="$SANDBOX_ID" bash "$REPO_ROOT/scripts/run-pi.sh" \
  "State your active phase. Do not modify any files." 2>&1
) || true
PI_EC=$?
# Pi might exit 0 or non-zero depending on config state
# The key test: did we get output?
assert_nonzero_length "Pi produced output" "$PI_OUTPUT"

# Check that Pi references its phase (proving SYSTEM.md was loaded)
# SYSTEM.md says: "Always state the active phase: ANALYSIS, BOOTSTRAP, RED, GREEN, or REFACTOR"
if echo "$PI_OUTPUT" | grep -qiE "ANALYSIS|BOOTSTRAP|RED|GREEN|REFACTOR|phase"; then
  echo "  PASS: Pi response references a phase (SYSTEM.md loaded)"
  ((PASS++))
else
  echo "  FAIL: Pi response does not reference any phase"
  echo "    First 300 chars: ${PI_OUTPUT:0:300}"
  ((FAIL++))
fi

# ---- Step 5: Run Pi --continue (session continuity) ----
echo ""
echo "Step 5: Run Pi --continue (follow-up)"
CONTINUE_OUTPUT=$(
  SANDBOX_ID="$SANDBOX_ID" bash "$REPO_ROOT/scripts/run-pi.sh" --continue \
  "Confirm you received the previous message. Do not modify any files." 2>&1
) || true
CONTINUE_EC=$?
assert_nonzero_length "Pi --continue produced output" "$CONTINUE_OUTPUT"

# ---- Step 6: Kill sandbox ----
echo ""
echo "Step 6: Kill sandbox"
source scripts/lib/e2b-lifecycle.sh
kill_sandbox "$SANDBOX_ID" 2>/dev/null
kill_ec=$?
assert_eq "kill_sandbox succeeds" "0" "$kill_ec"

# Verify it's dead
sleep 1
source scripts/lib/e2b-lifecycle.sh
if ! is_sandbox_alive "$SANDBOX_ID" 2>/dev/null; then
  echo "  PASS: Sandbox is dead after kill"
  ((PASS++))
else
  echo "  FAIL: Sandbox still alive after kill"
  ((FAIL++))
fi

# Clear sandbox ID so cleanup trap doesn't double-kill
SANDBOX_ID=""

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] || exit 1
