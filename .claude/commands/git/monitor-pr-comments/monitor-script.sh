#!/bin/bash
# PR Comment Monitor Script
# Usage: ./monitor-script.sh <owner/repo> <pr-number> [interval-seconds] [timeout-minutes]

REPO="$1"
PR="$2"
INTERVAL="${3:-30}"
TIMEOUT_MINUTES="${4:-0}"
mkdir -p ./tmp
PROCESSED_FILE="./tmp/pr${PR}_processed_comments.txt"

echo "=== PR #$PR Monitor Started at $(date '+%Y-%m-%d %H:%M:%S') ==="
echo "Checking every $INTERVAL seconds for new comments..."
if [ "$TIMEOUT_MINUTES" -gt 0 ]; then
    echo "Will auto-stop after $TIMEOUT_MINUTES minute(s)"
fi
echo ""

START_TIME=$(date +%s)

while true; do
    # Check timeout
    if [ "$TIMEOUT_MINUTES" -gt 0 ]; then
        ELAPSED=$(( $(date +%s) - START_TIME ))
        TIMEOUT_SECONDS=$(( TIMEOUT_MINUTES * 60 ))
        if [ "$ELAPSED" -ge "$TIMEOUT_SECONDS" ]; then
            echo ""
            echo "=== Monitor stopped after $TIMEOUT_MINUTES minute(s) ==="
            exit 0
        fi
    fi
    # Get current PR review comments
    PR_COMMENTS=$(gh api repos/$REPO/pulls/$PR/comments --jq '.[] | "\(.id)|\(.user.login)|\(.body | gsub("\n"; " ") | .[0:150])"' 2>/dev/null)

    # Get current issue comments
    ISSUE_COMMENTS=$(gh api repos/$REPO/issues/$PR/comments --jq '.[] | "issue:\(.id)|\(.user.login)|\(.body | gsub("\n"; " ") | .[0:150])"' 2>/dev/null)

    NEW_FOUND=0

    # Check PR comments for new ones
    while IFS='|' read -r id user body; do
        if [ -n "$id" ] && ! grep -q "^${id}$" "$PROCESSED_FILE" 2>/dev/null; then
            echo ""
            echo "=== NEW COMMENT at $(date '+%H:%M:%S') ==="
            echo "ID: $id"
            echo "User: $user"
            echo "Body: $body"
            echo "================================"
            NEW_FOUND=1
        fi
    done <<< "$PR_COMMENTS"

    # Check issue comments for new ones
    while IFS='|' read -r id user body; do
        if [ -n "$id" ] && ! grep -q "^${id}$" "$PROCESSED_FILE" 2>/dev/null; then
            echo ""
            echo "=== NEW ISSUE COMMENT at $(date '+%H:%M:%S') ==="
            echo "ID: $id"
            echo "User: $user"
            echo "Body: $body"
            echo "================================"
            NEW_FOUND=1
        fi
    done <<< "$ISSUE_COMMENTS"

    if [ $NEW_FOUND -eq 0 ]; then
        echo -n "."
    fi

    sleep $INTERVAL
done
