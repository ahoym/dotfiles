#!/bin/bash
# PreToolUse hook: restricts Write/Edit to claude/ within the worktree.
# Usage: guard-write-scope.sh <worktree_root>
# Used by consolidation loops to prevent out-of-scope writes.
# Exit 0 = allow, Exit 2 + stderr = block

WORKTREE_ROOT="$1"
if [ -z "$WORKTREE_ROOT" ]; then
  echo "BLOCKED: No worktree root specified for write scope guard" >&2
  exit 2
fi

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Allow writes within claude/ inside the worktree
case "$FILE_PATH" in
  "$WORKTREE_ROOT/claude/"*)
    exit 0
    ;;
  "$WORKTREE_ROOT/claude")
    exit 0
    ;;
  *)
    echo "BLOCKED: Write outside allowed scope: $FILE_PATH (allowed: $WORKTREE_ROOT/claude/)" >&2
    exit 2
    ;;
esac
