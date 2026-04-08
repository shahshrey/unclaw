#!/bin/bash
# Start the agent in a tmux session with an optional messaging channel.
# Uses a startup lock so concurrent starts can't race.
# Usage: ./start-agent.sh

set -eu

export PATH="$HOME/.bun/bin:$HOME/.local/bin:/opt/homebrew/bin:$PATH"

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENT_ENV_FILE="$PROJECT_DIR/agent.env"
RUNTIME_DIR="$PROJECT_DIR/.claude/runtime"
EVENT_LOG="$RUNTIME_DIR/start-agent.log"
LOCK_DIR="$RUNTIME_DIR/start-agent.lock"

if [ -f "$AGENT_ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  . "$AGENT_ENV_FILE"
  set +a
fi

export AGENT_SESSION_NAME="${AGENT_SESSION_NAME:-agent}"
export AGENT_CHANNEL="${AGENT_CHANNEL:-}"
SESSION_NAME="$AGENT_SESSION_NAME"
CHANNEL="$AGENT_CHANNEL"

mkdir -p "$RUNTIME_DIR"

timestamp() { date '+%Y-%m-%d %H:%M:%S %Z'; }
log() { printf '[%s] start-agent: %s\n' "$(timestamp)" "$1" >> "$EVENT_LOG"; }

acquire_lock() {
  local attempts=0
  while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    attempts=$((attempts + 1))
    if [ "$attempts" -ge 30 ]; then
      log "startup lock busy for 30s; aborting"
      echo "Agent startup already in progress."
      exit 1
    fi
    sleep 1
  done
}

release_lock() { rmdir "$LOCK_DIR" 2>/dev/null || true; }
trap release_lock EXIT INT TERM
acquire_lock

log "startup requested session=$SESSION_NAME channel=$CHANNEL"

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  log "session already exists; no-op"
  echo "Agent is already running. Attach with: tmux attach -t $SESSION_NAME"
  exit 0
fi

pkill -f "bun.*server\.ts" 2>/dev/null && { log "killed orphaned bun server(s)"; sleep 1; } || true

tmux new-session -d -s "$SESSION_NAME" -c "$PROJECT_DIR" \
  "/bin/bash \"$PROJECT_DIR/.claude/scripts/run-agent-session.sh\""

log "tmux session created"

echo "Agent started in tmux session '$SESSION_NAME' (cwd: $PROJECT_DIR)"
echo "  Attach:  tmux attach -t $SESSION_NAME"
echo "  Detach:  Ctrl+B, then D"
echo "  Stop:    tmux kill-session -t $SESSION_NAME"
