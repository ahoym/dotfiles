#!/bin/bash
# sweep-status.sh — Read status and live activity for a sweep run directory
# Usage: bash ~/.claude/skill-references/sweep-status.sh <run-dir>
# Already allowlisted via: Bash(bash ~/.claude/skill-references/**)

set -euo pipefail

RUN_DIR="${1:?Usage: sweep-status.sh <run-dir>}"

if [ ! -d "$RUN_DIR" ]; then
    echo "ERROR: run directory not found: $RUN_DIR"
    exit 1
fi

echo "=== Sweep Status: $(basename "$RUN_DIR") ==="

for pr_dir in "$RUN_DIR"/pr-*/; do
    [ -d "$pr_dir" ] || continue
    pr_num=$(basename "$pr_dir" | sed 's/pr-//')
    status_file="${pr_dir}status.md"
    live_file="${pr_dir}live.md"
    state_file="${pr_dir}state.md"

    printf "\n--- PR #%s ---\n" "$pr_num"

    # Status
    if [ -f "$status_file" ]; then
        cat "$status_file"
    else
        echo "status: no status.md"
    fi

    # State (runner state)
    if [ -f "$state_file" ]; then
        printf "\nRunner state:\n"
        cat "$state_file"
    fi

    # Live activity (last 5 lines)
    if [ -f "$live_file" ]; then
        printf "\nLast activity:\n"
        tail -5 "$live_file"
    fi
done

echo ""
echo "=== End ==="
