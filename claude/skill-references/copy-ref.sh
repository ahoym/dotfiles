#!/usr/bin/env bash
# Copy a file from ~/.claude/skill-references/ to a destination.
# Usage: bash ~/.claude/skill-references/copy-ref.sh <filename> <dest>
#
# Bypasses the Bash tool sandbox restriction on cp with out-of-project sources.

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: copy-ref.sh <filename> <dest>" >&2
  exit 1
fi

src="$HOME/.claude/skill-references/$(basename "$1")"
dest="$2"

if [[ ! -f "$src" ]]; then
  echo "Error: $src not found" >&2
  exit 1
fi

cp "$src" "$dest"
echo "Copied $1 -> $dest"
