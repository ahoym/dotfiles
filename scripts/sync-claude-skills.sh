#!/usr/bin/env bash
set -euo pipefail

DOTFILES="/Users/malcolmahoy/WORKSPACE/dotfiles"
MAHOY="/Users/malcolmahoy/WORKSPACE/mahoy-claude-stuff"

SYNC_DIRS=(
  ".claude/commands/"
  ".claude/guidelines/"
  ".claude/learnings/"
  "docs/claude-learnings/"
)

EXCLUDES=(
  "--exclude=settings.json"
  "--exclude=settings.local.json"
  "--exclude=README.md"
  "--exclude=lab/"
  "--exclude=personas/"
  "--exclude=worktrees/"
)

usage() {
  echo "Usage: $0 {diff|dotfiles-to-mahoy|mahoy-to-dotfiles}"
  echo ""
  echo "Modes:"
  echo "  diff               Show what would change (dry run, both directions)"
  echo "  dotfiles-to-mahoy  Sync from dotfiles → mahoy-claude-stuff"
  echo "  mahoy-to-dotfiles  Sync from mahoy-claude-stuff → dotfiles"
  exit 1
}

sync_dirs() {
  local src="$1"
  local dst="$2"
  local dry_run="$3"
  local direction="$4"

  echo ""
  echo "=== $direction ==="
  echo ""

  local has_changes=false

  for dir in "${SYNC_DIRS[@]}"; do
    local src_path="$src/$dir"
    local dst_path="$dst/$dir"

    # Skip if source dir doesn't exist
    if [[ ! -d "$src_path" ]]; then
      continue
    fi

    # Ensure destination parent exists
    mkdir -p "$dst_path"

    if [[ "$dry_run" == "true" ]]; then
      local output
      output=$(rsync -avn --delete "${EXCLUDES[@]}" "$src_path" "$dst_path" 2>&1 || true)
      if echo "$output" | grep -qv '^\(sending\|sent\|total\|$\|building\|\.\/\)'; then
        has_changes=true
        echo "--- $dir ---"
        echo "$output" | grep -v '^\(sending\|sent\|total\|$\|building\)'
        echo ""
      fi
    else
      echo "--- Syncing $dir ---"
      rsync -av --delete "${EXCLUDES[@]}" "$src_path" "$dst_path"
      echo ""
    fi
  done

  if [[ "$dry_run" == "true" && "$has_changes" == "false" ]]; then
    echo "No changes detected."
  fi
}

confirm() {
  local direction="$1"
  echo ""
  read -r -p "Apply changes ($direction)? [y/N] " response
  case "$response" in
    [yY][eE][sS]|[yY]) return 0 ;;
    *) echo "Aborted."; exit 0 ;;
  esac
}

[[ $# -lt 1 ]] && usage

case "$1" in
  diff)
    sync_dirs "$DOTFILES" "$MAHOY" "true" "dotfiles → mahoy"
    sync_dirs "$MAHOY" "$DOTFILES" "true" "mahoy → dotfiles"
    ;;
  dotfiles-to-mahoy)
    sync_dirs "$DOTFILES" "$MAHOY" "true" "dotfiles → mahoy (preview)"
    confirm "dotfiles → mahoy"
    sync_dirs "$DOTFILES" "$MAHOY" "false" "dotfiles → mahoy"
    echo "Sync complete."
    ;;
  mahoy-to-dotfiles)
    sync_dirs "$MAHOY" "$DOTFILES" "true" "mahoy → dotfiles (preview)"
    confirm "mahoy → dotfiles"
    sync_dirs "$MAHOY" "$DOTFILES" "false" "mahoy → dotfiles"
    echo "Sync complete."
    ;;
  *)
    usage
    ;;
esac
