#!/usr/bin/env bash
# pi-invoke.sh — Build Pi CLI invocation commands.
#
# Source-verified against badlogic/pi-mono packages/coding-agent/src/cli/args.ts:
#   - "--print" / "-p": sets print mode (non-interactive, single-shot)
#   - "--continue" / "-c": continue previous session
#   - "--provider <name>": LLM provider
#   - "--model <name>": model selection (supports provider/id, fuzzy matching)
#   - "--mode <mode>": output mode — "text" (default), "json", "rpc"
#   - "--no-context-files" / "-nc": suppresses loadProjectContextFiles (line 455)
#     → NEVER pass this — Pi must discover .pi/SYSTEM.md and AGENTS.md
#   - "--no-skills" / "-ns": suppresses skill loading
#     → NEVER pass this — Pi needs its skills
#   - Positional args become messages[]
#   - @file args become fileArgs[]
#
# Usage:
#   source scripts/lib/pi-invoke.sh
#   cmd=$(build_pi_command "Your prompt here")
#   cmd=$(build_pi_command "Follow-up" --continue)

set -euo pipefail

build_pi_command() {
  local prompt=""
  local continue_flag=""
  local mode="${PI_MODE:-text}"
  local provider="${PI_PROVIDER:-openai-codex}"
  local model="${PI_MODEL:-gpt-5.4}"

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --continue|-c) continue_flag="--continue"; shift ;;
      --mode) mode="$2"; shift 2 ;;
      --provider) provider="$2"; shift 2 ;;
      --model) model="$2"; shift 2 ;;
      *) prompt="$1"; shift ;;
    esac
  done

  if [[ -z "$prompt" ]]; then
    echo "ERROR: No prompt provided to build_pi_command" >&2
    return 1
  fi

  # Build command parts array
  local cmd="pi -p"

  # Add --continue if this is a follow-up
  if [[ -n "$continue_flag" ]]; then
    cmd="$cmd --continue"
  fi

  # Mode (only add if non-default)
  if [[ "$mode" != "text" ]]; then
    cmd="$cmd --mode $mode"
  fi

  # Provider and model
  cmd="$cmd --provider $provider --model $model"

  # Escape single quotes in prompt for shell safety
  # Replace ' with '\'' (end quote, escaped quote, start quote)
  local safe_prompt="${prompt//\'/\'\\\'\'}"
  cmd="$cmd '${safe_prompt}'"

  echo "$cmd"
}
