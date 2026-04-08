#!/usr/bin/env python3
"""
Search indexed daily logs using SQLite FTS5.
Usage: python3 .claude/scripts/search-logs.py "query" [--limit N] [--date YYYY-MM-DD]
Returns matching entries with context, ranked by relevance.
"""

import sqlite3
import sys
import argparse
from pathlib import Path
from typing import Optional

SCRIPT_DIR = Path(__file__).parent
PROJECT_DIR = SCRIPT_DIR.parent.parent
DB_PATH = PROJECT_DIR / ".claude" / "memory.db"


def search(query: str, limit: int = 10, date_filter: Optional[str] = None) -> list[dict]:
    if not DB_PATH.exists():
        print("No index found. Run: python3 .claude/scripts/index-daily-logs.py")
        return []

    conn = sqlite3.connect(str(DB_PATH))
    conn.row_factory = sqlite3.Row

    if date_filter:
        rows = conn.execute(
            """
            SELECT date, time_block, content, source_file,
                   rank
            FROM log_entries
            WHERE log_entries MATCH ? AND date = ?
            ORDER BY rank
            LIMIT ?
            """,
            (query, date_filter, limit),
        ).fetchall()
    else:
        rows = conn.execute(
            """
            SELECT date, time_block, content, source_file,
                   rank
            FROM log_entries
            WHERE log_entries MATCH ?
            ORDER BY rank
            LIMIT ?
            """,
            (query, limit),
        ).fetchall()

    conn.close()
    return [dict(r) for r in rows]


def main():
    parser = argparse.ArgumentParser(description="Search daily logs")
    parser.add_argument("query", help="Search query (supports FTS5 syntax: AND, OR, NOT, phrases)")
    parser.add_argument("--limit", type=int, default=10, help="Max results (default: 10)")
    parser.add_argument("--date", help="Filter by date (YYYY-MM-DD)")
    args = parser.parse_args()

    results = search(args.query, args.limit, args.date)

    if not results:
        print(f"No results for: {args.query}")
        return

    print(f"Found {len(results)} result(s) for: {args.query}\n")

    for i, r in enumerate(results, 1):
        print(f"--- Result {i} [{r['date']}] {r['time_block']} ---")
        print(f"Source: {r['source_file']}")
        content = r["content"]
        if len(content) > 500:
            content = content[:500] + "..."
        print(content)
        print()


if __name__ == "__main__":
    main()
