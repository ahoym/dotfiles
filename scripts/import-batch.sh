#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARBALL="${1:?Usage: import-batch.sh <tarball-path>}"
BRANCH="batch-import"
DATE=$(date +%Y-%m-%d)

cd "$REPO_DIR"

# Bail if working tree is dirty
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Working tree has uncommitted changes. Commit or stash first."
  exit 1
fi

# Create import branch from current main
git checkout -b "$BRANCH"

# Extract tarball (overwrites shared content, learnings-private excluded at export time)
tar xzf "$TARBALL" -C .

# Commit the batch state
git add -A
if git diff --cached --quiet; then
  echo "No changes to import."
  git checkout main
  git branch -d "$BRANCH"
  exit 0
fi
git commit -m "batch import $DATE"

# Merge into main
git checkout main
git merge "$BRANCH" -m "merge batch import $DATE"

# Clean up
git branch -d "$BRANCH"

echo "Batch import merged. Review with: git log --oneline -5"
echo "Push when ready: git push"
