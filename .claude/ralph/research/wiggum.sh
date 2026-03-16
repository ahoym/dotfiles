#!/bin/bash
# Ralph Loop runner — iterates Claude over a research spec.
# Usage: ./wiggum.sh <project_directory> [max_iterations]
#
# Expects to run from a worktree root (created by /ralph:init).
# Injects security hooks for the duration of the loop, removes them on exit.
#
# Example:
#   cd .claude/worktrees/ralph-my-topic
#   bash ~/.claude/ralph/research/wiggum.sh docs/staged-learnings/my-topic 10

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Args ---
if [ -z "$1" ]; then
    echo "Usage: $0 <project_directory> [max_iterations]"
    echo "Example: $0 docs/staged-learnings/monte-carlo 10"
    exit 1
fi

PROJECT_DIR="$1"
PROMPT_FILE="${PROJECT_DIR}/spec.md"
PROGRESS_FILE="${PROJECT_DIR}/progress.md"
LOG_DIR="${PROJECT_DIR}/logs"
MAX_ITERATIONS=${2:-10}
COMPLETION_SIGNAL=${3:-"WOOT_COMPLETE_WOOT"}
AI_COMMAND="claude --dangerously-skip-permissions --print"

# --- Validate ---
if [ ! -d "$PROJECT_DIR" ]; then
    echo "Error: Project directory does not exist: $PROJECT_DIR"
    exit 1
fi

if [ ! -f "$PROMPT_FILE" ]; then
    echo "Error: spec.md not found in $PROJECT_DIR"
    exit 1
fi

if [ ! -f "$PROGRESS_FILE" ]; then
    echo "Error: progress.md not found in $PROJECT_DIR"
    exit 1
fi

# --- Hooks ---
SETTINGS_FILE=".claude/settings.local.json"
ABS_PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

source "$SCRIPT_DIR/hooks/lib-hooks.sh"
inject_hooks "$SETTINGS_FILE" "$ABS_PROJECT_DIR"
trap 'remove_hooks "$SETTINGS_FILE"; sleep 3; osascript -e "tell application \"iTerm2\" to tell current session of current window to close"' EXIT

# --- Loop ---
mkdir -p "$LOG_DIR"

echo ════════════════════════════════════════════════════════════
echo Starting Ralph Loop
echo ════════════════════════════════════════════════════════════
echo "Project:        $PROJECT_DIR"
echo "Spec file:      $PROMPT_FILE"
echo "Progress file:  $PROGRESS_FILE"
echo "Log directory:  $LOG_DIR"
echo "Max iterations: $MAX_ITERATIONS"
echo "Started at:     $(date)"
echo ════════════════════════════════════════════════════════════

LOOP_START_TIME=$(date +%s)

for i in $(seq 1 $MAX_ITERATIONS); do
    ITER_START_TIME=$(date +%s)
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    LOG_FILE="$LOG_DIR/iteration_${i}_${TIMESTAMP}.log"

    echo ""
    echo "═══ Iteration $i of $MAX_ITERATIONS ═══"
    echo "Started at: $(date)"
    echo "Log file:   $LOG_FILE"
    echo ""

    if cat "$PROMPT_FILE" | $AI_COMMAND 2>&1 | tee "$LOG_FILE"; then
        ITER_STATUS="success"
    else
        ITER_STATUS="error"
        echo "Warning: Iteration $i exited with non-zero status" | tee -a "$LOG_FILE"
    fi

    ITER_END_TIME=$(date +%s)
    ITER_DURATION=$((ITER_END_TIME - ITER_START_TIME))

    echo ""
    echo "Iteration $i completed in ${ITER_DURATION}s (status: $ITER_STATUS)"

    # Check for completion signal
    if grep -q "$COMPLETION_SIGNAL" "$PROGRESS_FILE"; then
        LOOP_END_TIME=$(date +%s)
        LOOP_DURATION=$((LOOP_END_TIME - LOOP_START_TIME))

        echo ""
        echo ════════════════════════════════════════════════════════════
        echo "Done! Completion signal received."
        echo "Total iterations: $i"
        echo "Total duration:   ${LOOP_DURATION}s"
        echo "Completed at:     $(date)"
        echo ════════════════════════════════════════════════════════════
        echo ""
        echo "Next steps:"
        echo "  git add $PROJECT_DIR"
        echo "  git commit -m 'research: $(basename "$PROJECT_DIR")'"
        echo "  git push -u origin $(git rev-parse --abbrev-ref HEAD)"
        exit 0
    fi

    sleep 2
done

LOOP_END_TIME=$(date +%s)
LOOP_DURATION=$((LOOP_END_TIME - LOOP_START_TIME))

echo ""
echo ════════════════════════════════════════════════════════════
echo "Max iterations reached without completion."
echo "Total duration: ${LOOP_DURATION}s"
echo "Ended at:       $(date)"
echo ════════════════════════════════════════════════════════════
echo ""
echo "Next steps:"
echo "  git add $PROJECT_DIR"
echo "  git commit -m 'research: partial $(basename "$PROJECT_DIR")'"
echo "  git push -u origin $(git rev-parse --abbrev-ref HEAD)"
exit 1
