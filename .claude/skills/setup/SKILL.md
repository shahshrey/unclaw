---
name: setup
description: Bootstrap an UnClaw agent from scratch. Converts a stock Claude Code instance into a persistent personal agent with identity, memory, and scheduling.
---

# Agent Setup

This skill bootstraps the entire agent. Do **not** assume hooks, launchd jobs, or even `.claude/settings.json` already exist.

## Step 0: Install or repair the core scaffold

Before personalizing anything:

1. Ensure these directories exist:
   - `.claude/`
   - `.claude/rules/`
   - `.claude/skills/`
   - `.claude/scripts/`
   - `.claude/runtime/launchd/`
   - `memory/`
   - `daily-logs/`

2. Ensure these critical files exist:
   - `CLAUDE.md`
   - `identity/SOUL.md`
   - `identity/user.md`
   - `identity/memory.md`
   - `config/agent.env`
   - `.claude/settings.json`
   - `.claude/rules/*.md`
   - `.claude/scripts/*.sh`
   - `templates/settings.json`
   - `templates/launchd/*.plist`

3. If `.claude/settings.json` is missing or malformed, recreate it from `templates/settings.json`.

4. Verify these required hooks exist in `.claude/settings.json`:
   - `SessionStart`
   - `Notification`
   - `PreCompact`
   - `PostCompact`
   - `PostToolUse`

   If any are missing, repair `.claude/settings.json` from `templates/settings.json`.

5. Ensure scripts are executable:
   ```bash
   chmod +x bin/start-agent.sh bin/setup.sh .claude/scripts/*.sh
   ```

## Step 1: Gather identity and role

Ask the user for:
- **Agent name** (e.g. "Ray", "Jarvis", "Friday")
- **Owner name** and full name
- **Agent role** — what this agent _is_. Not just "engineer." Could be: software engineer, research assistant, content creator, financial analyst, habit coach, food/nutrition tracker, writing partner, ops/devops specialist, data analyst, product manager, or anything else. Let the user type a custom role. This determines the agent's identity, expertise framing, and domain-specific rules.
- **Domain expertise** — the equivalent of "tech stack" but for any role. Examples:
  - Software engineer → "TypeScript, React, Node.js"
  - Financial analyst → "equity research, DCF modeling, Bloomberg"
  - Content creator → "SEO, WordPress, video editing, social media"
  - Habit coach → "behavioral psychology, habit tracking, accountability"
  - Research assistant → "academic papers, literature review, citation management"
- **Timezone**
- **OS**
- **Editor**
- **Communication style**

## Step 2: Personalize files

Replace placeholders in:
- `CLAUDE.md` — `{{AGENT_NAME}}`, `{{OWNER_NAME}}`, `{{AGENT_ROLE}}`
- `identity/SOUL.md` — `{{AGENT_NAME}}`, `{{OWNER_NAME}}`, `{{AGENT_ROLE}}`
- `identity/user.md` — `{{OWNER_NAME}}`, `{{OWNER_FULL_NAME}}`, `{{TIMEZONE}}`, `{{DOMAIN_EXPERTISE}}`, `{{OS}}`, `{{EDITOR}}`, `{{COMMUNICATION_STYLE}}`
- `config/agent.env` — `AGENT_SESSION_NAME` (lowercase agent name), `AGENT_CHANNEL`
- `.claude/rules/communication.md` — `{{OWNER_NAME}}`

### Generate `.claude/rules/domain.md`

Generate this file based on the chosen **role** and **domain expertise**. It should contain role-appropriate conventions and best practices. Examples:

- **Software engineer** → coding conventions, testing practices, linting rules
- **Content creator** → tone guides, SEO checklist, publishing workflow
- **Financial analyst** → data sourcing rules, model conventions, disclosure practices
- **Research assistant** → citation style, source evaluation criteria, note-taking format
- **Habit coach** → tracking format, check-in cadence, encouragement style
- **Any role** → the file should feel like a senior practitioner wrote their working standards

Keep it concise (under 20 lines). The user can always expand it later.

Use `config/agent.env` as the source of truth for runtime config:
- `AGENT_SESSION_NAME` → lowercase agent name
- `AGENT_CHANNEL` → blank by default, filled if messaging is configured
- `TELEGRAM_STATE_DIR` → per-agent path, set only if Telegram is configured

## Step 3: Messaging channel (optional)

Ask: "Do you want to connect a messaging channel like Telegram?"

If yes, walk through the prerequisites first, then configure the channel.

### Prerequisites

Handle these before configuring the channel. Do each silently and report the result to the user.

#### 1. Claude Code channels

Check `~/.claude/settings.json` for `"DISABLE_TELEMETRY": "1"` in the `env` object.
- If present, remove it. Claude Code uses feature flags for channels, and this setting causes `--channels` to fall back to "Channels are not currently available."
- Also check shell profiles for `DISABLE_TELEMETRY` or `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`. If either is exported there, remove it and restart the terminal.

#### 2. Bun

The Telegram MCP server runs on Bun. Run `bun --version` to check.
- If installed, tell the user which version is present and move on.
- If not found, install it with `curl -fsSL https://bun.sh/install | bash`, then verify with `bun --version`. Tell the user it was installed.

#### 3. Telegram bot token

The user needs to create a bot through BotFather — this is the one step that requires manual action on their phone/desktop. Tell the user:

> Open [@BotFather](https://t.me/BotFather) on Telegram and send `/newbot`.
> It asks for a **name** (display name, anything) and a **username** (must end in `bot`, e.g. `my_assistant_bot`).
> BotFather replies with a token like `123456789:AAHfiqksKZ8...` — copy the whole thing including the number and colon, and paste it here.

Wait for the user to provide the token before proceeding.

#### 4. Telegram plugin

Check if the Telegram plugin is already installed by running `claude plugin list 2>&1 | grep -i telegram` or checking `~/.claude/plugins/installed_plugins.json`.

- If already installed and enabled, tell the user it's present and move on.
- If not installed, tell the user to run these in a Claude Code session:
  ```
  /plugin install telegram@claude-plugins-official
  /reload-plugins
  ```
  If running inside Cursor rather than the Claude Code CLI, add the Telegram MCP server entry to `.cursor/mcp.json` instead (see the plugin's README for the server command and args).

After either path, verify the Telegram plugin appears in the installed list. Tell the user the result. Also verify if the Telegram MCP server appears in the active MCP list.

### Per-agent Telegram isolation

Each agent gets its own Telegram state directory so multiple agents can run
different bots on the same machine without conflict. The Telegram MCP plugin
reads `TELEGRAM_STATE_DIR` from its environment; `config/agent.env` vars are auto-exported
via `set -a` in the session scripts, so child processes (including MCP servers) inherit them.

1. Create the per-agent state directory: `~/.claude/channels/telegram-<agent-name>/`
   (e.g. `telegram-tony`, `telegram-ray` — lowercase agent name)
2. Create `~/.claude/channels/telegram-<agent-name>/.env` with `TELEGRAM_BOT_TOKEN=<token>`
3. Create `~/.claude/channels/telegram-<agent-name>/access.json` with:
   ```json
   {"dmPolicy": "pairing", "allowFrom": [], "groups": {}, "pending": {}}
   ```
4. Write these lines into `config/agent.env`:
   ```
   AGENT_CHANNEL="plugin:telegram@claude-plugins-official"
   TELEGRAM_STATE_DIR="$HOME/.claude/channels/telegram-<agent-name>"
   ```

**Why per-agent dirs?** The Telegram MCP plugin defaults to `~/.claude/channels/telegram/` for
its bot token and access list. If two agents share that path, they fight over the same bot token
(409 Conflict) and share access lists. `TELEGRAM_STATE_DIR` overrides this per-agent.

### Auto-pair the owner's Telegram account

After the agent is started and Telegram is connected:

1. Tell the user: "DM your bot on Telegram now — send any message (e.g. 'hi'). The bot will reply with a pairing code."
2. Ask the user to paste the **pairing code** (a short hex string like `25255d`).
3. Read `~/.claude/channels/telegram-<agent-name>/access.json` to find the pending entry matching that code.
4. Extract the `senderId` from the pending entry.
5. Add the `senderId` to the `allowFrom` array and remove it from `pending`.
6. Write the updated `access.json`.
7. Create the approval notification: `mkdir -p ~/.claude/channels/telegram-<agent-name>/approved`
   then write the `senderId` to `~/.claude/channels/telegram-<agent-name>/approved/<senderId>`.
   The bot polls this directory and sends a "Paired!" confirmation to the user.
8. Tell the user they're paired — the bot will now respond to their DMs.

Do not rely on `/telegram:access pair` for per-agent setups. That command reads
`~/.claude/channels/telegram/access.json` instead of the per-agent directory.
For isolated bots, pair by editing the per-agent `access.json` directly.

If the user doesn't have the code yet or the pending entry hasn't appeared, wait a moment and re-read the file. The bot writes the pending entry when it receives the first DM.

If no, leave `AGENT_CHANNEL=""` and `TELEGRAM_STATE_DIR` commented out in `config/agent.env` — tmux-only mode is valid.

## Step 4: Hooks (required)

Hooks are required for daily logs, compaction safety, and indexing.

1. Ensure `.claude/settings.json` exists
2. Ensure it contains the required hooks listed in Step 0
3. If not, overwrite it from `templates/settings.json`
4. Confirm to the user that hooks are installed/repaired

## Step 5: launchd scheduling (optional, macOS only)

Ask: "Do you want automatic heartbeats, session logging, memory promotion, nightly self-improvement, and watchdog restarts via launchd?"

If yes:
1. Read the chosen session name and project directory
2. Generate plists from `templates/launchd/` by replacing:
   - `{{AGENT_SESSION_NAME}}`
   - `{{PROJECT_DIR}}`
   - `{{AGENT_CHANNEL}}`
3. Write them to `~/Library/LaunchAgents/`
4. Validate them with `plutil -lint`
5. Unload old versions if present, then `launchctl load` the new ones
6. Verify with `launchctl list | grep <session>`
7. If the assistant job exits with `Operation not permitted` or exit code `126`, tell the user to grant Full Disk Access to `/bin/bash` in **System Settings → Privacy & Security → Full Disk Access**. Until then, they should start the agent manually after reboot.

If no, skip — the agent still works, but recurring tasks must be run manually or via `/loop`.

## Step 6: Start the agent

```bash
./bin/start-agent.sh
```

Then verify the tmux session reaches the `❯` prompt. If Claude shows the workspace trust prompt,
accept it and re-check the pane. If it shows "Channels are not currently available," go back to
Step 3 prerequisite 1.

## Step 7: Verify

- Check tmux session exists: `tmux has-session -t <session>`
- Check `.claude/settings.json` exists and includes the required hooks
- Capture the tmux pane and confirm you see:
  - `Listening for channel messages from: plugin:telegram@...` (if Telegram enabled)
  - `❯` prompt (session is ready)
  - No "Channels are not currently available" warning
- If launchd was enabled, verify the jobs are loaded: `launchctl list | grep <session>`

## Step 8: Confirm

Tell the user:
- how to attach: `tmux attach -t <session>`
- which recurring tasks are automatic vs manual
- that hooks are installed and daily logs/memory promotion will work
- if Telegram is set up, confirm the pairing worked and the bot responds
