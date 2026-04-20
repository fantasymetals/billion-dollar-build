#!/usr/bin/env bash
# run-pi.sh — Send a prompt to Pi inside an E2B sandbox.
#
# This is the PROMPT DELIVERY script. Computer uses it to send a prompt to Pi
# and receive Pi's output. It does NOT touch the codebase — Pi does, in
# response to the prompt.
#
# Uses Phase 1+2 libraries: pi-invoke.sh, e2b-exec.sh, e2b-lifecycle.sh
#
# Usage:
#   bash scripts/run-pi.sh "Your prompt here"
#   bash scripts/run-pi.sh --continue "Follow-up prompt"
#   bash scripts/run-pi.sh --json "Prompt for structured output"
#
# Environment variables:
#   SANDBOX_ID   — Override sandbox ID (default: read from .sandbox-id)
#   PI_PROVIDER  — Model provider (default: openai-codex)
#   PI_MODEL     — Model name (default: gpt-5.4)
#   PROJECT_DIR  — Working directory inside sandbox (default: /home/user/project)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/pi-invoke.sh"
source "$SCRIPT_DIR/lib/pi-parse.sh"
source "$SCRIPT_DIR/lib/e2b-exec.sh"
source "$SCRIPT_DIR/lib/e2b-lifecycle.sh"

CONTINUE_FLAG=""
JSON_MODE=""
STATUS_ONLY=""
PROMPT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --continue|-c) CONTINUE_FLAG="--continue"; shift ;;
    --json|-j) JSON_MODE="--mode json"; shift ;;
    --status-only|-s) STATUS_ONLY=1; shift ;;
    *) PROMPT="$1"; shift ;;
  esac
done

[[ -z "$PROMPT" ]] && { echo "Usage: run-pi.sh [--continue] [--json] [--status-only] 'prompt'" >&2; exit 1; }

SANDBOX_ID="${SANDBOX_ID:-$(cat .sandbox-id 2>/dev/null || true)}"
[[ -z "$SANDBOX_ID" ]] && { echo "ERROR: No sandbox ID. Run bootstrap.sh first or set SANDBOX_ID." >&2; exit 1; }

export NO_COLOR=1

# Check sandbox is alive before executing
is_sandbox_alive "$SANDBOX_ID" || { echo "ERROR: Sandbox $SANDBOX_ID is not running" >&2; exit 1; }

# Build Pi command using Phase 2 library
# Pass prompt and flags as separate arguments to preserve quoting
BUILD_ARGS=("$PROMPT")
[[ -n "$CONTINUE_FLAG" ]] && BUILD_ARGS+=("$CONTINUE_FLAG")
[[ -n "$JSON_MODE" ]] && BUILD_ARGS+=("$JSON_MODE")

PI_CMD=$(build_pi_command "${BUILD_ARGS[@]}")
PROJECT_DIR="${PROJECT_DIR:-/home/user/project}"

# -c sets Pi's cwd to project root — critical for .pi/SYSTEM.md and AGENTS.md discovery
# Source: resource-loader.ts line 843 — checks join(this.cwd, CONFIG_DIR_NAME, "SYSTEM.md")
# Pi is the sole operator from this point forward
if [[ -n "$STATUS_ONLY" ]]; then
  # Capture stdout, extract and validate status block only
  PI_OUTPUT=$(exec_and_capture "$SANDBOX_ID" "$PI_CMD" "$PROJECT_DIR" 2>/dev/null)
  PI_EC=$?
  if [[ $PI_EC -ne 0 ]]; then
    echo "ERROR: Pi exited with code $PI_EC" >&2
    exit $PI_EC
  fi
  STATUS_JSON=$(extract_status_block "$PI_OUTPUT")
  if [[ -z "$STATUS_JSON" ]]; then
    echo "ERROR: No status block found in Pi output" >&2
    exit 1
  fi
  if ! validate_status_block "$STATUS_JSON" 2>/dev/null; then
    echo "ERROR: Status block validation failed" >&2
    validate_status_block "$STATUS_JSON"  # Print errors to stderr
    exit 1
  fi
  echo "$STATUS_JSON"
else
  exec_and_capture "$SANDBOX_ID" "$PI_CMD" "$PROJECT_DIR"
fi
