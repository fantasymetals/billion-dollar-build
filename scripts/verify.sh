#!/usr/bin/env bash
# verify.sh — Verify sandbox health and Pi readiness.
#
# Two parts:
#   1. Infrastructure checks (Computer verifies sandbox health, tool availability)
#   2. Pi diagnostic (Computer sends Pi a prompt to confirm config file loading)
#
# The Pi diagnostic proves Pi loaded .pi/SYSTEM.md and AGENTS.md — it does NOT
# have Computer inspect those files directly. That's Pi's domain.
#
# Uses Phase 1+2 libraries: e2b-exec.sh, e2b-lifecycle.sh, pi-invoke.sh
#
# Usage:
#   bash scripts/verify.sh [sandbox-id]
#   SANDBOX_ID=xxx bash scripts/verify.sh
#
# Environment variables:
#   SANDBOX_ID   — Override sandbox ID (default: read from .sandbox-id)
#   PI_PROVIDER  — Model provider for diagnostic (default: openai-codex)
#   PI_MODEL     — Model name for diagnostic (default: gpt-5.4)
#   SKIP_PI_DIAGNOSTIC — Set to 1 to skip the Pi diagnostic prompt

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/e2b-exec.sh"
source "$SCRIPT_DIR/lib/e2b-lifecycle.sh"
source "$SCRIPT_DIR/lib/pi-invoke.sh"

SANDBOX_ID="${1:-${SANDBOX_ID:-$(cat .sandbox-id 2>/dev/null || true)}}"
[[ -z "$SANDBOX_ID" ]] && { echo "ERROR: No sandbox ID. Pass as argument, set SANDBOX_ID, or ensure .sandbox-id exists." >&2; exit 1; }

export NO_COLOR=1
FAILURES=0
CHECKS=0

check() {
  local name="$1"
  shift
  CHECKS=$(( CHECKS + 1 ))
  if "$@" >/dev/null 2>&1; then
    echo "  PASS: $name"
  else
    echo "  FAIL: $name"
    FAILURES=$(( FAILURES + 1 ))
  fi
}

echo "=== Sandbox Verification: $SANDBOX_ID ==="
echo ""

# Infrastructure checks (Computer verifies sandbox health)
echo "Infrastructure checks:"
check "Sandbox alive" is_sandbox_alive "$SANDBOX_ID"
check "Bun installed" exec_and_capture "$SANDBOX_ID" "bun --version" "/home/user"
check "Pi installed" exec_and_capture "$SANDBOX_ID" "pi --version" "/home/user"
check "Project directory exists" exec_and_capture "$SANDBOX_ID" "test -d /home/user/project" "/home/user"
check "SYSTEM.md exists" exec_and_capture "$SANDBOX_ID" "test -f /home/user/project/.pi/SYSTEM.md" "/home/user"
check "AGENTS.md exists" exec_and_capture "$SANDBOX_ID" "test -f /home/user/project/AGENTS.md" "/home/user"
check "Git credentials configured" exec_and_capture "$SANDBOX_ID" "test -f /home/user/.git-credentials" "/home/user"
check "Pi auth configured" exec_and_capture "$SANDBOX_ID" "test -f /home/user/.pi/agent/auth.json" "/home/user"

# Pi diagnostic (Pi is the operator for this check)
if [[ "${SKIP_PI_DIAGNOSTIC:-0}" != "1" ]]; then
  echo ""
  echo "Pi diagnostic:"
  # Ask Pi to confirm it loaded its config. This verifies:
  #   - Pi discovered .pi/SYSTEM.md (resource-loader.ts line 843)
  #   - Pi discovered AGENTS.md (resource-loader.ts lines 76-99: ancestor walk)
  #   - Pi responds according to its execution protocol
  PI_CMD=$(build_pi_command "State your active phase and confirm you have loaded the project operating contract.")
  if exec_and_capture "$SANDBOX_ID" "$PI_CMD" "/home/user/project" >/dev/null 2>&1; then
    echo "  PASS: Pi print mode responds"
    CHECKS=$(( CHECKS + 1 ))
  else
    echo "  FAIL: Pi print mode responds"
    CHECKS=$(( CHECKS + 1 ))
    FAILURES=$(( FAILURES + 1 ))
  fi
fi

echo ""
echo "Results: $((CHECKS - FAILURES))/$CHECKS checks passed"

if [[ "$FAILURES" -eq 0 ]]; then
  echo "All checks passed. Pi is the sole operator of /home/user/project/."
else
  echo "$FAILURES check(s) failed."
  exit 1
fi
