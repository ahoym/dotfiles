#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTDIR="${1:-.}"
DATE=$(date +%Y-%m-%d)
TARBALL="$OUTDIR/claude-batch-$DATE.tar.gz"

cd "$REPO_DIR"

tar czf "$TARBALL" \
  --exclude='.claude/learnings-private' \
  --exclude='.git' \
  --exclude='.claude/settings.local.json' \
  --exclude='.claude/worktrees' \
  --exclude='.claude/tracking-artifacts' \
  --exclude='.claude/ralph' \
  --exclude='.claude/plans' \
  --exclude='.claude/scheduled_tasks.lock' \
  .claude/

echo "Exported: $TARBALL"
