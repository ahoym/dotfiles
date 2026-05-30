#!/bin/bash
# Rebuild ~/.claude/claude-artifacts/ast/sections.json from the federated learnings corpus.
# Invoked from /learnings:curate after content edits. Silent no-op if binary is missing.

DIR="$(cd "$(dirname "$0")" && pwd)"

case "$(uname -s)-$(uname -m)" in
  Darwin-arm64)   BIN="$DIR/bin/learnings-index-build-aarch64-darwin" ;;
  Darwin-x86_64)  BIN="$DIR/bin/learnings-index-build-x86_64-darwin" ;;
  Linux-x86_64)   BIN="$DIR/bin/learnings-index-build-x86_64-linux-gnu" ;;
  Linux-aarch64)  BIN="$DIR/bin/learnings-index-build-aarch64-linux-gnu" ;;
  *)              exit 0 ;;
esac

[ -x "$BIN" ] && exec "$BIN"
exit 0
