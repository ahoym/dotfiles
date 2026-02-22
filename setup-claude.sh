#!/bin/bash

# Symlinks Claude Code dotfiles from this repo into ~/.claude
# Safe to run multiple times — skips existing symlinks and backs up conflicts.

set -e

DOTFILES_CLAUDE_DIR="$(cd "$(dirname "$0")/.claude" && pwd)"
TARGET_DIR="$HOME/.claude"

# Items to symlink (everything in .claude/ except README.md)
ITEMS=(commands guidelines lab learnings settings.local.json)

if [ ! -d "$TARGET_DIR" ]; then
  mkdir -p "$TARGET_DIR"
fi

for item in "${ITEMS[@]}"; do
  src="$DOTFILES_CLAUDE_DIR/$item"
  dest="$TARGET_DIR/$item"

  if [ ! -e "$src" ]; then
    echo "  skip   $item (not found in dotfiles)"
    continue
  fi

  # Already correctly symlinked
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "  ok     $item"
    continue
  fi

  # Something else exists at the destination — back it up
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    backup="$dest.backup.$(date +%s)"
    echo "  backup $item -> $(basename "$backup")"
    mv "$dest" "$backup"
  fi

  ln -s "$src" "$dest"
  echo "  link   $item -> $src"
done
