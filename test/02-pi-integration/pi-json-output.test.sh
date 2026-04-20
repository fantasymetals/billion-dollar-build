#!/usr/bin/env bash
# pi-json-output.test.sh — Tests for pi-json-parse.ts (JSON/JSONL mode parsing)
# Deterministic tests using fixture data, no live Pi calls.
#
# Source: badlogic/pi-mono packages/coding-agent/src/modes/print-mode.ts
#   - Lines 112-114: JSON mode subscriber writes JSON.stringify(event) + "\n"
#   - Lines 120-123: session header emitted first
#   - agent-session.ts: event types listed in _processAgentEvent

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

set +e

# Ensure bun is available
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
command -v bun >/dev/null 2>&1 || { echo "SKIP: bun not available"; exit 0; }

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

PARSER="$REPO_ROOT/scripts/lib/pi-json-parse.ts"

echo "=== pi-json-output.test.sh ==="

# ---- Fixture: successful Pi session with tool use ----

FIXTURE_SUCCESS=$(cat <<'JSONL'
{"type":"session_header","sessionId":"abc123","sessionPath":"/tmp/session"}
{"type":"agent_start"}
{"type":"turn_start","turnNumber":1}
{"type":"message_start","message":{"role":"user","content":[{"type":"text","text":"Create hello.ts"}]}}
{"type":"message_end","message":{"role":"user"}}
{"type":"message_start","message":{"role":"assistant","content":[]}}
{"type":"tool_execution_start","toolName":"write","toolCallId":"tc_1"}
{"type":"tool_execution_end","toolName":"write","toolCallId":"tc_1","result":"File created","isError":false}
{"type":"tool_execution_start","toolName":"bash","toolCallId":"tc_2"}
{"type":"tool_execution_end","toolName":"bash","toolCallId":"tc_2","result":"Tests pass","isError":false}
{"type":"message_end","message":{"role":"assistant"}}
{"type":"turn_end","turnNumber":1}
{"type":"turn_start","turnNumber":2}
{"type":"message_start","message":{"role":"assistant","content":[{"type":"text","text":"Created hello.ts and verified tests pass."}]}}
{"type":"message_end","message":{"role":"assistant"}}
{"type":"turn_end","turnNumber":2}
{"type":"agent_end","messages":[{"role":"user","content":[{"type":"text","text":"Create hello.ts"}]},{"role":"assistant","content":[{"type":"text","text":"Created hello.ts and verified tests pass."}]}]}
JSONL
)

result=$(echo "$FIXTURE_SUCCESS" | bun "$PARSER" 0 2>/dev/null)

# Test: success flag
success=$(echo "$result" | jq -r '.success')
assert_eq "success is true for exit 0" "true" "$success"

# Test: exit code forwarded
ec=$(echo "$result" | jq -r '.exitCode')
assert_eq "exit code is 0" "0" "$ec"

# Test: response extracted from agent_end
response=$(echo "$result" | jq -r '.response')
assert_eq "response extracted from agent_end" "Created hello.ts and verified tests pass." "$response"

# Test: tools used collected
tool_count=$(echo "$result" | jq '.toolsUsed | length')
assert_eq "2 tools used" "2" "$tool_count"

first_tool=$(echo "$result" | jq -r '.toolsUsed[0].tool')
assert_eq "first tool is write" "write" "$first_tool"

second_tool=$(echo "$result" | jq -r '.toolsUsed[1].tool')
assert_eq "second tool is bash" "bash" "$second_tool"

# Test: no errors
error_count=$(echo "$result" | jq '.errors | length')
assert_eq "no errors in success case" "0" "$error_count"

# Test: total turns counted
turns=$(echo "$result" | jq '.totalTurns')
assert_eq "2 turns counted" "2" "$turns"

# ---- Fixture: Pi error ----

FIXTURE_ERROR=$(cat <<'JSONL'
{"type":"agent_start"}
{"type":"turn_start","turnNumber":1}
{"type":"tool_execution_start","toolName":"bash","toolCallId":"tc_err"}
{"type":"tool_execution_end","toolName":"bash","toolCallId":"tc_err","result":"Command failed","isError":true}
{"type":"turn_end","turnNumber":1}
{"type":"agent_end","messages":[{"role":"assistant","content":[{"type":"text","text":"An error occurred."}]}]}
JSONL
)

result=$(echo "$FIXTURE_ERROR" | bun "$PARSER" 1 2>/dev/null)

success=$(echo "$result" | jq -r '.success')
assert_eq "success is false for exit 1" "false" "$success"

error_count=$(echo "$result" | jq '.errors | length')
assert_eq "1 error captured" "1" "$error_count"

error_tool=$(echo "$result" | jq -r '.errors[0].tool')
assert_eq "error tool is bash" "bash" "$error_tool"

# ---- Fixture: empty output ----

result=$(echo "" | bun "$PARSER" 0 2>/dev/null)

success=$(echo "$result" | jq -r '.success')
assert_eq "empty output: success true for exit 0" "true" "$success"

response=$(echo "$result" | jq -r '.response')
assert_eq "empty output: response is empty" "" "$response"

turns=$(echo "$result" | jq '.totalTurns')
assert_eq "empty output: 0 turns" "0" "$turns"

# ---- Fixture: malformed JSONL lines are skipped ----

FIXTURE_MALFORMED=$(cat <<'JSONL'
{"type":"agent_start"}
NOT VALID JSON
{"type":"turn_end","turnNumber":1}
also garbage {{{
{"type":"agent_end","messages":[{"role":"assistant","content":[{"type":"text","text":"Survived malformed lines."}]}]}
JSONL
)

result=$(echo "$FIXTURE_MALFORMED" | bun "$PARSER" 0 2>/dev/null)

response=$(echo "$result" | jq -r '.response')
assert_eq "malformed lines skipped, response extracted" "Survived malformed lines." "$response"

turns=$(echo "$result" | jq '.totalTurns')
assert_eq "malformed lines: 1 turn counted" "1" "$turns"

# ---- Fixture: response with status block extracts phase ----

FIXTURE_WITH_STATUS=$(cat <<'JSONL'
{"type":"agent_start"}
{"type":"turn_end","turnNumber":1}
{"type":"agent_end","messages":[{"role":"assistant","content":[{"type":"text","text":"Done.\n\n```json:status\n{\"phase\":\"GREEN\",\"gates_passing\":[\"test\"],\"gates_failing\":[],\"files_changed\":[\"src/foo.ts\"],\"git_commit\":\"abc1234\",\"git_pushed\":false,\"next_step\":\"Refactor\"}\n```"}]}]}
JSONL
)

result=$(echo "$FIXTURE_WITH_STATUS" | bun "$PARSER" 0 2>/dev/null)

phase=$(echo "$result" | jq -r '.phase')
assert_eq "phase extracted from status block" "GREEN" "$phase"

# ---- Fixture: session header is handled gracefully ----

FIXTURE_HEADER_FIRST=$(cat <<'JSONL'
{"type":"session_header","sessionId":"xyz","sessionPath":"/sessions/xyz"}
{"type":"agent_start"}
{"type":"agent_end","messages":[{"role":"assistant","content":[{"type":"text","text":"Hello."}]}]}
JSONL
)

result=$(echo "$FIXTURE_HEADER_FIRST" | bun "$PARSER" 0 2>/dev/null)

response=$(echo "$result" | jq -r '.response')
assert_eq "session header handled, response extracted" "Hello." "$response"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] || exit 1
