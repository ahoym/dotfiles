#!/bin/bash
# PreToolUse hook: restricts Write/Edit to the project directory
# Usage: guard-write-scope.sh <project_dir>
# Used by ralph loops to prevent out-of-scope writes.
# Exit 0 = allow, Exit 2 + stderr = block

PROJECT_DIR="$1"
if [ -z "$PROJECT_DIR" ]; then
  echo "BLOCKED: No project directory specified for write scope guard" >&2
  exit 2
fi

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Allow writes within the project directory
case "$FILE_PATH" in
  "$PROJECT_DIR"/*)
    exit 0
    ;;
  "$PROJECT_DIR")
    exit 0
    ;;
  *)
    echo "BLOCKED: Write outside project scope: $FILE_PATH (allowed: $PROJECT_DIR/)" >&2
    exit 2
    ;;
esac
