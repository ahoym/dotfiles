#!/usr/bin/env python3
# SessionStart hook: warns when the learnings keyword index is stale.
# Stays silent unless >= THRESHOLD files have changed since the last rebuild,
# so it doesn't nag on every minor edit.

import json
import os
import subprocess
import sys
from pathlib import Path

THRESHOLD = 5
CLAUDE = Path.home() / ".claude"
INDEX = CLAUDE / "learnings" / ".keyword-index.json"


def main():
    if not INDEX.exists():
        return
    try:
        meta = json.loads(INDEX.read_text()).get("_meta", {})
    except (json.JSONDecodeError, OSError):
        return
    anchor = (meta.get("last_rebuild_commit") or "").split("_", 1)[0]
    if not anchor:
        return

    # Resolve through the symlink to find the actual repo root that owns the file.
    repo = INDEX.resolve().parent
    while repo != repo.parent and not (repo / ".git").exists():
        repo = repo.parent
    if not (repo / ".git").exists():
        return

    try:
        out = subprocess.check_output(
            [
                "git", "-C", str(repo), "diff", "--name-only",
                f"{anchor}..HEAD", "--",
                "claude/learnings/", "claude/guidelines/",
                "claude/commands/", "claude/skill-references/",
            ],
            stderr=subprocess.DEVNULL,
            text=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return

    changed = [line for line in out.splitlines() if line.strip()]
    if len(changed) < THRESHOLD:
        return

    msg = (
        f"⚠️  Learnings keyword index is stale: {len(changed)} files changed "
        f"since rebuild at {anchor[:7]}. Run `/learnings:curate` to refresh "
        f"(affects the UserPromptSubmit suggestion hook)."
    )
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "SessionStart",
            "additionalContext": msg,
        }
    }))


if __name__ == "__main__":
    try:
        main()
    except Exception as e:  # noqa: BLE001 — hook must never block a session
        print(f"learnings-staleness: {e}", file=sys.stderr)
