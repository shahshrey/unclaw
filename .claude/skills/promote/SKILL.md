---
name: promote
description: Extract key learnings from daily logs and promote them to identity/memory.md. Run automatically via launchd once per day, or manually after a productive day.
---

Daily log promotion — extract signal from raw conversation logs into long-term memory.

## Hot/Cold Memory Architecture

- **Hot:** `identity/memory.md` — always in context, kept under 2500 tokens. Only the essentials.
- **Cold:** `memory/*.md` — topic files searched on-demand. Detailed context lives here.
  - `memory/projects.md` — project details, architecture, status
  - `memory/preferences.md` — recurring patterns, style choices
  - `memory/decisions.md` — key decisions with reasoning
  - `memory/people.md` — people context
  - `memory/archive-YYYY-MM.md` — older entries rotated out of hot memory

## Steps

1. Read the last 3 days of `daily-logs/` files
2. Read current `identity/memory.md` (hot) and relevant `memory/*.md` files (cold)
3. Extract and route:
   - **Key decisions** (with rationale) → `identity/memory.md` Current State + `memory/decisions.md`
   - **Lessons learned** → `memory/decisions.md`
   - **New preferences** → `memory/preferences.md`
   - **Project context** → `memory/projects.md`
   - **People context** → `memory/people.md`
   - **Active work / open threads** → `identity/memory.md` Active Work
4. For `identity/memory.md` (hot layer):
   - Only promote things needed in every conversation
   - Update `## Current State` and `## Active Work`
   - Add one-liner to `## Session Log`
   - Keep under 2500 tokens — push detail to cold files
5. For `memory/*.md` (cold layer):
   - Add detailed entries with datestamps: `<!-- promoted YYYY-MM-DD -->`
   - Don't duplicate — consolidate with existing entries
   - Remove stale entries that are clearly no longer relevant
6. If `identity/memory.md` is over 2500 tokens, archive oldest entries to `memory/archive-YYYY-MM.md`
7. Report what was promoted, where it went, and what was skipped
