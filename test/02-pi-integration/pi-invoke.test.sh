#!/usr/bin/env bash
# pi-invoke.test.sh — Tests for build_pi_command()
# Deterministic tests, no live E2B or Pi calls.
#
# Source: badlogic/pi-mono packages/coding-agent/src/cli/args.ts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source library (sets -euo pipefail internally), then relax for test control
source "$REPO_ROOT/scripts/lib/pi-invoke.sh"
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

echo "=== pi-invoke.test.sh ==="

# Test: basic command with defaults
result=$(build_pi_command "Hello world")
assert_eq "basic command uses -p flag" \
  "pi -p --provider openai-codex --model gpt-5.4 'Hello world'" "$result"

# Test: --continue flag added for follow-up
result=$(build_pi_command "Follow-up prompt" --continue)
assert_contains "adds --continue for follow-up" "--continue" "$result"
assert_contains "prompt still present with --continue" "Follow-up prompt" "$result"

# Test: --continue is NOT present on first invocation
result=$(build_pi_command "First prompt")
assert_not_contains "--continue absent on first invocation" "--continue" "$result"

# Test: provider defaults to openai-codex
result=$(build_pi_command "Test prompt")
assert_contains "provider defaults to openai-codex" "--provider openai-codex" "$result"

# Test: model defaults to gpt-5.4
result=$(build_pi_command "Test prompt")
assert_contains "model defaults to gpt-5.4" "--model gpt-5.4" "$result"

# Test: custom provider via env var
result=$(PI_PROVIDER=anthropic build_pi_command "Test prompt")
assert_contains "custom provider via PI_PROVIDER" "--provider anthropic" "$result"

# Test: custom model via env var
result=$(PI_MODEL=claude-4-sonnet build_pi_command "Test prompt")
assert_contains "custom model via PI_MODEL" "--model claude-4-sonnet" "$result"

# Test: prompt with single quotes is escaped
result=$(build_pi_command "It's a test")
assert_contains "single quotes escaped in prompt" "It'\\''s a test" "$result"

# Test: NEVER includes --no-context-files
# Source: resource-loader.ts line 455 — noContextFiles suppresses loadProjectContextFiles
# Pi must always load .pi/SYSTEM.md and AGENTS.md
result=$(build_pi_command "Test prompt")
assert_not_contains "never includes --no-context-files" "--no-context-files" "$result"
assert_not_contains "never includes -nc" " -nc " "$result"

# Test: NEVER includes --no-skills
result=$(build_pi_command "Test prompt")
assert_not_contains "never includes --no-skills" "--no-skills" "$result"
assert_not_contains "never includes -ns" " -ns " "$result"

# Test: always starts with pi -p (print mode)
# Source: args.ts — "--print" / "-p" sets print: true
result=$(build_pi_command "Test prompt")
assert_contains "command starts with pi -p" "pi -p" "$result"

# Test: --mode json when PI_MODE=json
result=$(PI_MODE=json build_pi_command "Test prompt")
assert_contains "json mode adds --mode json" "--mode json" "$result"

# Test: text mode (default) omits --mode flag
# Note: search for "--mode " (with space) to avoid matching "--model"
result=$(PI_MODE=text build_pi_command "Test prompt")
assert_not_contains "text mode omits --mode flag" "--mode " "$result"

# Test: empty prompt fails
assert_fails "fails on empty prompt" build_pi_command ""

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] || exit 1
