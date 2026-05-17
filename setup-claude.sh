#!/bin/bash

# Symlinks Claude Code dotfiles from this repo into ~/.claude
# Safe to run multiple times — skips existing symlinks and backs up conflicts.

set -e

DOTFILES_CLAUDE_DIR="$(cd "$(dirname "$0")/claude" && pwd)"
TARGET_DIR="$HOME/.claude"

# Items to symlink (everything in claude/ except README.md)
ITEMS=(CLAUDE.md commands guidelines hooks lab learnings learnings-providers.json ralph settings.json settings.local.json skill-references statusline-command.sh)

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

# --- Platform-specific commands symlink ---
# Creates ~/.claude/platform-commands -> skill-references/{github,gitlab}/commands/
# Skills use !`cat ~/.claude/platform-commands/<cmd>.sh` to inline platform commands.

PLATFORM_FILE="$TARGET_DIR/.platform"
PLATFORM_LINK="$TARGET_DIR/platform-commands"

if [ -f "$PLATFORM_FILE" ]; then
  PLATFORM=$(cat "$PLATFORM_FILE")
  case "$PLATFORM" in
    github|gitlab) ;;
    *) echo "  error: invalid cached platform '$PLATFORM'; delete .platform and re-run"; exit 1 ;;
  esac
  echo "  platform: $PLATFORM (cached in .platform)"
else
  printf "  Which platform does this machine use? [github/gitlab]: "
  read -r PLATFORM
  case "$PLATFORM" in
    github|gitlab) ;;
    *) echo "  error: expected github or gitlab, got $PLATFORM"; exit 1 ;;
  esac
  echo "$PLATFORM" > "$PLATFORM_FILE"
  echo "  platform: $PLATFORM (saved to .platform)"
fi

PLATFORM_SRC="$DOTFILES_CLAUDE_DIR/skill-references/$PLATFORM/commands"

if [ ! -d "$PLATFORM_SRC" ]; then
  echo "  skip   platform-commands ($PLATFORM_SRC not found)"
else
  if [ -L "$PLATFORM_LINK" ] && [ "$(readlink "$PLATFORM_LINK")" = "$PLATFORM_SRC" ]; then
    echo "  ok     platform-commands -> $PLATFORM/commands"
  else
    if [ -e "$PLATFORM_LINK" ] || [ -L "$PLATFORM_LINK" ]; then
      backup="$PLATFORM_LINK.backup.$(date +%s)"
      echo "  backup platform-commands -> $(basename "$backup")"
      mv "$PLATFORM_LINK" "$backup"
    fi
    ln -s "$PLATFORM_SRC" "$PLATFORM_LINK"
    echo "  link   platform-commands -> $PLATFORM/commands"
  fi
fi

# --- Build the learnings-suggest hook binary for this platform ---
# Idempotent. Falls back silently if Rust toolchain is unavailable.

HOOK_BOOTSTRAP="$DOTFILES_CLAUDE_DIR/hooks/learnings-suggest/bootstrap.sh"
if [ -x "$HOOK_BOOTSTRAP" ]; then
  echo "  hook   learnings-suggest"
  "$HOOK_BOOTSTRAP" || echo "  warn   learnings-suggest build failed — hook will no-op"

  # Build the section index used by the suggest hook (iteration 2a).
  INDEX_BUILDER=""
  case "$(uname -s)-$(uname -m)" in
    Darwin-arm64)   INDEX_BUILDER="$DOTFILES_CLAUDE_DIR/hooks/learnings-suggest/bin/learnings-index-build-aarch64-darwin" ;;
    Darwin-x86_64)  INDEX_BUILDER="$DOTFILES_CLAUDE_DIR/hooks/learnings-suggest/bin/learnings-index-build-x86_64-darwin" ;;
    Linux-x86_64)   INDEX_BUILDER="$DOTFILES_CLAUDE_DIR/hooks/learnings-suggest/bin/learnings-index-build-x86_64-linux-gnu" ;;
    Linux-aarch64)  INDEX_BUILDER="$DOTFILES_CLAUDE_DIR/hooks/learnings-suggest/bin/learnings-index-build-aarch64-linux-gnu" ;;
  esac
  if [ -n "$INDEX_BUILDER" ] && [ -x "$INDEX_BUILDER" ]; then
    "$INDEX_BUILDER" 2>&1 | sed 's/^/  index  /' || true
  fi
fi
