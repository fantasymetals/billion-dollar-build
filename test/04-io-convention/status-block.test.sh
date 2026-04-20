#!/usr/bin/env bash
# status-block.test.sh — Tests for validate_status_block()
# Deterministic tests for status block field validation.
#
# Source: AGENTS.md "Output format for print mode" section
#   Required fields: phase, gates_passing, gates_failing, files_changed,
#                    git_commit, git_pushed, next_step
#   Phase enum: BOOTSTRAP, RED, GREEN, REFACTOR, ANALYSIS

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source library then relax for test control
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

assert_valid() {
  local desc="$1" json="$2"
  if validate_status_block "$json" 2>/dev/null; then
    echo "  PASS: $desc"
    ((PASS++))
  else
    echo "  FAIL: $desc (should be valid)"
    ((FAIL++))
  fi
}

assert_invalid() {
  local desc="$1" json="$2"
  if ! validate_status_block "$json" 2>/dev/null; then
    echo "  PASS: $desc"
    ((PASS++))
  else
    echo "  FAIL: $desc (should be invalid)"
    ((FAIL++))
  fi
}

assert_error_contains() {
  local desc="$1" json="$2" needle="$3"
  local stderr_output
  stderr_output=$(validate_status_block "$json" 2>&1 1>/dev/null)
  if [[ "$stderr_output" == *"$needle"* ]]; then
    echo "  PASS: $desc"
    ((PASS++))
  else
    echo "  FAIL: $desc"
    echo "    expected stderr to contain: $needle"
    echo "    actual stderr: $stderr_output"
    ((FAIL++))
  fi
}

echo "=== status-block.test.sh ==="

# ---- Valid status blocks ----

VALID_GREEN='{"phase":"GREEN","gates_passing":["format","lint","typecheck","test"],"gates_failing":[],"files_changed":["src/foo.ts"],"git_commit":"abc1234","git_pushed":false,"next_step":"Refactor implementation"}'
assert_valid "valid GREEN status block" "$VALID_GREEN"

VALID_RED='{"phase":"RED","gates_passing":["format","lint"],"gates_failing":["test"],"files_changed":["test/foo.test.ts"],"git_commit":null,"git_pushed":false,"next_step":"Write implementation"}'
assert_valid "valid RED status block (git_commit null)" "$VALID_RED"

VALID_BOOTSTRAP='{"phase":"BOOTSTRAP","gates_passing":[],"gates_failing":[],"files_changed":[],"git_commit":null,"git_pushed":false,"next_step":"Create automation foundation"}'
assert_valid "valid BOOTSTRAP status block (empty arrays)" "$VALID_BOOTSTRAP"

VALID_REFACTOR='{"phase":"REFACTOR","gates_passing":["format","lint","typecheck","test"],"gates_failing":[],"files_changed":["src/foo.ts","src/bar.ts"],"git_commit":"def5678","git_pushed":true,"next_step":"Done"}'
assert_valid "valid REFACTOR with git_pushed true" "$VALID_REFACTOR"

VALID_ANALYSIS='{"phase":"ANALYSIS","gates_passing":["format"],"gates_failing":[],"files_changed":[],"git_commit":null,"git_pushed":false,"next_step":"Analyze current scope"}'
assert_valid "valid ANALYSIS phase" "$VALID_ANALYSIS"

# ---- Invalid: missing fields ----

MISSING_PHASE='{"gates_passing":[],"gates_failing":[],"files_changed":[],"git_commit":null,"git_pushed":false,"next_step":"test"}'
assert_invalid "rejects missing phase" "$MISSING_PHASE"
assert_error_contains "error mentions missing phase" "$MISSING_PHASE" "phase"

MISSING_GATES='{"phase":"RED","gates_failing":[],"files_changed":[],"git_commit":null,"git_pushed":false,"next_step":"test"}'
assert_invalid "rejects missing gates_passing" "$MISSING_GATES"
assert_error_contains "error mentions gates_passing" "$MISSING_GATES" "gates_passing"

MISSING_NEXT_STEP='{"phase":"RED","gates_passing":[],"gates_failing":[],"files_changed":[],"git_commit":null,"git_pushed":false}'
assert_invalid "rejects missing next_step" "$MISSING_NEXT_STEP"

# ---- Invalid: wrong types ----

WRONG_PHASE='{"phase":"INVALID_PHASE","gates_passing":[],"gates_failing":[],"files_changed":[],"git_commit":null,"git_pushed":false,"next_step":"test"}'
assert_invalid "rejects invalid phase enum" "$WRONG_PHASE"
assert_error_contains "error mentions invalid phase" "$WRONG_PHASE" "Invalid phase"

GATES_NOT_ARRAY='{"phase":"RED","gates_passing":"format","gates_failing":[],"files_changed":[],"git_commit":null,"git_pushed":false,"next_step":"test"}'
assert_invalid "rejects gates_passing as string" "$GATES_NOT_ARRAY"
assert_error_contains "error mentions gates_passing type" "$GATES_NOT_ARRAY" "gates_passing must be an array"

PUSHED_NOT_BOOL='{"phase":"RED","gates_passing":[],"gates_failing":[],"files_changed":[],"git_commit":null,"git_pushed":"yes","next_step":"test"}'
assert_invalid "rejects git_pushed as string" "$PUSHED_NOT_BOOL"
assert_error_contains "error mentions git_pushed type" "$PUSHED_NOT_BOOL" "git_pushed must be a boolean"

COMMIT_WRONG_TYPE='{"phase":"RED","gates_passing":[],"gates_failing":[],"files_changed":[],"git_commit":123,"git_pushed":false,"next_step":"test"}'
assert_invalid "rejects git_commit as number" "$COMMIT_WRONG_TYPE"
assert_error_contains "error mentions git_commit type" "$COMMIT_WRONG_TYPE" "git_commit must be a string or null"

EMPTY_NEXT_STEP='{"phase":"RED","gates_passing":[],"gates_failing":[],"files_changed":[],"git_commit":null,"git_pushed":false,"next_step":""}'
assert_invalid "rejects empty next_step" "$EMPTY_NEXT_STEP"

# ---- Invalid: not JSON ----

assert_invalid "rejects empty input" ""
assert_invalid "rejects non-JSON" "not json at all"
assert_error_contains "error mentions not valid JSON" "not json at all" "not valid JSON"

# ---- extract + validate pipeline ----

FULL_PI_OUTPUT='Pi completed the task successfully.

```json:status
{"phase":"GREEN","gates_passing":["format","lint","typecheck","test"],"gates_failing":[],"files_changed":["src/foo.ts"],"git_commit":"abc1234","git_pushed":false,"next_step":"Refactor"}
```'

extracted=$(extract_status_block "$FULL_PI_OUTPUT")
assert_valid "extract + validate pipeline works" "$extracted"

phase=$(get_status_field "$extracted" "phase")
assert_eq "pipeline: phase is GREEN" "GREEN" "$phase"

# ---- AGENTS.md convention exists ----

AGENTS_CONTENT=$(cat "$REPO_ROOT/AGENTS.md")
if [[ "$AGENTS_CONTENT" == *"Output format for print mode"* ]]; then
  echo "  PASS: AGENTS.md contains output format convention"
  ((PASS++))
else
  echo "  FAIL: AGENTS.md missing output format convention"
  ((FAIL++))
fi

if [[ "$AGENTS_CONTENT" == *'```json:status'* ]]; then
  echo "  PASS: AGENTS.md contains json:status example"
  ((PASS++))
else
  echo "  FAIL: AGENTS.md missing json:status example"
  ((FAIL++))
fi

if [[ "$AGENTS_CONTENT" == *"BOOTSTRAP"* ]] && [[ "$AGENTS_CONTENT" == *"ANALYSIS"* ]]; then
  echo "  PASS: AGENTS.md lists all phase enum values"
  ((PASS++))
else
  echo "  FAIL: AGENTS.md missing phase enum values"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] || exit 1
