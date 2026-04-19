#!/bin/bash
# sweep-status-summary.sh
# Read status.md + state.md + tail of output.log across all item dirs in a sweep run
# and print a structured monitoring report. Works for both pr-<N>/ (sweep:*-prs)
# and issue-<N>/ (sweep:work-items) layouts.
#
# Usage:
#   bash ~/.claude/skill-references/sweep-status-summary.sh <RUN_DIR> [--logs N]
#     --logs N  — also include last N lines of each item's output.log (default: 0)

set -euo pipefail

RUN_DIR="${1:?Usage: sweep-status-summary.sh <RUN_DIR> [--logs N]}"
shift || true

LOG_TAIL=0
SHOW_RETRO=false
while [ $# -gt 0 ]; do
    case "$1" in
        --logs) LOG_TAIL="${2:-20}"; shift 2 ;;
        --retro) SHOW_RETRO=true; shift ;;
        *) echo "ERROR: unknown arg: $1" >&2; exit 1 ;;
    esac
done

[ -d "$RUN_DIR" ] || { echo "ERROR: run dir not found: $RUN_DIR" >&2; exit 1; }

echo "=== Sweep Status Summary ==="
echo "Run dir: $RUN_DIR"
echo ""

# Find all item dirs (issue-* or pr-*)
shopt -s nullglob
item_dirs=("$RUN_DIR"/issue-* "$RUN_DIR"/pr-*)

if [ ${#item_dirs[@]} -eq 0 ]; then
    echo "No item directories found (expected issue-<N>/ or pr-<N>/)"
    exit 0
fi

# Rate-limit sentinel
if [ -f "$RUN_DIR/.rate-limited" ]; then
    echo "WARNING: .rate-limited sentinel present"
    echo ""
fi

for d in "${item_dirs[@]}"; do
    name=$(basename "$d")
    echo "--- $name ---"
    if [ -f "$d/status.md" ]; then
        echo "[status.md]"
        cat "$d/status.md"
    else
        echo "[status.md] MISSING"
    fi
    echo ""
    if [ -f "$d/state.md" ]; then
        echo "[state.md]"
        cat "$d/state.md"
    else
        echo "[state.md] MISSING"
    fi
    if [ "$LOG_TAIL" -gt 0 ] && [ -f "$d/output.log" ]; then
        echo ""
        echo "[output.log — last $LOG_TAIL lines]"
        tail -n "$LOG_TAIL" "$d/output.log"
    fi
    if [ "$SHOW_RETRO" = true ]; then
        if [ -f "$d/results.md" ]; then
            echo ""
            echo "[results.md]"
            cat "$d/results.md"
        fi
        if [ -f "$d/learnings.md" ]; then
            echo ""
            echo "[learnings.md]"
            cat "$d/learnings.md"
        fi
    fi
    echo ""
done

# Quick aggregate (count over status.md files we actually have)
echo "=== Aggregate ==="
status_files=()
for d in "${item_dirs[@]}"; do
    [ -f "$d/status.md" ] && status_files+=("$d/status.md")
done
done_count=0
errored_count=0
skipped_count=0
if [ ${#status_files[@]} -gt 0 ]; then
    done_count=$( { grep -l '^milestone: done' "${status_files[@]}" 2>/dev/null || true; } | wc -l | tr -d ' ')
    errored_count=$( { grep -l '^milestone: errored' "${status_files[@]}" 2>/dev/null || true; } | wc -l | tr -d ' ')
    skipped_count=$( { grep -l '^milestone: skipped' "${status_files[@]}" 2>/dev/null || true; } | wc -l | tr -d ' ')
fi
total=${#item_dirs[@]}
echo "Total: $total | Done: $done_count | Errored: $errored_count | Skipped: $skipped_count"
