#!/usr/bin/env bash
# pi-text-output.test.sh — Tests for parse_pi_text_response() and extract_status_block()
# Deterministic tests using fixtures, no live Pi calls.
#
# Source: badlogic/pi-mono packages/coding-agent/src/modes/print-mode.ts
#   - Lines ~147-151: text mode outputs content.type === "text" blocks
#   - Lines ~143-145: stopReason "error" or "aborted" → stderr + exit 1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source library (sets -euo pipefail internally), then relax for test control
source "$REPO_ROOT/scripts/lib/pi-parse.sh"
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

echo "=== pi-text-output.test.sh ==="

# ---- parse_pi_text_response tests ----

# Test: successful response (exit 0) echoes stdout
result=$(parse_pi_text_response "Hello from Pi" "" "0" 2>/dev/null)
ec=$?
assert_eq "success response echoes stdout" "Hello from Pi" "$result"
assert_eq "success response returns 0" "0" "$ec"

# Test: Pi error (exit 1) returns 1 and echoes stderr
result=$(parse_pi_text_response "" "Request error" "1" 2>/dev/null)
ec=$?
assert_eq "error response returns 1" "1" "$ec"

# Test: stderr goes to stderr on error
stderr_output=$(parse_pi_text_response "" "Request aborted" "1" 2>&1 1>/dev/null)
assert_contains "error stderr is forwarded" "Request aborted" "$stderr_output"

# Test: exit code > 1 is infrastructure error
result=$(parse_pi_text_response "" "Connection failed" "2" 2>/dev/null)
ec=$?
assert_eq "infra error returns 1" "1" "$ec"

# Test: empty stdout + exit 0 is valid (empty response)
result=$(parse_pi_text_response "" "" "0" 2>/dev/null)
ec=$?
assert_eq "empty stdout with exit 0 is valid" "0" "$ec"

# Test: multiline stdout preserved
multiline_output=$'Line 1\nLine 2\nLine 3'
result=$(parse_pi_text_response "$multiline_output" "" "0" 2>/dev/null)
assert_eq "multiline output preserved" "$multiline_output" "$result"

# Test: error with no stderr gives fallback message
stderr_output=$(parse_pi_text_response "" "" "1" 2>&1 1>/dev/null)
assert_contains "error with no stderr gives fallback" "Pi exited with code 1" "$stderr_output"

# ---- extract_status_block tests ----

# Test: extracts valid status block
FIXTURE_WITH_STATUS='Some Pi output text here.

More explanation of what was done.

```json:status
{
  "phase": "GREEN",
  "gates_passing": ["format", "lint", "typecheck", "test"],
  "gates_failing": [],
  "files_changed": ["src/foo.ts"],
  "git_commit": "abc1234",
  "git_pushed": false,
  "next_step": "Refactor the implementation"
}
```'

result=$(extract_status_block "$FIXTURE_WITH_STATUS")
assert_contains "extracts phase from status block" '"phase": "GREEN"' "$result"
assert_contains "extracts git_commit from status block" '"git_commit": "abc1234"' "$result"

# Test: returns empty when no status block present
result=$(extract_status_block "Just some plain text output from Pi")
assert_eq "returns empty for no status block" "" "$result"

# Test: returns empty for empty input
result=$(extract_status_block "")
assert_eq "returns empty for empty input" "" "$result"

# Test: handles malformed JSON gracefully (returns empty, not crash)
FIXTURE_MALFORMED='Some text
```json:status
{not valid json
```'

result=$(extract_status_block "$FIXTURE_MALFORMED")
assert_eq "returns empty for malformed JSON" "" "$result"

# Test: status block with all required fields is valid JSON
FIXTURE_FULL_STATUS='```json:status
{
  "phase": "RED",
  "gates_passing": [],
  "gates_failing": ["test"],
  "files_changed": ["test/foo.test.ts"],
  "git_commit": null,
  "git_pushed": false,
  "next_step": "Write implementation to make test pass"
}
```'

result=$(extract_status_block "$FIXTURE_FULL_STATUS")
# Verify it's valid JSON by piping through jq
phase=$(echo "$result" | jq -r '.phase' 2>/dev/null)
assert_eq "parsed phase field is RED" "RED" "$phase"

git_pushed=$(echo "$result" | jq -r '.git_pushed' 2>/dev/null)
assert_eq "parsed git_pushed is false" "false" "$git_pushed"

next_step=$(echo "$result" | jq -r '.next_step' 2>/dev/null)
assert_eq "parsed next_step field" "Write implementation to make test pass" "$next_step"

# ---- get_status_field tests ----

# Test: extracts individual field
STATUS_JSON='{"phase":"REFACTOR","gates_passing":["format"],"git_commit":"def5678"}'
result=$(get_status_field "$STATUS_JSON" "phase")
assert_eq "get_status_field extracts phase" "REFACTOR" "$result"

result=$(get_status_field "$STATUS_JSON" "git_commit")
assert_eq "get_status_field extracts git_commit" "def5678" "$result"

# Test: returns empty for missing field
result=$(get_status_field "$STATUS_JSON" "nonexistent")
assert_eq "get_status_field returns empty for missing field" "" "$result"

# Test: handles empty JSON
result=$(get_status_field "" "phase")
assert_eq "get_status_field handles empty JSON" "" "$result"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] || exit 1
