#!/bin/bash
# Initialize a sweep PR run directory with per-PR subdirs + shared preflight.
# Usage: init-sweep-pr-dir.sh <run_dir> <pr_numbers...>
#
# Creates:
#   <run_dir>/
#   <run_dir>/pr-<N>/        (one per PR number)
#   <run_dir>/sweep-pr-preflight.md  (copy of shared preflight)
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $0 <run_dir> <pr_numbers...>" >&2
  exit 1
fi

RUN_DIR="$1"
shift

# Validate PR numbers up front so a typo doesn't half-initialize the run-dir
# with malformed `pr-foo/` or `pr----retro/` subdirs (which sweep-status-summary
# would later surface via its `pr-*` glob).
for pr in "$@"; do
  [[ "$pr" =~ ^[0-9]+$ ]] || { echo "ERROR: not a PR number: $pr" >&2; exit 1; }
done

mkdir -p "$RUN_DIR"
for pr in "$@"; do
  mkdir -p "$RUN_DIR/pr-$pr"
done

PREFLIGHT_SRC="$HOME/.claude/skill-references/sweep-pr-preflight.md"
if [ -f "$PREFLIGHT_SRC" ]; then
  cp "$PREFLIGHT_SRC" "$RUN_DIR/sweep-pr-preflight.md"
fi

echo "Initialized $RUN_DIR with $# PR subdirectories"
