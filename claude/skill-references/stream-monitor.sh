#!/bin/bash
# Stream Monitor — pipe filter for claude -p --verbose --output-format stream-json
# Reads JSON events from stdin, passes through to stdout, writes live.md as side effect.
#
# Usage: cat prompt.txt | claude -p --verbose --output-format stream-json \
#          | stream-monitor.sh "$PR_DIR" | tee "$PR_DIR/raw.jsonl"
#
# PID resolution: reads $PR_DIR/session.pid (written by runner via sh -c/exec pattern),
# falls back to $SESSION_PID env var, then "unknown".

set -euo pipefail

PR_DIR="${1:?Usage: stream-monitor.sh <PR_DIR>}"
LIVE="$PR_DIR/live.md"

# Resolve PID: pid file (with brief retry for pipeline race) > env var > unknown
resolve_pid() {
    if [ -n "${SESSION_PID:-}" ]; then echo "$SESSION_PID"; return; fi
    for _ in 1 2 3 4 5; do
        if [ -f "$PR_DIR/session.pid" ]; then cat "$PR_DIR/session.pid"; return; fi
        sleep 0.1
    done
    echo "unknown"
}

PID=$(resolve_pid)
perm_count=0
err_count=0
last_type=""
saw_result=false

printf '## %s — started\npid: %s\n\n' "$(date -Iseconds)" "$PID" >> "$LIVE"

while IFS= read -r line; do
    printf '%s\n' "$line"
    type=$(printf '%s' "$line" | jq -r '.type // empty' 2>/dev/null) || continue
    ts=$(date -Iseconds)

    case "$type" in
        system)
            subtype=$(printf '%s' "$line" | jq -r '.subtype // empty' 2>/dev/null)
            if [ "$subtype" = "init" ]; then
                model=$(printf '%s' "$line" | jq -r '.model // "unknown"' 2>/dev/null)
                printf '## %s — init\nmodel: %s\n\n' "$ts" "$model" >> "$LIVE"
            fi ;;

        assistant)
            tool=$(printf '%s' "$line" | jq -r '[.message.content[]? | select(.type == "tool_use") | .name] | first // empty' 2>/dev/null)
            if [ -n "$tool" ]; then
                parent=$(printf '%s' "$line" | jq -r '.parent_tool_use_id // empty' 2>/dev/null)
                input=$(printf '%s' "$line" | jq -r '[.message.content[]? | select(.type == "tool_use") | .input | tostring] | first // "" | .[0:120]' 2>/dev/null)
                label="$tool"; [ -n "$parent" ] && label="$tool (subagent)"
                printf '## %s — tool_call\ntool: %s\ninput: %s\n\n' "$ts" "$label" "$input" >> "$LIVE"
            fi
            last_type="assistant" ;;

        user)
            content=$(printf '%s' "$line" | jq -r '[.message.content[]? | select(.type == "tool_result") | .content] | first // empty' 2>/dev/null)
            if printf '%s' "$content" | grep -q "permission" 2>/dev/null; then
                perm_count=$((perm_count + 1))
                printf '## %s — escalation\ntype: permission_denial (count: %d)\ncontent: %s\n\n' \
                    "$ts" "$perm_count" "$(printf '%s' "$content" | head -c 200)" >> "$LIVE"
            fi
            if printf '%s' "$content" | grep -qi "error\|failed\|exception" 2>/dev/null; then
                err_count=$((err_count + 1))
                [ "$err_count" -ge 3 ] && printf '## %s — escalation\ntype: repeated_errors (count: %d)\ncontent: %s\n\n' \
                    "$ts" "$err_count" "$(printf '%s' "$content" | head -c 200)" >> "$LIVE"
            fi
            last_type="user" ;;

        rate_limit_event)
            printf '## %s — rate_limit\n\n' "$ts" >> "$LIVE" ;;

        result)
            saw_result=true
            printf '## %s — completed\n%s\n\n' "$ts" \
                "$(printf '%s' "$line" | jq -r '"is_error: \(.is_error // false)\nduration_ms: \(.duration_ms // 0)\ncost_usd: \(.total_cost_usd // 0)\nturns: \(.num_turns // 0)\npermission_denials: \(.permission_denials | length // 0)"' 2>/dev/null)
errors_seen: $err_count" >> "$LIVE" ;;
    esac
done

if [ "$saw_result" = false ]; then
    printf '## %s — terminated\nreason: pipe closed without result event\nlast_event_type: %s\nerrors_seen: %d\n\n' \
        "$(date -Iseconds)" "$last_type" "$err_count" >> "$LIVE"
fi
