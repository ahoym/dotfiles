#!/usr/bin/env bash
set -euo pipefail

# Usage: worktree-commit.sh <worktree-path> <commit-message>

WORKTREE="$1"
MESSAGE="$2"

git -C "$WORKTREE" add .claude/ docs/
git -C "$WORKTREE" commit -m "$MESSAGE"
