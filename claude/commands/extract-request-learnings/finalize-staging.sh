#!/usr/bin/env bash
# Copies staged learnings files to their final locations and cleans up.
# Called by the extract-request-learnings orchestrator after writers complete.
#
# Usage: bash ~/.claude/commands/extract-request-learnings/finalize-staging.sh [project-root]
#
# Expects staging dirs at:
#   <project-root>/docs/learnings/_staging/general/
#   <project-root>/docs/learnings/_staging/private/

set -euo pipefail

ROOT="${1:-.}"

GENERAL_STAGING="$ROOT/docs/learnings/_staging/general"
PRIVATE_STAGING="$ROOT/docs/learnings/_staging/private"

copied=0

# Copy general learnings to personal and learnings-team (shared team)
if [ -d "$GENERAL_STAGING" ]; then
  for f in "$GENERAL_STAGING"/*.md; do
    [ -f "$f" ] || continue
    base=$(basename "$f")
    # Check if file belongs in a subdirectory (e.g., java/spring-boot-gotchas.md)
    # For now, flat copy — subdirectory routing handled by writer naming
    cp "$f" ~/.claude/learnings/"$base"
    cp "$f" ~/.claude/learnings-team/learnings/"$base"
    copied=$((copied + 1))
  done
  # Handle java/ subdirectory if present
  if [ -d "$GENERAL_STAGING/java" ]; then
    mkdir -p ~/.claude/learnings/java ~/.claude/learnings-team/learnings/java
    for f in "$GENERAL_STAGING"/java/*.md; do
      [ -f "$f" ] || continue
      base=$(basename "$f")
      cp "$f" ~/.claude/learnings/java/"$base"
      cp "$f" ~/.claude/learnings-team/learnings/java/"$base"
      copied=$((copied + 1))
    done
  fi
fi

# Copy private learnings
if [ -d "$PRIVATE_STAGING" ]; then
  for f in "$PRIVATE_STAGING"/*.md; do
    [ -f "$f" ] || continue
    base=$(basename "$f")
    cp "$f" ~/.claude/learnings-private/"$base"
    copied=$((copied + 1))
  done
fi

# Clean up staging
rm -rf "$ROOT/docs/learnings/_staging"

echo "Finalized: $copied files copied, staging cleaned."
