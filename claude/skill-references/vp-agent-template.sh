#!/bin/bash
# VP Agent — launches a Director claude session, which spawns its own Worker sessions
# Multi-tier agent hierarchy: VP (this script) → Director (claude -p) → Workers (claude -p)
# Directors can instruct workers to spawn subagents for 4+ tier depth.
#
# Usage: bash ~/.claude/skill-references/vp-agent-template.sh [TASK] [RUN_DIR_BASE]
# Example: bash ~/.claude/skill-references/vp-agent-template.sh "Summarize this repo" ./tmp/vp
#
# Requires: claude CLI, ~/.claude/skill-references/stream-monitor.sh
# Key learning: --allowedTools is mandatory on every claude -p invocation (headless sessions
# auto-deny unpermitted tools; settings.local.json doesn't reliably propagate to nested sessions).

set -euo pipefail

TASK="${1:-Explore this repository and produce a brief summary of its structure and purpose}"
RUN_DIR_BASE="${2:-./tmp/claude-artifacts/vp-experiment}"
TIMESTAMP=$(date +%Y-%m-%dT%H%M%S)
RUN_DIR="$(cd "$RUN_DIR_BASE" 2>/dev/null && pwd || mkdir -p "$RUN_DIR_BASE" && cd "$RUN_DIR_BASE" && pwd)/${TIMESTAMP}"
MONITOR="$HOME/.claude/skill-references/stream-monitor.sh"
ALLOWED_TOOLS="Read Glob Grep Bash Write"

mkdir -p "$RUN_DIR/director" "$RUN_DIR/workers"

# ============================================================
# Generate the Director prompt
# ============================================================

cat > "$RUN_DIR/director/prompt.txt" << 'DIRECTOR_PROMPT'
You are a Director agent. Your job is to break a task into subtasks, delegate each to parallel headless claude worker sessions, monitor their progress, and synthesize results.

## Task
{{TASK}}

## Run directory
{{RUN_DIR}}

## Rules
1. You are NON-INVASIVE — do not modify the working tree directly. All work happens through worker sessions.
2. All coordination is FILE-BASED — write prompts, read status files.
3. Workers communicate back to you via status.md and results.md in their artifact directories.

## Phases

### Phase 1: Plan
Break the task into 2-3 independent subtasks. Write your plan to {{RUN_DIR}}/director/plan.md.

### Phase 2: Launch Workers
For each subtask:
1. Create directory: mkdir -p {{RUN_DIR}}/workers/worker-N
2. Write {{RUN_DIR}}/workers/worker-N/prompt.txt with the subtask prompt
3. Launch the worker using this Bash command (use run_in_background: true):

cat "{{RUN_DIR}}/workers/worker-N/prompt.txt" | claude -p --allowedTools "{{ALLOWED_TOOLS}}" --verbose --output-format stream-json | {{MONITOR}} "{{RUN_DIR}}/workers/worker-N" | tee "{{RUN_DIR}}/workers/worker-N/raw.jsonl" > /dev/null

IMPORTANT: Each worker prompt MUST instruct the worker to:
- Write findings to: {{RUN_DIR}}/workers/worker-N/results.md
- Write status to: {{RUN_DIR}}/workers/worker-N/status.md
- Set milestone: running when starting, milestone: done when finished
- Keep results concise

### Phase 3: Monitor
After launching all workers, wait 45 seconds, then check every 30 seconds:
1. Read each worker's status.md — check milestone field
2. Read each worker's live.md — check for recent activity, errors, or stalls
3. Continue until all workers report milestone: done (or error)

### Phase 4: Synthesize
Once all workers are done:
1. Read each worker's results.md
2. Write a combined summary to {{RUN_DIR}}/director/results.md
3. Write "milestone: done" to {{RUN_DIR}}/director/status.md

Begin now with Phase 1.
DIRECTOR_PROMPT

# Substitute placeholders
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s|{{TASK}}|${TASK}|g" "$RUN_DIR/director/prompt.txt"
    sed -i '' "s|{{RUN_DIR}}|${RUN_DIR}|g" "$RUN_DIR/director/prompt.txt"
    sed -i '' "s|{{MONITOR}}|${MONITOR}|g" "$RUN_DIR/director/prompt.txt"
    sed -i '' "s|{{ALLOWED_TOOLS}}|${ALLOWED_TOOLS}|g" "$RUN_DIR/director/prompt.txt"
else
    sed -i "s|{{TASK}}|${TASK}|g" "$RUN_DIR/director/prompt.txt"
    sed -i "s|{{RUN_DIR}}|${RUN_DIR}|g" "$RUN_DIR/director/prompt.txt"
    sed -i "s|{{MONITOR}}|${MONITOR}|g" "$RUN_DIR/director/prompt.txt"
    sed -i "s|{{ALLOWED_TOOLS}}|${ALLOWED_TOOLS}|g" "$RUN_DIR/director/prompt.txt"
fi

# ============================================================
# Launch the Director session
# ============================================================

printf '=== VP Agent ===\n'
printf 'Task: %s\n' "$TASK"
printf 'Run dir: %s\n' "$RUN_DIR"
printf 'Launching Director session...\n\n'

if [ -x "$MONITOR" ]; then
    cat "$RUN_DIR/director/prompt.txt" \
        | sh -c "echo \$\$ > $RUN_DIR/director/session.pid; exec claude -p --allowedTools '$ALLOWED_TOOLS' --verbose --output-format stream-json" \
        | "$MONITOR" "$RUN_DIR/director" \
        | tee "$RUN_DIR/director/raw.jsonl" > /dev/null &
    DIRECTOR_PID=$!
else
    cat "$RUN_DIR/director/prompt.txt" \
        | sh -c "echo \$\$ > $RUN_DIR/director/session.pid; exec claude -p --allowedTools '$ALLOWED_TOOLS'" \
        > "$RUN_DIR/director/result-raw.txt" 2>&1 &
    DIRECTOR_PID=$!
fi

printf 'Director PID: %s\n' "$DIRECTOR_PID"
printf 'Director session.pid: %s/director/session.pid\n\n' "$RUN_DIR"

# ============================================================
# VP Monitor Loop
# ============================================================

printf '=== VP Monitoring ===\n'
printf 'Polling every 30s. Ctrl+C to stop monitoring (sessions continue).\n\n'

monitor_cycle=0
while true; do
    sleep 30
    monitor_cycle=$((monitor_cycle + 1))
    ts=$(date -Iseconds)
    printf '--- VP Check #%d @ %s ---\n' "$monitor_cycle" "$ts"

    # Check director status
    if [ -f "$RUN_DIR/director/status.md" ]; then
        director_milestone=$(grep '^milestone:' "$RUN_DIR/director/status.md" 2>/dev/null | awk '{print $2}')
        printf 'Director: milestone=%s\n' "$director_milestone"
        if [ "$director_milestone" = "done" ]; then
            printf '\n=== Director finished ===\n'
            if [ -f "$RUN_DIR/director/results.md" ]; then
                printf 'Results:\n'
                cat "$RUN_DIR/director/results.md"
            fi
            exit 0
        fi
    else
        printf 'Director: no status.md yet\n'
    fi

    # Check director liveness
    if [ -f "$RUN_DIR/director/live.md" ]; then
        last_line=$(tail -1 "$RUN_DIR/director/live.md" 2>/dev/null)
        printf 'Director live.md tail: %s\n' "$last_line"
    fi

    # Check workers and subagents
    if [ -d "$RUN_DIR/workers" ]; then
        for worker_dir in "$RUN_DIR/workers"/worker-*/; do
            [ -d "$worker_dir" ] || continue
            worker_name=$(basename "$worker_dir")
            if [ -f "${worker_dir}status.md" ]; then
                w_milestone=$(grep '^milestone:' "${worker_dir}status.md" 2>/dev/null | awk '{print $2}')
                printf '  %s: milestone=%s\n' "$worker_name" "$w_milestone"
            else
                printf '  %s: no status.md\n' "$worker_name"
            fi
            # Check for subagents
            if [ -d "${worker_dir}subagent" ]; then
                if [ -f "${worker_dir}subagent/status.md" ]; then
                    s_milestone=$(grep '^milestone:' "${worker_dir}subagent/status.md" 2>/dev/null | awk '{print $2}')
                    printf '    subagent: milestone=%s\n' "$s_milestone"
                else
                    printf '    subagent: no status.md\n'
                fi
            fi
        done
    else
        printf '  No workers spawned yet\n'
    fi

    printf '\n'

    # Safety: bail after 20 minutes
    if [ "$monitor_cycle" -ge 40 ]; then
        printf 'VP: 20-minute timeout reached. Stopping monitor.\n'
        printf 'Sessions may still be running. Check: %s\n' "$RUN_DIR"
        exit 1
    fi
done
