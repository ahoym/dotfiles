#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARBALL="${1:?Usage: import-batch.sh <tarball-path>}"
DATE=$(date +%Y-%m-%d)
BRANCH="batch-import-$DATE-$$"

cd "$REPO_DIR"

# Bail if working tree is dirty
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Working tree has uncommitted changes. Commit or stash first."
  exit 1
fi

# Create import branch from current main
git checkout -b "$BRANCH"

# Safety: verify we're on the import branch before continuing
if [ "$(git branch --show-current)" != "$BRANCH" ]; then
  echo "Failed to checkout branch $BRANCH. Aborting."
  exit 1
fi

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

echo "Import committed on branch: $BRANCH"
echo "Review with: git diff main...$BRANCH"
echo "Merge when ready: git checkout main && git merge $BRANCH"
