---
name: distill-session
description: Compress and save the key context from this session to the daily log. Run before ending a long session.
disable-model-invocation: true
---

Session distillation — save this session's context to the daily log:

1. Summarize what was accomplished in this session (3-5 bullets)
2. List any open tasks or threads left unfinished
3. Extract any preferences or patterns Shrey demonstrated
4. Append to `daily-logs/YYYY-MM-DD.md` (today's date) under a `## [HH:MM] Session Distill` heading
   - Create the file with a `# Daily Log — YYYY-MM-DD` header if it doesn't exist
5. Also append a one-liner to `identity/memory.md` under `## Session Log`:
   Format: `- [YYYY-MM-DD] <what was done, 1 line>`
6. Confirm what was saved

Token budget: keep the daily log entry under 200 words. Keep the identity/memory.md one-liner under 20 words.
