#!/usr/bin/env bash
# Bootstrap a director session: create the session dir and initialize
# session.json (append-only item index) and decisions.md (decision log).
#
# Usage: director-bootstrap.sh <timestamp>
#   <timestamp>: e.g. 2026-04-24-2101 (date +%Y-%m-%d-%H%M)
#
# Prints the session dir path on stdout. Errors if the dir already exists.

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <timestamp>" >&2
  exit 1
fi

TIMESTAMP="$1"
SESSION_DIR="tmp/claude-artifacts/director-sessions/$TIMESTAMP"
ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)

if [ -e "$SESSION_DIR" ]; then
  echo "Session dir already exists: $SESSION_DIR" >&2
  exit 1
fi

mkdir -p "$SESSION_DIR"

cat > "$SESSION_DIR/session.json" <<EOF
{
  "created_at": "$ISO",
  "session_dir": "$SESSION_DIR",
  "items": {}
}
EOF

cat > "$SESSION_DIR/decisions.md" <<EOF
# Director Decisions — $TIMESTAMP
EOF

echo "$SESSION_DIR"
