#!/usr/bin/env bash
# Copies staged learnings files to their final locations and cleans up.
# Called by the extract-request-learnings orchestrator after writers complete.
#
# Usage: bash ~/.claude/commands/extract-request-learnings/finalize-staging.sh [project-root]
#
# Reads ~/.claude/learnings-providers.json to discover provider directories.
# General staging → all writable providers with writeScope "global"
# Private staging → all writable providers with writeScope "private"
#
# Expects staging dirs at:
#   <project-root>/docs/learnings/_staging/general/
#   <project-root>/docs/learnings/_staging/private/

set -euo pipefail

ROOT="${1:-.}"

GENERAL_STAGING="$ROOT/docs/learnings/_staging/general"
PRIVATE_STAGING="$ROOT/docs/learnings/_staging/private"

PROVIDERS_FILE="$HOME/.claude/learnings-providers.json"

copied=0

# Resolve ~ in localPath to $HOME
resolve_path() {
  local p="$1"
  echo "${p/#\~/$HOME}"
}

# Copy files from staging to a target directory, handling java/ subdirectory
copy_to_target() {
  local staging_dir="$1"
  local target_dir="$2"

  [ -d "$staging_dir" ] || return 0

  mkdir -p "$target_dir"

  for f in "$staging_dir"/*.md; do
    [ -f "$f" ] || continue
    local base
    base=$(basename "$f")
    cp "$f" "$target_dir/$base"
    copied=$((copied + 1))
  done

  # Handle java/ subdirectory if present
  if [ -d "$staging_dir/java" ]; then
    mkdir -p "$target_dir/java"
    for f in "$staging_dir"/java/*.md; do
      [ -f "$f" ] || continue
      local base
      base=$(basename "$f")
      cp "$f" "$target_dir/java/$base"
      copied=$((copied + 1))
    done
  fi
}

if [ ! -f "$PROVIDERS_FILE" ]; then
  echo "Error: $PROVIDERS_FILE not found" >&2
  exit 1
fi

# Copy general learnings to all writable global-scope providers
if [ -d "$GENERAL_STAGING" ]; then
  while IFS= read -r raw_path; do
    target=$(resolve_path "$raw_path")
    copy_to_target "$GENERAL_STAGING" "$target"
  done < <(jq -r '.providers[] | select(.writable == true and .writeScope == "global") | .localPath' "$PROVIDERS_FILE")
fi

# Copy private learnings to all writable private-scope providers
if [ -d "$PRIVATE_STAGING" ]; then
  while IFS= read -r raw_path; do
    target=$(resolve_path "$raw_path")
    copy_to_target "$PRIVATE_STAGING" "$target"
  done < <(jq -r '.providers[] | select(.writable == true and .writeScope == "private") | .localPath' "$PROVIDERS_FILE")
fi

# Clean up staging
rm -rf "$ROOT/docs/learnings/_staging"

echo "Finalized: $copied files copied, staging cleaned."
