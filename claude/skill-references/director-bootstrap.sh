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

# Strict format guard: prevents path traversal, JSON-injection via the heredoc
# below, and stray quotes in the markdown heading. Closes TOCTOU together with
# the atomic mkdir below — same-minute parallel /director invocations both pass
# the regex but only one wins the mkdir.
if [[ ! "$TIMESTAMP" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4}$ ]]; then
  echo "ERROR: timestamp must match YYYY-MM-DD-HHMM (got: $TIMESTAMP)" >&2
  exit 1
fi

SESSION_DIR="tmp/claude-artifacts/director-sessions/$TIMESTAMP"
ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Atomic — no `-p`. Fails on the loser of any race; parent dir must already
# exist (caller's responsibility, satisfied by tmp/claude-artifacts/* lifecycle).
mkdir -p tmp/claude-artifacts/director-sessions
mkdir "$SESSION_DIR"

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
