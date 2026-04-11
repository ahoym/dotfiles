#!/bin/bash
# audit-permissions.sh — Scan sweep run raw.jsonl files for permission denials
# Usage: bash ~/.claude/skill-references/audit-permissions.sh <run-dir>
# Already allowlisted via: Bash(bash ~/.claude/skill-references/**)
#
# Extracts denied tool calls from stream-json output and suggests
# permission patterns to add to ~/.claude/settings.json

set -euo pipefail

RUN_DIR="${1:?Usage: audit-permissions.sh <run-dir>}"

if [ ! -d "$RUN_DIR" ]; then
    echo "ERROR: run directory not found: $RUN_DIR"
    exit 1
fi

echo "=== Permission Audit: $(basename "$RUN_DIR") ==="
echo ""

TOTAL_DENIALS=0
TEMP=$(mktemp)
trap 'rm -f "$TEMP"' EXIT

for pr_dir in "$RUN_DIR"/pr-*/; do
    [ -d "$pr_dir" ] || continue
    pr_num=$(basename "$pr_dir" | sed 's/pr-//')

    for raw in "$pr_dir"raw*.jsonl; do
        [ -f "$raw" ] || continue

        # Extract permission denial content from tool results
        grep -a "requires approval\|permission_denial\|Permission denied\|not allowed" "$raw" 2>/dev/null \
            | grep -ao '"content":"[^"]*requires approval[^"]*"' 2>/dev/null \
            | sort -u \
            >> "$TEMP" || true

        # Count denials from result events
        count=$(grep -ao '"permission_denials":\[[^]]*\]' "$raw" 2>/dev/null \
            | grep -o '"[^"]*"' | grep -v "permission_denials" | wc -l || echo 0)
        TOTAL_DENIALS=$((TOTAL_DENIALS + count))
    done
done

if [ ! -s "$TEMP" ]; then
    echo "No permission denials found."
    echo "=== Done ==="
    exit 0
fi

echo "Denied operations (deduplicated):"
echo ""
sort -u "$TEMP" | while IFS= read -r line; do
    # Clean up the content field
    cleaned=$(echo "$line" | sed 's/"content":"//;s/"$//' | head -c 200)
    echo "  - $cleaned"
done

echo ""
echo "Total denial events: ~$TOTAL_DENIALS"
echo ""
echo "=== Done ==="
