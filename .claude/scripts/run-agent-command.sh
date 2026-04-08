#!/bin/bash
# Dispatch a command into the single long-lived agent tmux session.
# Used by scheduled jobs so they don't start a second Claude session.

set -eu

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
AGENT_ENV_FILE="$PROJECT_DIR/agent.env"
LOG_FILE="$PROJECT_DIR/.claude/launchd-task-log.txt"
COMMAND="${*:-}"

export PATH="$HOME/.bun/bin:$HOME/.local/bin:/opt/homebrew/bin:$PATH"

if [ -f "$AGENT_ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  . "$AGENT_ENV_FILE"
  set +a
fi

export AGENT_SESSION_NAME="${AGENT_SESSION_NAME:-agent}"
SESSION_NAME="$AGENT_SESSION_NAME"

timestamp() { date '+%Y-%m-%d %H:%M:%S %Z'; }
log() { printf '[%s] %s\n' "$(timestamp)" "$1" >> "$LOG_FILE"; }

if [ -z "$COMMAND" ]; then
  log "No command provided; aborting."
  exit 1
fi

mkdir -p "$PROJECT_DIR/.claude"
log "Requested scheduled command: $COMMAND"

if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  log "$SESSION_NAME session missing; starting via start-agent.sh"
  /bin/bash "$PROJECT_DIR/start-agent.sh" >> "$LOG_FILE" 2>&1 || true
fi

for _ in $(seq 1 30); do
  tmux has-session -t "$SESSION_NAME" 2>/dev/null && break
  sleep 1
done

if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  log "Failed to create $SESSION_NAME session; skipping command: $COMMAND"
  exit 1
fi

for _ in $(seq 1 60); do
  if tmux capture-pane -t "$SESSION_NAME" -p -S -20 2>/dev/null | /usr/bin/grep -q '❯'; then
    tmux send-keys -t "$SESSION_NAME" "$COMMAND" Enter
    log "Dispatched command into $SESSION_NAME session: $COMMAND"
    exit 0
  fi
  sleep 5
done

log "$SESSION_NAME session stayed busy for 5 minutes; skipped command: $COMMAND"
exit 0
