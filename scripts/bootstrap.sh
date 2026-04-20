#!/usr/bin/env bash
# bootstrap.sh — Create an E2B sandbox, inject auth credentials, verify readiness.
#
# This is an INFRASTRUCTURE script that Computer runs. It does NOT operate on
# the codebase — it creates the sandbox, injects auth, and verifies the sandbox
# is alive. Pi is not running yet when this executes.
#
# Uses Phase 1 libraries: e2b-parse.sh, e2b-exec.sh, e2b-lifecycle.sh
#
# Prerequisites:
#   - E2B CLI installed (bun install -g @e2b/cli)
#   - E2B_API_KEY — E2B platform key
#   - APP_INSTALLATION_TOKEN — GitHub App token (short-lived, ~1hr)
#   - PI_AUTH_JSON — contents of ~/.pi/agent/auth.json (Codex OAuth)
#
# Usage:
#   bash scripts/bootstrap.sh <template-name-or-id> <github-repo-url>
#
# Example:
#   bash scripts/bootstrap.sh pi-bun-sandbox https://github.com/fantasymetals/billion-dollar-build

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/e2b-parse.sh"
source "$SCRIPT_DIR/lib/e2b-exec.sh"
source "$SCRIPT_DIR/lib/e2b-lifecycle.sh"

TEMPLATE="${1:?Usage: bootstrap.sh <template-name-or-id> <github-repo-url>}"
REPO_URL="${2:?Usage: bootstrap.sh <template-name-or-id> <github-repo-url>}"

: "${E2B_API_KEY:?E2B_API_KEY required}"
: "${APP_INSTALLATION_TOKEN:?APP_INSTALLATION_TOKEN required}"
: "${PI_AUTH_JSON:?PI_AUTH_JSON required}"

# Git identity for Pi (configurable via env vars)
PI_GIT_NAME="${PI_GIT_NAME:-pi-codebase-operator[bot]}"
PI_GIT_EMAIL="${PI_GIT_EMAIL:-noreply@users.noreply.github.com}"

export NO_COLOR=1

# 1. Create sandbox (infrastructure — Computer creates the environment)
echo "Creating sandbox from template: $TEMPLATE..."
OUTPUT=$(e2b sandbox create "$TEMPLATE" --detach 2>&1)
SANDBOX_ID=$(parse_sandbox_id "$OUTPUT")
echo "$SANDBOX_ID" > .sandbox-id
echo "Sandbox created: $SANDBOX_ID"

# 2. Inject Pi auth.json (infrastructure — credential setup, not codebase manipulation)
# Pi needs this to authenticate with Codex/OpenAI for model access
echo "Injecting Pi auth..."
exec_and_capture "$SANDBOX_ID" \
  "mkdir -p /home/user/.pi/agent && cat > /home/user/.pi/agent/auth.json << 'AUTHEOF'
${PI_AUTH_JSON}
AUTHEOF" "/home/user" >/dev/null

# 3. Inject App installation token for git operations (infrastructure — not codebase)
# Pi will use this to clone, pull, and push via git credential store
echo "Configuring git credentials..."
exec_and_capture "$SANDBOX_ID" \
  "git config --global credential.helper store" "/home/user" >/dev/null
exec_and_capture "$SANDBOX_ID" \
  "echo 'https://x-access-token:${APP_INSTALLATION_TOKEN}@github.com' > ~/.git-credentials" \
  "/home/user" >/dev/null

# 4. Configure git identity (so Pi's commits are attributed correctly)
exec_and_capture "$SANDBOX_ID" \
  "git config --global user.name '$PI_GIT_NAME' && git config --global user.email '$PI_GIT_EMAIL'" \
  "/home/user" >/dev/null

# 5. Clone repo into sandbox (infrastructure — Pi's project directory)
echo "Cloning repo..."
exec_and_capture "$SANDBOX_ID" \
  "git clone https://x-access-token:${APP_INSTALLATION_TOKEN}@github.com/${REPO_URL#*github.com/} /home/user/project" \
  "/home/user" >/dev/null 2>&1

# 6. Install project dependencies (biome, typescript, etc.)
# Pi's AGENTS.md contract requires all automation gates (format, lint, typecheck, test)
# to pass before any code changes. Without this step, Pi will refuse to operate.
echo "Installing project dependencies..."
exec_and_capture "$SANDBOX_ID" "cd /home/user/project && bun install" "/home/user/project" >/dev/null 2>&1

# 7. Verify sandbox is alive (infrastructure check)
is_sandbox_alive "$SANDBOX_ID" || { echo "ERROR: Sandbox not running after setup" >&2; exit 1; }

echo ""
echo "Bootstrap complete. Sandbox $SANDBOX_ID ready."
echo "  Template: $TEMPLATE"
echo "  Repo: $REPO_URL"
echo "  Git identity: $PI_GIT_NAME <$PI_GIT_EMAIL>"
echo "  Sandbox ID saved to .sandbox-id"
echo ""
echo "Next: run verify.sh to confirm Pi loaded SYSTEM.md and AGENTS.md."
echo "Then: run-pi.sh to send Pi prompts. Pi is the sole operator from here."
