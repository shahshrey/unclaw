#!/bin/bash
# Interactive setup for a Claude Code personal agent.
# Run once after cloning: ./setup.sh

set -eu

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SETTINGS_TEMPLATE="$PROJECT_DIR/templates/settings.json"
SETTINGS_FILE="$PROJECT_DIR/.claude/settings.json"
AGENT_ENV_FILE="$PROJECT_DIR/agent.env"

ensure_scaffold() {
  mkdir -p \
    "$PROJECT_DIR/.claude/rules" \
    "$PROJECT_DIR/.claude/skills" \
    "$PROJECT_DIR/.claude/scripts" \
    "$PROJECT_DIR/.claude/runtime/launchd" \
    "$PROJECT_DIR/memory" \
    "$PROJECT_DIR/daily-logs" \
    "$PROJECT_DIR/templates/launchd"

  if [ ! -f "$SETTINGS_TEMPLATE" ]; then
    echo "Missing template settings file: $SETTINGS_TEMPLATE"
    exit 1
  fi

  if [ ! -f "$SETTINGS_FILE" ]; then
    cp "$SETTINGS_TEMPLATE" "$SETTINGS_FILE"
    echo "Installed .claude/settings.json from template."
    return
  fi

  if ! python3 - "$SETTINGS_FILE" <<'PY'
import json, sys
path = sys.argv[1]
required = {"SessionStart", "Notification", "PreCompact", "SessionEnd", "PostCompact", "PostToolUse"}
with open(path) as f:
    data = json.load(f)
hooks = set((data.get("hooks") or {}).keys())
missing = required - hooks
raise SystemExit(0 if not missing else 1)
PY
  then
    cp "$SETTINGS_TEMPLATE" "$SETTINGS_FILE"
    echo "Repaired .claude/settings.json from template."
  else
    echo "Hooks config verified."
  fi
}

replace_placeholders() {
  python3 - "$PROJECT_DIR" "$1" "$2" "$3" "$4" "$5" "$6" "$7" <<'PY'
from pathlib import Path
import re, sys
project = Path(sys.argv[1])
agent_name, owner_name, owner_full_name, timezone, tech_stack, os_name, editor, comm_style = sys.argv[2:10]
repls = {
    "{{AGENT_NAME}}": agent_name,
    "{{OWNER_NAME}}": owner_name,
    "{{OWNER_FULL_NAME}}": owner_full_name,
    "{{TIMEZONE}}": timezone,
    "{{TECH_STACK}}": tech_stack,
    "{{OS}}": os_name,
    "{{EDITOR}}": editor,
    "{{COMMUNICATION_STYLE}}": comm_style,
}
for rel in ["CLAUDE.md", "SOUL.md", "user.md"]:
    path = project / rel
    if not path.exists():
        continue
    text = path.read_text()
    for old, new in repls.items():
        text = text.replace(old, new)
    path.write_text(text)

env_path = project / "agent.env"
text = env_path.read_text() if env_path.exists() else 'AGENT_SESSION_NAME="agent"\nAGENT_CHANNEL=""\n'
session_name = re.sub(r'[^a-z0-9_-]+', '-', agent_name.lower()).strip('-') or 'agent'
text = re.sub(r'^AGENT_SESSION_NAME=".*"$', f'AGENT_SESSION_NAME="{session_name}"', text, flags=re.M)
if 'AGENT_SESSION_NAME=' not in text:
    text += f'\nAGENT_SESSION_NAME="{session_name}"\n'
if 'AGENT_CHANNEL=' not in text:
    text += '\nAGENT_CHANNEL=""\n'
env_path.write_text(text)
print(session_name)
PY
}

set_agent_channel() {
  python3 - "$AGENT_ENV_FILE" "$1" <<'PY'
from pathlib import Path
import re, sys
path = Path(sys.argv[1])
channel = sys.argv[2]
text = path.read_text() if path.exists() else ''
if 'AGENT_CHANNEL=' in text:
    text = re.sub(r'^AGENT_CHANNEL=".*"$', f'AGENT_CHANNEL="{channel}"', text, flags=re.M)
else:
    if text and not text.endswith('\n'):
        text += '\n'
    text += f'AGENT_CHANNEL="{channel}"\n'
path.write_text(text)
PY
}

generate_launchd() {
  local session_name="$1"
  local channel_val="$2"

  if [ "$(uname -s)" != "Darwin" ]; then
    echo "launchd setup skipped: not running on macOS."
    return
  fi

  mkdir -p "$HOME/Library/LaunchAgents" "$PROJECT_DIR/.claude/runtime/launchd"

  for tmpl in "$PROJECT_DIR/templates/launchd/"*.plist; do
    BASENAME=$(basename "$tmpl")
    DEST_NAME=$(echo "$BASENAME" | sed "s/agent/$session_name/g")
    python3 - "$tmpl" "$HOME/Library/LaunchAgents/$DEST_NAME" "$session_name" "$PROJECT_DIR" "$channel_val" <<'PY'
from pathlib import Path
import sys
src = Path(sys.argv[1])
dst = Path(sys.argv[2])
session_name, project_dir, channel = sys.argv[3:6]
text = src.read_text()
text = text.replace('{{AGENT_SESSION_NAME}}', session_name)
text = text.replace('{{PROJECT_DIR}}', project_dir)
text = text.replace('{{AGENT_CHANNEL}}', channel)
dst.write_text(text)
PY
    launchctl unload "$HOME/Library/LaunchAgents/$DEST_NAME" 2>/dev/null || true
    plutil -lint "$HOME/Library/LaunchAgents/$DEST_NAME" >/dev/null
    launchctl load "$HOME/Library/LaunchAgents/$DEST_NAME"
  done

  echo "launchd jobs installed and loaded."
}

echo "================================"
echo "  Claude Agent Setup"
echo "================================"
echo ""

ensure_scaffold

echo ""
read -p "Agent name (e.g. Ray, Jarvis): " AGENT_NAME
read -p "Your name: " OWNER_NAME
read -p "Your full name: " OWNER_FULL_NAME
read -p "Timezone (e.g. America/Los_Angeles): " TIMEZONE
read -p "Primary tech stack (e.g. TypeScript, Python): " TECH_STACK
read -p "OS (macOS / Linux): " OS_NAME
read -p "Editor (Cursor / VS Code / Neovim): " EDITOR
read -p "Communication style (e.g. Direct, no hand-holding): " COMM_STYLE

echo ""
echo "Personalizing files..."
SESSION_NAME=$(replace_placeholders "$AGENT_NAME" "$OWNER_NAME" "$OWNER_FULL_NAME" "$TIMEZONE" "$TECH_STACK" "$OS_NAME" "$EDITOR" "$COMM_STYLE")
echo "Done."
echo ""

CHANNEL_VAL=""
read -p "Set up Telegram? (y/n): " SETUP_TELEGRAM
if [ "$SETUP_TELEGRAM" = "y" ]; then
  echo ""
  echo "1. Open Telegram and message @BotFather"
  echo "2. Send /newbot or use an existing bot"
  echo "3. Copy the bot token"
  echo ""
  read -p "Paste your Telegram bot token: " BOT_TOKEN

  mkdir -p "$HOME/.claude/channels/telegram"
  echo "TELEGRAM_BOT_TOKEN=$BOT_TOKEN" > "$HOME/.claude/channels/telegram/.env"
  chmod 600 "$HOME/.claude/channels/telegram/.env"
  echo '{"dmPolicy": "pairing", "allowFrom": [], "groups": {}, "pending": {}}' > "$HOME/.claude/channels/telegram/access.json"

  CHANNEL_VAL="plugin:telegram@claude-plugins-official"
  set_agent_channel "$CHANNEL_VAL"

  echo "Telegram configured."
else
  set_agent_channel ""
fi

echo ""
read -p "Set up auto-start and scheduled tasks via launchd? (macOS only, y/n): " SETUP_LAUNCHD
if [ "$SETUP_LAUNCHD" = "y" ]; then
  generate_launchd "$SESSION_NAME" "$CHANNEL_VAL"
fi

chmod +x "$PROJECT_DIR/setup.sh" "$PROJECT_DIR/start-agent.sh" "$PROJECT_DIR/.claude/scripts/"*.sh 2>/dev/null || true

echo ""
echo "================================"
echo "  Setup complete!"
echo "================================"
echo ""
echo "Hooks installed: $SETTINGS_FILE"
echo "Runtime config:  $AGENT_ENV_FILE"
echo "Start your agent:"
echo "  ./start-agent.sh"
echo ""
echo "Attach to the session:"
echo "  tmux attach -t $SESSION_NAME"
echo ""
if [ "$SETUP_TELEGRAM" = "y" ]; then
  echo "First Telegram message: send anything to your bot."
  echo "You'll get a pairing code — run /telegram:access pair <code>"
  echo "inside the Claude session to complete pairing."
  echo ""
fi
