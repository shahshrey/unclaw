---
name: self-improve
description: Recursive self-improvement loop. Reviews and improves the agent's own skills, rules, identity files, hooks, and scripts based on recent usage patterns. Runs nightly via launchd or manually with /self-improve.
---

# Recursive Self-Improvement

Review the agent's own operational infrastructure and make improvements based on evidence from recent usage.

## Signal Gathering

Collect evidence before changing anything:

1. **Daily logs** (last 7 days) — look for:
   - Tasks that took multiple attempts or unusually long
   - Patterns the agent struggled with repeatedly
   - Gaps where no skill existed for a common task
   - Workflows that felt clunky or required workarounds

2. **User overrides** — look for:
   - Places the user corrected the agent's approach
   - Redirections ("no, do it this way instead")
   - Explicit feedback on what worked or didn't
   - Preferences the agent missed or forgot

3. **Runtime logs** — check `.claude/runtime/` for:
   - Hook failures or errors in `launchd/*.log`
   - Watchdog incidents in `incidents/*.log`
   - Stale paths or broken references in scripts

## Improvement Scope

Review and improve these in order:

### 1. Skills (`.claude/skills/*/SKILL.md`)
- **Clarity** — are instructions unambiguous? Would a fresh session follow them correctly?
- **Completeness** — do they cover edge cases that came up in logs?
- **Gaps** — should a new skill exist for a recurring pattern?
- **Redundancy** — do any skills overlap and cause confusion?

### 2. Rules (`.claude/rules/*.md`)
- **Relevance** — are all rules still applicable to how the agent is actually used?
- **Contradictions** — do any rules conflict with each other or with skills?
- **Missing rules** — did the logs reveal patterns that should be codified?
- **Specificity** — are rules concrete enough to act on, or vague platitudes?

### 3. Identity files (`CLAUDE.md`, `SOUL.md`)
- **Alignment** — does the described role match how the agent is actually used?
- **Completeness** — are there capabilities or constraints missing from the description?
- **Imports** — are all `@` references valid and loading correctly?

### 4. Hooks & scripts (`.claude/settings.json`, `.claude/scripts/*.sh`)
- **Health** — do all hooks reference scripts that exist and are executable?
- **Error handling** — do scripts fail silently or report errors?
- **Stale paths** — are there hardcoded paths that may have moved?

## Execution Rules

- **Auto-apply all changes.** The morning standup will surface what changed.
- **One change per concern.** Don't combine unrelated improvements into one edit.
- **Document every change.** Append a summary to `daily-logs/YYYY-MM-DD.md` under `## [HH:MM] Self-Improvement` with what was changed and why.
- **Preserve intent.** Improve clarity and coverage, don't change the agent's personality or role.
- **Be conservative.** If unsure whether a change is an improvement, skip it. False positives erode trust.
- **Never delete skills or rules.** Only add, refine, or consolidate. Flag candidates for removal in the daily log for the user to decide.
- **Test hooks after changing them.** If you modify `.claude/settings.json` or a script, verify the hook still fires correctly.

## Output

After completing the loop, append to the daily log:

```
## [HH:MM] Self-Improvement

### Changes made
- [file]: [what changed] — [why, citing evidence from logs]

### Skipped (needs human input)
- [observation]: [why it wasn't auto-fixed]

### Health check
- Skills: X reviewed, Y improved
- Rules: X reviewed, Y improved
- Hooks: all passing / [issues found]
```
