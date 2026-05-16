#!/bin/bash
# Sweep Dashboard — show worker states across one or more run directories
# Usage: bash sweep-dashboard.sh <run_dir> [<run_dir2> ...]
# Works for both VP-tier (multiple run dirs across repos) and Director-tier (single run dir)
#
# Examples:
#   Director: bash sweep-dashboard.sh tmp/claude-artifacts/sweep-reviews/2026-04-13-1804
#   VP:       bash sweep-dashboard.sh /path/to/repo-a/tmp/.../sweep-reviews/... /path/to/repo-b/tmp/.../sweep-reviews/...

set -e

if [ $# -eq 0 ]; then
    echo "Usage: sweep-dashboard.sh <run_dir> [<run_dir2> ...]"
    exit 1
fi

echo "========================================"
echo " SWEEP DASHBOARD — $(date -Iseconds)"
echo "========================================"

printf "\n%-20s %-6s %-12s %-14s %-6s %-24s\n" "RUN" "ITEM" "STATE" "MILESTONE" "LINES" "LAST ACTIVITY"
printf "%-20s %-6s %-12s %-14s %-6s %-24s\n" "--------------------" "------" "------------" "--------------" "------" "------------------------"

for run_dir in "$@"; do
    run_name=$(basename "$run_dir")

    if [ ! -d "$run_dir" ]; then
        printf "%-20s (directory not found)\n" "$run_name"
        continue
    fi

    find "$run_dir" -maxdepth 1 -type d -name "pr-*" -o -name "issue-*" | sort | while read item_dir; do
        item=$(basename "$item_dir")
        state="-"
        milestone="-"
        lines="-"
        last="-"

        if [ -f "$item_dir/state.md" ]; then
            state=$(grep '^state:' "$item_dir/state.md" 2>/dev/null | awk '{print $2}')
        fi
        if [ -f "$item_dir/status.md" ]; then
            milestone=$(grep '^milestone:' "$item_dir/status.md" 2>/dev/null | awk '{print $2}')
        fi
        if [ -f "$item_dir/live.md" ]; then
            lines=$(wc -l < "$item_dir/live.md" 2>/dev/null | tr -d ' ')
            last=$(grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}T[0-9:]*' "$item_dir/live.md" 2>/dev/null | tail -1)
        fi

        printf "%-20s %-6s %-12s %-14s %-6s %-24s\n" "$run_name" "$item" "${state:--}" "${milestone:--}" "${lines:--}" "${last:--}"
    done
done

# Summary counts
echo ""
echo "--- SUMMARY ---"
for run_dir in "$@"; do
    run_name=$(basename "$run_dir")
    [ ! -d "$run_dir" ] && continue

    c=$(find "$run_dir" -name state.md -exec grep -l '^state: completed' {} \; 2>/dev/null | wc -l | tr -d ' ')
    r=$(find "$run_dir" -name state.md -exec grep -l '^state: running' {} \; 2>/dev/null | wc -l | tr -d ' ')
    e=$(find "$run_dir" -name state.md -exec grep -l '^state: errored' {} \; 2>/dev/null | wc -l | tr -d ' ')
    t=$(find "$run_dir" -maxdepth 1 -type d \( -name "pr-*" -o -name "issue-*" \) 2>/dev/null | wc -l | tr -d ' ')
    echo "$run_name: $c/$t completed, $r running, $e errored"
done
