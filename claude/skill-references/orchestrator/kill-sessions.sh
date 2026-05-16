#!/bin/bash
# Kill running claude -p sessions in a sweep run directory
# Usage: bash kill-sessions.sh <run_dir> [--runners]
# Finds session.pid files, checks liveness, kills active sessions.
# With --runners: also kills let-it-rip.sh runner processes for the run dir.
#
# Examples:
#   Director: bash kill-sessions.sh tmp/claude-artifacts/sweep-address/2026-04-13-1804
#   VP:       bash kill-sessions.sh /path/to/repo/tmp/claude-artifacts/sweep-address/2026-04-13-1804 --runners

set -e

RUN_DIR="${1:?Usage: kill-sessions.sh <run_dir> [--runners]}"
KILL_RUNNERS=false

for arg in "$@"; do
    case "$arg" in
        --runners) KILL_RUNNERS=true ;;
    esac
done

if [ ! -d "$RUN_DIR" ]; then
    echo "Directory not found: $RUN_DIR"
    exit 1
fi

echo "=== Killing sessions in $RUN_DIR ==="

killed=0
dead=0

for pidfile in "$RUN_DIR"/pr-*/session.pid "$RUN_DIR"/issue-*/session.pid; do
    [ -f "$pidfile" ] || continue
    pid=$(cat "$pidfile")
    item=$(basename "$(dirname "$pidfile")")

    if kill -0 "$pid" 2>/dev/null; then
        echo "Killing $item (pid $pid)"
        kill "$pid" 2>/dev/null
        killed=$((killed + 1))
    else
        dead=$((dead + 1))
    fi
done

if [ "$KILL_RUNNERS" = true ]; then
    run_base=$(basename "$RUN_DIR")
    ps aux | grep "let-it-rip" | grep "$run_base" | grep -v grep | while read -r line; do
        pid=$(echo "$line" | awk '{print $2}')
        echo "Killing runner (pid $pid)"
        kill "$pid" 2>/dev/null
    done
fi

echo "Killed: $killed  Already dead: $dead"
