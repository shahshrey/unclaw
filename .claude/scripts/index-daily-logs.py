#!/usr/bin/env python3
"""
Index daily logs into SQLite FTS5 for full-text search.
Tracks file modification times to only re-index changed files.
Run via: python3 .claude/scripts/index-daily-logs.py [--rebuild]
"""

import sqlite3
import os
import sys
import re
from pathlib import Path
from datetime import datetime

SCRIPT_DIR = Path(__file__).parent
PROJECT_DIR = SCRIPT_DIR.parent.parent
LOGS_DIR = PROJECT_DIR / "daily-logs"
MEMORY_DIR = PROJECT_DIR / "memory"
DB_PATH = PROJECT_DIR / ".claude" / "memory.db"


def init_db(conn: sqlite3.Connection):
    conn.executescript("""
        CREATE TABLE IF NOT EXISTS indexed_files (
            path TEXT PRIMARY KEY,
            mtime REAL,
            indexed_at TEXT
        );
        CREATE VIRTUAL TABLE IF NOT EXISTS log_entries USING fts5(
            date,
            time_block,
            content,
            source_file,
            tokenize='porter unicode61'
        );
    """)


def parse_log_file(filepath: Path) -> list[dict]:
    text = filepath.read_text(encoding="utf-8")
    date_match = re.search(r"(\d{4}-\d{2}-\d{2})", filepath.name)
    is_memory = str(MEMORY_DIR) in str(filepath) if MEMORY_DIR.exists() else False
    date = date_match.group(1) if date_match else ("memory" if is_memory else "unknown")

    entries = []
    sections = re.split(r"^## ", text, flags=re.MULTILINE)

    for section in sections[1:]:
        lines = section.strip().split("\n")
        heading = lines[0].strip() if lines else ""
        body = "\n".join(lines[1:]).strip()

        if body:
            entries.append({
                "date": date,
                "time_block": heading,
                "content": body,
                "source_file": str(filepath.relative_to(PROJECT_DIR)),
            })

    if not entries and text.strip():
        entries.append({
            "date": date,
            "time_block": "full-file",
            "content": text.strip(),
            "source_file": str(filepath.relative_to(PROJECT_DIR)),
        })

    return entries


def index_file(conn: sqlite3.Connection, filepath: Path):
    rel_path = str(filepath.relative_to(PROJECT_DIR))
    conn.execute("DELETE FROM log_entries WHERE source_file = ?", (rel_path,))
    entries = parse_log_file(filepath)
    for entry in entries:
        conn.execute(
            "INSERT INTO log_entries (date, time_block, content, source_file) VALUES (?, ?, ?, ?)",
            (entry["date"], entry["time_block"], entry["content"], entry["source_file"]),
        )
    conn.execute(
        "INSERT OR REPLACE INTO indexed_files (path, mtime, indexed_at) VALUES (?, ?, ?)",
        (rel_path, filepath.stat().st_mtime, datetime.now().isoformat()),
    )


def needs_indexing(conn: sqlite3.Connection, filepath: Path) -> bool:
    rel_path = str(filepath.relative_to(PROJECT_DIR))
    row = conn.execute("SELECT mtime FROM indexed_files WHERE path = ?", (rel_path,)).fetchone()
    if row is None:
        return True
    return filepath.stat().st_mtime > row[0]


def main():
    rebuild = "--rebuild" in sys.argv

    if not LOGS_DIR.exists():
        print("No daily-logs directory found.")
        return

    conn = sqlite3.connect(str(DB_PATH))
    init_db(conn)

    if rebuild:
        conn.execute("DELETE FROM log_entries")
        conn.execute("DELETE FROM indexed_files")
        print("Rebuilding index from scratch...")

    all_files = sorted(LOGS_DIR.glob("*.md"))
    if MEMORY_DIR.exists():
        all_files.extend(sorted(MEMORY_DIR.glob("*.md")))

    indexed = 0
    skipped = 0

    for filepath in all_files:
        if needs_indexing(conn, filepath):
            index_file(conn, filepath)
            indexed += 1
        else:
            skipped += 1

    conn.commit()

    total = conn.execute("SELECT COUNT(*) FROM log_entries").fetchone()[0]
    files_count = conn.execute("SELECT COUNT(*) FROM indexed_files").fetchone()[0]

    print(f"Indexed: {indexed} files, Skipped: {skipped} unchanged, Total entries: {total}, Files tracked: {files_count}")
    conn.close()


if __name__ == "__main__":
    main()
