#!/bin/bash
# Appends a timestamped entry to today's daily log.
# Called by PreCompact and SessionEnd hooks.
# Reads context from stdin (JSON from Claude Code hook system).

LOGS_DIR="$(cd "$(dirname "$0")/../.." && pwd)/daily-logs"
TODAY="$(date '+%Y-%m-%d')"
LOG_FILE="$LOGS_DIR/$TODAY.md"
TIMESTAMP="$(date '+%H:%M:%S %Z')"

mkdir -p "$LOGS_DIR"

# Read hook context from stdin
CONTEXT=$(cat)

# Extract the event type and any summary from the JSON context
EVENT=$(echo "$CONTEXT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('event','unknown'))" 2>/dev/null || echo "unknown")

# Create header if this is a new daily log
if [ ! -f "$LOG_FILE" ]; then
  echo "# Daily Log — $TODAY" >> "$LOG_FILE"
  echo "" >> "$LOG_FILE"
fi

# Append the entry
echo "## [$TIMESTAMP] $EVENT" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# For PreCompact, ask Claude to summarize what's being compacted
if [ "$EVENT" = "PreCompact" ]; then
  echo "Session context was compacted. Key context should have been saved by the PreCompact prompt hook." >> "$LOG_FILE"
fi

# For SessionEnd, note the session ended
if [ "$EVENT" = "SessionEnd" ]; then
  echo "Session ended." >> "$LOG_FILE"
fi

echo "" >> "$LOG_FILE"
echo "---" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

echo "Saved to $LOG_FILE"
