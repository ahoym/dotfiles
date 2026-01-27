#!/bin/bash
# A basic implementation of the Ralph Loop
# Usage: ./wiggum.sh <project_directory> [max_iterations]
#
# Example:
#   ./wiggum.sh ./docs/claude-learnings/monte-carlo 10

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Require project directory as first argument
if [ -z "$1" ]; then
    echo "Usage: $0 <project_directory> [max_iterations]"
    echo "Example: $0 ./docs/claude-learnings/monte-carlo 10"
    exit 1
fi

PROJECT_DIR="$1"
PROMPT_FILE="${PROJECT_DIR}/spec.md"
PROGRESS_FILE="${PROJECT_DIR}/progress.md"
LOG_DIR="${PROJECT_DIR}/logs"
COMPLETION_SIGNAL=${3:-"WOOT_COMPLETE_WOOT"}
MAX_ITERATIONS=${2:-10}
AI_COMMAND="claude --dangerously-skip-permissions --print"
# AI_COMMAND="claude --print"

# Validate project directory exists
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

# Create logs directory
mkdir -p "$LOG_DIR"

echo "════════════════════════════════════════════════════════════"
echo "Starting Ralph Loop"
echo "════════════════════════════════════════════════════════════"
echo "Project:        $PROJECT_DIR"
echo "Spec file:      $PROMPT_FILE"
echo "Progress file:  $PROGRESS_FILE"
echo "Log directory:  $LOG_DIR"
echo "Max iterations: $MAX_ITERATIONS"
echo "Started at:     $(date)"
echo "════════════════════════════════════════════════════════════"

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
    echo "Current progress:"
    cat "$PROGRESS_FILE"
    echo ""
    echo "───────────────────────────────────────"

    # Run the AI command, feeding it the prompt file contents
    # Capture output to log file and display to console
    if cat "$PROMPT_FILE" | $AI_COMMAND 2>&1 | tee "$LOG_FILE"; then
        ITER_STATUS="success"
    else
        ITER_STATUS="error"
        echo "Warning: Iteration $i exited with non-zero status" | tee -a "$LOG_FILE"
    fi

    ITER_END_TIME=$(date +%s)
    ITER_DURATION=$((ITER_END_TIME - ITER_START_TIME))

    echo ""
    echo "───────────────────────────────────────"
    echo "Iteration $i completed in ${ITER_DURATION}s (status: $ITER_STATUS)"

    # Check for the completion signal (e.g., WOOT_COMPLETE_WOOT)
    if grep -q "$COMPLETION_SIGNAL" "$PROGRESS_FILE"; then
        LOOP_END_TIME=$(date +%s)
        LOOP_DURATION=$((LOOP_END_TIME - LOOP_START_TIME))
        echo ""
        echo "════════════════════════════════════════════════════════════"
        echo "Done! Completion signal received."
        echo "Total iterations: $i"
        echo "Total duration:   ${LOOP_DURATION}s"
        echo "Completed at:     $(date)"
        echo "════════════════════════════════════════════════════════════"
        exit 0
    fi

    # Short sleep to avoid rate limiting
    sleep 2
done

LOOP_END_TIME=$(date +%s)
LOOP_DURATION=$((LOOP_END_TIME - LOOP_START_TIME))

echo ""
echo "════════════════════════════════════════════════════════════"
echo "Max iterations reached without completion."
echo "Total duration: ${LOOP_DURATION}s"
echo "Ended at:       $(date)"
echo "════════════════════════════════════════════════════════════"
exit 1
