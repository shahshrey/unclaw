#!/bin/bash
# Watchdog: keep the single agent session healthy.
# Detects dead channel pollers and process anomalies.

set -eu

export PATH="$HOME/.bun/bin:$HOME/.local/bin:/opt/homebrew/bin:$PATH"

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
AGENT_ENV_FILE="$PROJECT_DIR/agent.env"
RUNTIME_DIR="$PROJECT_DIR/.claude/runtime"
INCIDENT_DIR="$RUNTIME_DIR/incidents"
TASK_LOG="$PROJECT_DIR/.claude/launchd-task-log.txt"
WATCHDOG_LOG="$RUNTIME_DIR/watchdog.log"

if [ -f "$AGENT_ENV_FILE" ]; then
  # shellcheck disable=SC1090
  . "$AGENT_ENV_FILE"
fi

export AGENT_SESSION_NAME="${AGENT_SESSION_NAME:-agent}"
SESSION_NAME="$AGENT_SESSION_NAME"

mkdir -p "$INCIDENT_DIR"

timestamp() { date '+%Y-%m-%d %H:%M:%S %Z'; }
log() {
  local line="[$(timestamp)] watchdog: $1"
  printf '%s\n' "$line" >> "$WATCHDOG_LOG"
  printf '%s\n' "$line" >> "$TASK_LOG"
}

write_snapshot() {
  local reason="$1"
  local safe_reason snapshot
  safe_reason="$(printf '%s' "$reason" | tr ' /' '__' | tr -cd '[:alnum:]_.-')"
  snapshot="$INCIDENT_DIR/incident-$(date '+%Y%m%d-%H%M%S')-$safe_reason.log"

  {
    echo "# Agent incident snapshot"
    echo "generated: $(timestamp)"
    echo "reason: $reason"
    echo "session: $SESSION_NAME"
    echo
    echo "## Process Table"
    ps -axo pid=,ppid=,state=,etime=,command= | awk '/claude |bun.*server|tmux / && $0 !~ /awk/' || true
    echo
    echo "## Tmux Sessions"
    tmux list-sessions 2>/dev/null || true
    echo
    echo "## Session Pane Tail"
    tmux capture-pane -t "$SESSION_NAME" -p -S -60 2>/dev/null || true
  } > "$snapshot"

  log "wrote incident snapshot: $snapshot"
}

if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  write_snapshot "session-missing"
  log "$SESSION_NAME session missing — starting via start-agent.sh"
  /bin/bash "$PROJECT_DIR/start-agent.sh" >> "$TASK_LOG" 2>&1
  exit 0
fi

BUN_COUNT=$(ps -axo command= | awk '$1 ~ /\/bun$/ && /server.ts$/ {count++} END {print count+0}')
CLAUDE_COUNT=$(ps -axo command= | awk '$1 == "claude" && /--dangerously-skip-permissions/ {count++} END {print count+0}')

if [ "$BUN_COUNT" -ge 1 ] && [ "$CLAUDE_COUNT" -eq 1 ]; then
  exit 0
fi

write_snapshot "runtime-anomaly-bun${BUN_COUNT}-claude${CLAUDE_COUNT}"
log "anomaly detected (bun=$BUN_COUNT claude=$CLAUDE_COUNT) — restarting"
pkill -f "bun.*server\.ts" 2>/dev/null || true
tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true
sleep 2
/bin/bash "$PROJECT_DIR/start-agent.sh" >> "$TASK_LOG" 2>&1
log "session restarted"
