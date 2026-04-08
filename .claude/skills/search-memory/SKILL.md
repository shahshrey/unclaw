---
name: search-memory
description: Search through all past daily logs, cold memory files, and conversation history. Use when Shrey asks "when did we...", "do you remember...", "what did I say about...", or needs context from a past session.
allowed-tools: Bash Read
---

Search the memory system for past context:

## Search Order

1. **Check hot memory first** — read `identity/memory.md` (already in context, might have the answer)
2. **Check cold memory** — read relevant `memory/*.md` files (projects, decisions, preferences, people)
3. **Search daily log archive** — FTS5 full-text search for raw conversation history

## Daily Log Search

1. Ensure the index is up to date:
   ```bash
   python3 .claude/scripts/index-daily-logs.py
   ```

2. Search using FTS5 syntax:
   ```bash
   python3 .claude/scripts/search-logs.py "$ARGUMENTS"
   ```

   Supported query syntax:
   - Simple words: `typescript testing`
   - Phrases: `"pull request"`
   - Boolean: `deploy AND production`
   - Negation: `api NOT graphql`
   - Prefix: `auth*`
   - Date filter: `--date 2026-04-05`
   - Limit: `--limit 20`

3. If the search returns results, read the full source file for more context if needed.

4. Synthesize findings into a clear answer. Don't dump raw results — summarize what's relevant to the question.
