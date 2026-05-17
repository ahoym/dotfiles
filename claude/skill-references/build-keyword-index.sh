#!/bin/bash
# Rebuild the keyword index for claude/learnings.
# Output: tmp/claude-artifacts/keyword-index/keyword-index.json (gitignored staging file).
# After inspecting, promote via:
#   cp tmp/claude-artifacts/keyword-index/keyword-index.json claude/learnings/.keyword-index.json
set -euo pipefail
SCRIPT_DIR=$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
cd "$REPO_ROOT"
mkdir -p tmp/claude-artifacts/keyword-index
exec node "$SCRIPT_DIR/build-keyword-index.js"
