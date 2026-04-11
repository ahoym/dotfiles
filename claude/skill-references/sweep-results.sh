#!/bin/bash
# sweep-results.sh — Read results and learnings for a sweep run directory
# Usage: bash ~/.claude/skill-references/sweep-results.sh <run-dir>
# Already allowlisted via: Bash(bash ~/.claude/skill-references/**)

set -euo pipefail

RUN_DIR="${1:?Usage: sweep-results.sh <run-dir>}"

if [ ! -d "$RUN_DIR" ]; then
    echo "ERROR: run directory not found: $RUN_DIR"
    exit 1
fi

echo "=== Sweep Results: $(basename "$RUN_DIR") ==="

for pr_dir in "$RUN_DIR"/pr-*/; do
    [ -d "$pr_dir" ] || continue
    pr_num=$(basename "$pr_dir" | sed 's/pr-//')
    result_file="${pr_dir}result.md"
    learnings_file="${pr_dir}learnings.md"

    printf "\n--- PR #%s ---\n" "$pr_num"

    if [ -f "$result_file" ]; then
        cat "$result_file"
    else
        echo "result: no result.md"
    fi

    if [ -f "$learnings_file" ]; then
        printf "\nLearnings:\n"
        cat "$learnings_file"
    fi
done

echo ""
echo "=== End ==="
