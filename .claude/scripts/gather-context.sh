#!/bin/bash
# Deterministic context gathering for the heartbeat.
# Runs BEFORE Claude reasons — no LLM calls here.

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
NOW="$(date '+%Y-%m-%d %H:%M %Z')"
TODAY="$(date '+%Y-%m-%d')"

echo "# Heartbeat Context Snapshot"
echo "Generated: $NOW"
echo ""

echo "## Pending Items from identity/memory.md"
if [ -f "$PROJECT_DIR/identity/memory.md" ]; then
  grep -i -E "follow.?up|pending|todo|deadline|reminder|urgent" "$PROJECT_DIR/identity/memory.md" 2>/dev/null || echo "No pending items found."
else
  echo "No identity/memory.md found."
fi
echo ""

echo "## Today's Daily Log ($TODAY)"
DAILY_LOG="$PROJECT_DIR/daily-logs/$TODAY.md"
if [ -f "$DAILY_LOG" ]; then
  wc -l < "$DAILY_LOG" | xargs printf "%s lines logged today\n"
  echo "Last 10 lines:"
  tail -10 "$DAILY_LOG"
else
  echo "No log for today yet."
fi
echo ""

echo "## Scheduled Tasks"
if [ -f "$PROJECT_DIR/.claude/scheduled-tasks.md" ]; then
  grep "^- " "$PROJECT_DIR/.claude/scheduled-tasks.md" 2>/dev/null || echo "No tasks defined."
else
  echo "No scheduled-tasks.md found."
fi
echo ""

echo "## Git Status"
cd "$PROJECT_DIR"
if git rev-parse --git-dir > /dev/null 2>&1; then
  BRANCH=$(git branch --show-current 2>/dev/null)
  UNCOMMITTED=$(git status --porcelain 2>/dev/null | wc -l | xargs)
  LAST_COMMIT=$(git log -1 --format='%h %s (%cr)' 2>/dev/null)
  echo "Branch: $BRANCH"
  echo "Uncommitted changes: $UNCOMMITTED files"
  echo "Last commit: $LAST_COMMIT"
else
  echo "Not a git repository."
fi
echo ""

echo "## Channel Health"
if pgrep -f "bun.*server\.ts" > /dev/null 2>&1; then
  BUN_PID=$(pgrep -f "bun.*server\.ts")
  echo "bun channel server: RUNNING (pid $BUN_PID)"
else
  echo "bun channel server: NOT RUNNING (may not be configured)"
fi
CLAUDE_COUNT=$(pgrep -fc "claude.*--dangerously-skip-permissions" 2>/dev/null || echo 0)
echo "claude agent processes: $CLAUDE_COUNT (expected: 1)"
echo ""

echo "## System"
echo "Uptime: $(uptime | sed 's/.*up /up /' | sed 's/,.*//')"
echo "Disk: $(df -h / | tail -1 | awk '{print $4 " free of " $2}')"
echo ""

echo "## Recent File Changes (last 2 hours)"
find "$PROJECT_DIR" -not -path '*/.firecrawl/*' -not -path '*/.git/*' -not -path '*/.claude/memory.db*' -not -path '*/.claude/runtime/*' -type f -mmin -120 -exec ls -lt {} + 2>/dev/null | head -10 || echo "No recent changes."
echo ""
