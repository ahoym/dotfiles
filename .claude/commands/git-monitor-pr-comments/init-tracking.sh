#!/bin/bash
# Initialize PR comment tracking
# Usage: ./init-tracking.sh <owner/repo> <pr-number>

REPO="$1"
PR="$2"
mkdir -p ./tmp
PROCESSED_FILE="./tmp/pr${PR}_processed_comments.txt"

# Get all current PR review comment IDs
gh api repos/$REPO/pulls/$PR/comments --jq '.[].id' > "$PROCESSED_FILE" 2>/dev/null

# Get all current issue comment IDs (prefixed to distinguish)
gh api repos/$REPO/issues/$PR/comments --jq '.[].id' | sed 's/^/issue:/' >> "$PROCESSED_FILE" 2>/dev/null

echo "Initialized tracking for PR #$PR"
echo "Tracking file: $PROCESSED_FILE"
echo "Comments tracked: $(wc -l < "$PROCESSED_FILE" | tr -d ' ')"
