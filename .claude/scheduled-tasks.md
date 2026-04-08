# Persistent Scheduled Tasks

Persistent recurring tasks are managed by `launchd` (macOS) or the OS scheduler.
The scheduler sends commands into the single agent tmux session so schedules survive reboots.

## Recurring

- `/heartbeat` every 30 minutes
- `/distill-session` every 6 hours
- `/promote` every 24 hours
- `/self-improve` nightly at 2 AM — reviews and improves skills, rules, identity, hooks based on recent usage
- **watchdog** every 5 minutes — checks channel server health, restarts agent if needed

## Temporary reminders

Use `/loop` only for temporary, session-scoped reminders that do not need to survive restarts.

## Logs

- Runtime session transcripts: `.claude/runtime/agent-session-*.log`
- Startup events: `.claude/runtime/start-agent.log`
- Watchdog events: `.claude/runtime/watchdog.log`
- Incident snapshots: `.claude/runtime/incidents/*.log`
- launchd stdout/stderr: `.claude/runtime/launchd/*.log`
