#!/bin/bash
# Consolidation Loop runner — iterates Claude over the consolidation spec.
# Usage: ./wiggum.sh [max_iterations]
#
# Expects to run from a consolidation worktree root (created by /ralph:consolidate:init).
# Injects security hooks for the duration of the loop, removes them on exit.
#
# Example:
#   cd .claude/worktrees/consolidate-2026-02-25
#   bash ~/.claude/ralph/consolidate/wiggum.sh 20

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Fixed paths ---
PROJECT_DIR=".claude/consolidate-output"
SPEC_FILE="${PROJECT_DIR}/spec.md"
PROGRESS_FILE="${PROJECT_DIR}/progress.md"
LOG_DIR="${PROJECT_DIR}/logs"
MAX_ITERATIONS=${1:-20}
COMPLETION_SIGNAL="WOOT_COMPLETE_WOOT"
AI_COMMAND="claude --dangerously-skip-permissions --print"

# --- Validate ---
if [ ! -d "$PROJECT_DIR" ]; then
    echo "Error: consolidate-output directory not found: $PROJECT_DIR"
    echo "Run /ralph:consolidate:init first to set up the worktree."
    exit 1
fi

if [ ! -f "$SPEC_FILE" ]; then
    echo "Error: spec.md not found in $PROJECT_DIR"
    exit 1
fi

if [ ! -f "$PROGRESS_FILE" ]; then
    echo "Error: progress.md not found in $PROJECT_DIR"
    exit 1
fi

# --- Hooks ---
SETTINGS_FILE=".claude/settings.local.json"
WORKTREE_ROOT="$(pwd)"

source "$SCRIPT_DIR/hooks/lib-hooks.sh"
inject_hooks "$SETTINGS_FILE" "$WORKTREE_ROOT"
trap 'remove_hooks "$SETTINGS_FILE"' EXIT

# --- Loop ---
mkdir -p "$LOG_DIR"

echo ════════════════════════════════════════════════════════════
echo Starting Consolidation Loop
echo ════════════════════════════════════════════════════════════
echo "Project:        $PROJECT_DIR"
echo "Spec file:      $SPEC_FILE"
echo "Progress file:  $PROGRESS_FILE"
echo "Log directory:  $LOG_DIR"
echo "Max iterations: $MAX_ITERATIONS"
echo "Started at:     $(date)"
echo ════════════════════════════════════════════════════════════

LOOP_START_TIME=$(date +%s)
LAST_ACTIONS_ITER=0

for i in $(seq 1 $MAX_ITERATIONS); do
    ITER_START_TIME=$(date +%s)
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    LOG_FILE="$LOG_DIR/iteration_${i}_${TIMESTAMP}.log"

    echo ""
    echo "--- Iteration $i of $MAX_ITERATIONS ---"
    echo "Started at: $(date)"
    echo "Log file:   $LOG_FILE"
    echo ""

    # Sweep count validation: capture before
    SWEEP_BEFORE=$(awk -F'|' '/SWEEP_COUNT/{gsub(/[[:space:]]/, "", $3); print $3}' "$PROGRESS_FILE") || true
    SWEEP_BEFORE=${SWEEP_BEFORE:-0}

    if cat "$SPEC_FILE" | $AI_COMMAND 2>&1 | tee "$LOG_FILE"; then
        ITER_STATUS="success"
    else
        ITER_STATUS="error"
        echo "Warning: Iteration $i exited with non-zero status" | tee -a "$LOG_FILE"
    fi

    # Sweep count validation: capture after and compare
    SWEEP_AFTER=$(awk -F'|' '/SWEEP_COUNT/{gsub(/[[:space:]]/, "", $3); print $3}' "$PROGRESS_FILE") || true
    SWEEP_AFTER=${SWEEP_AFTER:-0}
    SWEEP_DELTA=$((SWEEP_AFTER - SWEEP_BEFORE))
    if [ "$SWEEP_DELTA" -ne 1 ]; then
        echo "WARNING: Sweep count changed by $SWEEP_DELTA (expected 1) in iteration $i" | tee -a "$LOG_FILE"
    fi

    ITER_END_TIME=$(date +%s)
    ITER_DURATION=$((ITER_END_TIME - ITER_START_TIME))

    echo ""
    echo "Iteration $i completed in ${ITER_DURATION}s (status: $ITER_STATUS)"

    # Track whether this iteration made progress (wrote to decisions.md)
    if grep -q "| ${i} |" "${PROJECT_DIR}/decisions.md" 2>/dev/null; then
        LAST_ACTIONS_ITER=$i
    fi

    # Check for stop signals (exact line match — prevents false positives from prose mentions)
    STOP_SIGNAL=""
    if grep -qx "$COMPLETION_SIGNAL" "$PROGRESS_FILE"; then
        STOP_SIGNAL="$COMPLETION_SIGNAL"
    elif grep -qx "MAX_ROUNDS_HIT" "$PROGRESS_FILE"; then
        STOP_SIGNAL="MAX_ROUNDS_HIT"
    elif grep -qx "MAX_DEEP_DIVES_HIT" "$PROGRESS_FILE"; then
        STOP_SIGNAL="MAX_DEEP_DIVES_HIT"
    fi

    if [ -n "$STOP_SIGNAL" ]; then
        LOOP_END_TIME=$(date +%s)
        LOOP_DURATION=$((LOOP_END_TIME - LOOP_START_TIME))

        echo ""
        echo ════════════════════════════════════════════════════════════
        if [ "$STOP_SIGNAL" = "$COMPLETION_SIGNAL" ]; then
            echo "Done! Consolidation complete."
        else
            echo "Stopped: $STOP_SIGNAL"
            echo "Check blockers.md for details."
        fi
        echo "Total iterations: $i"
        echo "Total duration:   ${LOOP_DURATION}s"
        echo "Completed at:     $(date)"
        echo ════════════════════════════════════════════════════════════
        echo ""
        echo "Review the changes:"
        echo "  git diff main -- .claude/"
        echo ""
        echo "If satisfied, merge to main:"
        echo "  git checkout main"
        echo "  git merge $(git rev-parse --abbrev-ref HEAD)"
        echo ""
        echo "Output files:"
        echo "  $PROJECT_DIR/report.md     - Cumulative summary"
        echo "  $PROJECT_DIR/decisions.md  - Full decision log"
        echo "  $PROJECT_DIR/blockers.md   - Items needing human review"
        echo "  $PROJECT_DIR/lows.md       - Items for /learnings:curate"
        if [ "$STOP_SIGNAL" = "$COMPLETION_SIGNAL" ]; then
            exit 0
        else
            exit 1
        fi
    fi

    sleep 2
done

LOOP_END_TIME=$(date +%s)
LOOP_DURATION=$((LOOP_END_TIME - LOOP_START_TIME))

# Stalled detection: distinguish "progressing" from "stalled"
ITERS_SINCE_ACTION=$((MAX_ITERATIONS - LAST_ACTIONS_ITER))

echo ""
echo ════════════════════════════════════════════════════════════
echo "Max iterations ($MAX_ITERATIONS) reached."
echo "Total duration: ${LOOP_DURATION}s"
echo "Ended at:       $(date)"

if [ $ITERS_SINCE_ACTION -ge 3 ]; then
    echo ""
    echo "STATUS: STALLED"
    echo "No actions taken in the last $ITERS_SINCE_ACTION iterations."
    echo "The loop may be thrashing or the agent may not be making progress."
    echo "Check the last few logs in $LOG_DIR for diagnosis."
else
    echo ""
    echo "STATUS: PROGRESSING"
    echo "Last action was in iteration $LAST_ACTIONS_ITER."
    echo "The corpus may simply need more iterations."
fi

echo ════════════════════════════════════════════════════════════
echo ""
echo "Resume with /ralph:consolidate:resume to review state and relaunch."
echo ""
echo "Output files:"
echo "  $PROJECT_DIR/report.md     - Cumulative summary"
echo "  $PROJECT_DIR/decisions.md  - Full decision log"
echo "  $PROJECT_DIR/blockers.md   - Items needing human review"
echo "  $PROJECT_DIR/lows.md       - Items for /learnings:curate"
exit 1
