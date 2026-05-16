#!/bin/bash
# Check liveness of claude -p sessions in a run directory
# Usage: bash session-liveness.sh <run_dir|session_dir>
# Reads session.pid files, checks if processes are alive, shows live.md tail.
#
# Works for both:
#   Director session dirs (single session.pid)
#   Sweep run dirs (multiple pr-*/session.pid)

set -e

DIR="${1:?Usage: session-liveness.sh <run_dir|session_dir>}"

if [ ! -d "$DIR" ]; then
    echo "Directory not found: $DIR"
    exit 1
fi

echo "=== Session Liveness @ $(date -Iseconds) ==="

check_session() {
    local dir=$1
    local name=$2
    local pidfile="$dir/session.pid"

    if [ ! -f "$pidfile" ]; then
        printf "%-20s  NO PID FILE\n" "$name"
        return
    fi

    local pid=$(cat "$pidfile")
    local alive=$(kill -0 "$pid" 2>/dev/null && echo ALIVE || echo DEAD)
    local lines="-"
    local last="-"

    if [ -f "$dir/live.md" ]; then
        lines=$(wc -l < "$dir/live.md" 2>/dev/null | tr -d ' ')
        last=$(grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}T[0-9:]*' "$dir/live.md" 2>/dev/null | tail -1)
    fi

    printf "%-20s  pid=%-8s %-5s  live.md=%-5s lines  last=%s\n" "$name" "$pid" "$alive" "$lines" "${last:--}"
}

# Check if this is a single session dir or a run dir with items
if [ -f "$DIR/session.pid" ]; then
    check_session "$DIR" "$(basename "$DIR")"
fi

for item_dir in "$DIR"/pr-* "$DIR"/issue-* "$DIR"/director-*; do
    [ -d "$item_dir" ] || continue
    check_session "$item_dir" "$(basename "$item_dir")"
done
