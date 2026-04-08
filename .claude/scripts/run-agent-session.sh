#!/bin/bash
# Run the live Claude session under a PTY logger so runtime/plugin stderr
# is preserved even after restarts.

set -eu

export PATH="$HOME/.bun/bin:$HOME/.local/bin:/opt/homebrew/bin:$PATH"

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
AGENT_ENV_FILE="$PROJECT_DIR/agent.env"
RUNTIME_DIR="$PROJECT_DIR/.claude/runtime"
EVENT_LOG="$RUNTIME_DIR/agent-session-events.log"
SESSION_ID="$(date '+%Y%m%d-%H%M%S')"
TRANSCRIPT_LOG="$RUNTIME_DIR/agent-session-$SESSION_ID.log"

# set -a: auto-export all sourced vars so child processes (MCP servers, etc.)
# inherit them. Critical for TELEGRAM_STATE_DIR and other per-agent config.
if [ -f "$AGENT_ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  . "$AGENT_ENV_FILE"
  set +a
fi

export AGENT_SESSION_NAME="${AGENT_SESSION_NAME:-agent}"
export AGENT_CHANNEL="${AGENT_CHANNEL:-}"
CHANNEL="$AGENT_CHANNEL"

mkdir -p "$RUNTIME_DIR"

timestamp() { date '+%Y-%m-%d %H:%M:%S %Z'; }
log() { printf '[%s] session[%s]: %s\n' "$(timestamp)" "$SESSION_ID" "$1" >> "$EVENT_LOG"; }

CHANNEL_FLAG=""
if [ -n "$CHANNEL" ]; then
  CHANNEL_FLAG="--channels $CHANNEL"
fi

log "starting Claude session transcript=$TRANSCRIPT_LOG channel=$CHANNEL"

/usr/bin/script -q "$TRANSCRIPT_LOG" /bin/bash -lc "cd '$PROJECT_DIR' && exec claude --dangerously-skip-permissions $CHANNEL_FLAG"
EXIT_CODE=$?

log "Claude session exited code=$EXIT_CODE"
exit "$EXIT_CODE"
