#!/usr/bin/env bash
# bootstrap.test.sh — Tests for scripts/bootstrap.sh
# Deterministic tests for argument/env validation + integration tests (gated).

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

echo "=== bootstrap.test.sh ==="

# ---- Deterministic: env var validation ----

# Test: fails without E2B_API_KEY
output=$(E2B_API_KEY="" APP_INSTALLATION_TOKEN="x" PI_AUTH_JSON="{}" \
  bash "$REPO_ROOT/scripts/bootstrap.sh" "template" "https://github.com/test/repo" 2>&1)
ec=$?
assert_eq "fails without E2B_API_KEY" "1" "$ec"
assert_contains "error mentions E2B_API_KEY" "E2B_API_KEY" "$output"

# Test: fails without APP_INSTALLATION_TOKEN
output=$(E2B_API_KEY="test" APP_INSTALLATION_TOKEN="" PI_AUTH_JSON="{}" \
  bash "$REPO_ROOT/scripts/bootstrap.sh" "template" "https://github.com/test/repo" 2>&1)
ec=$?
assert_eq "fails without APP_INSTALLATION_TOKEN" "1" "$ec"
assert_contains "error mentions APP_INSTALLATION_TOKEN" "APP_INSTALLATION_TOKEN" "$output"

# Test: fails without PI_AUTH_JSON
output=$(E2B_API_KEY="test" APP_INSTALLATION_TOKEN="x" PI_AUTH_JSON="" \
  bash "$REPO_ROOT/scripts/bootstrap.sh" "template" "https://github.com/test/repo" 2>&1)
ec=$?
assert_eq "fails without PI_AUTH_JSON" "1" "$ec"
assert_contains "error mentions PI_AUTH_JSON" "PI_AUTH_JSON" "$output"

# Test: fails without positional args
output=$(E2B_API_KEY="test" APP_INSTALLATION_TOKEN="x" PI_AUTH_JSON="{}" \
  bash "$REPO_ROOT/scripts/bootstrap.sh" 2>&1)
ec=$?
assert_eq "fails without positional args" "1" "$ec"

# Test: fails with only template (no repo URL)
output=$(E2B_API_KEY="test" APP_INSTALLATION_TOKEN="x" PI_AUTH_JSON="{}" \
  bash "$REPO_ROOT/scripts/bootstrap.sh" "template" 2>&1)
ec=$?
assert_eq "fails without repo URL" "1" "$ec"

# Test: script sources Phase 1 libraries
assert_contains "sources e2b-parse.sh" "e2b-parse.sh" "$(cat "$REPO_ROOT/scripts/bootstrap.sh")"
assert_contains "sources e2b-exec.sh" "e2b-exec.sh" "$(cat "$REPO_ROOT/scripts/bootstrap.sh")"
assert_contains "sources e2b-lifecycle.sh" "e2b-lifecycle.sh" "$(cat "$REPO_ROOT/scripts/bootstrap.sh")"

# Test: script uses parse_sandbox_id (not raw grep)
assert_contains "uses parse_sandbox_id" "parse_sandbox_id" "$(cat "$REPO_ROOT/scripts/bootstrap.sh")"

# Test: script uses exec_and_capture (not raw e2b sandbox exec)
assert_contains "uses exec_and_capture" "exec_and_capture" "$(cat "$REPO_ROOT/scripts/bootstrap.sh")"

# Test: script uses is_sandbox_alive
assert_contains "uses is_sandbox_alive" "is_sandbox_alive" "$(cat "$REPO_ROOT/scripts/bootstrap.sh")"

# Test: script saves sandbox ID to .sandbox-id
assert_contains "saves to .sandbox-id" ".sandbox-id" "$(cat "$REPO_ROOT/scripts/bootstrap.sh")"

# Test: script sets NO_COLOR=1
assert_contains "sets NO_COLOR=1" "NO_COLOR=1" "$(cat "$REPO_ROOT/scripts/bootstrap.sh")"

# Test: script does NOT run Pi (no pi -p)
script_content=$(cat "$REPO_ROOT/scripts/bootstrap.sh")
if [[ "$script_content" != *"pi -p"* ]]; then
  echo "  PASS: bootstrap does NOT run Pi"
  ((PASS++))
else
  echo "  FAIL: bootstrap should NOT run Pi"
  ((FAIL++))
fi

# Test: bootstrap clones repo (infrastructure setup — not codebase operation)
# Computer clones the repo for Pi as part of sandbox setup. This is infrastructure,
# not codebase operation. Pi is sole operator once bootstrap completes.
assert_contains "bootstrap clones repo into sandbox" "git clone" "$script_content"

# Test: bootstrap installs dependencies (bun install)
# Pi's AGENTS.md contract requires automation gates to pass before any code changes.
# Without installed dev dependencies (biome, typescript), Pi refuses to operate.
assert_contains "bootstrap installs project dependencies" "bun install" "$script_content"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] || exit 1
