#!/bin/bash
# PreToolUse hook: restricts Read/Glob/Grep to claude/ and docs/learnings/ within the worktree.
# Usage: guard-read-scope.sh <worktree_root>
# Used by consolidation loops to prevent out-of-scope reads.
# Exit 0 = allow, Exit 2 + stderr = block

WORKTREE_ROOT="$1"
if [ -z "$WORKTREE_ROOT" ]; then
  echo "BLOCKED: No worktree root specified for read scope guard" >&2
  exit 2
fi

INPUT=$(cat)

# Read uses file_path; Glob/Grep use path
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')

# If no path specified (Glob/Grep default to CWD = worktree root), block — must be explicit
if [ -z "$FILE_PATH" ]; then
  echo "BLOCKED: Path must be explicitly scoped to claude/ or docs/learnings/" >&2
  exit 2
fi

# Allow reads within claude/ or docs/learnings/ inside the worktree
case "$FILE_PATH" in
  "$WORKTREE_ROOT/claude/"*|"$WORKTREE_ROOT/claude")
    exit 0
    ;;
  "$WORKTREE_ROOT/docs/learnings/"*|"$WORKTREE_ROOT/docs/learnings")
    exit 0
    ;;
  *)
    echo "BLOCKED: Read outside allowed scope: $FILE_PATH (allowed: claude/, docs/learnings/)" >&2
    exit 2
    ;;
esac
