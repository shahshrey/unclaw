---
name: heartbeat
description: Proactive check-in with pre-gathered context. Run automatically via launchd every 30 minutes.
disable-model-invocation: true
allowed-tools: Bash Read Write
---

Proactive heartbeat — gather context first, then reason:

1. **Gather context** (deterministic, no reasoning yet):
   ```bash
   bash .claude/scripts/gather-context.sh
   ```

2. **Read the output** and assess:
   - Is the configured channel server alive? If DEAD -> this is **critical**, notify immediately
   - Are there pending/follow-up items with passed or imminent deadlines?
   - Are there uncommitted changes that have been sitting for a long time?
   - Is disk space running low?
   - Are there duplicate claude/tmux processes? (expected: 1 each)
   - Any patterns in today's log that suggest an unfinished thread?

3. **Act** based on what you find:
   - If the channel server is DEAD -> run `bash ./start-agent.sh` to restart (the watchdog also does this, but belt-and-suspenders)
   - If there are urgent pending items -> send a notification and summarize what needs attention
   - If there are stale uncommitted changes -> suggest committing or stashing
   - If nothing needs attention -> do nothing (don't generate output for the sake of it)

4. **Only notify if something is actionable.** Silent heartbeats are good. Don't be noisy.

## Debugging rules
- NEVER call Telegram's `getUpdates` API via curl — this competes with the bun long-poller and breaks message delivery
- Safe to check: `getWebhookInfo` (read-only, no side effects)
- Safe to check: `pgrep -f "bun.*server\.ts"` (process alive?)
- Safe to check: `lsof -i -P | grep bun` (network connections?)
- If the channel is flaky, inspect `.claude/runtime/watchdog.log`, `.claude/runtime/incidents/*.log`, and the latest `.claude/runtime/agent-session-*.log` before restarting anything
