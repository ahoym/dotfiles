#!/bin/bash
# PostToolUse(Read) wrapper: dispatches to platform binary. Silent no-op on miss.

# Early exit when the machine hasn't been set up — limits global hook blast radius.
[ -f "$HOME/.claude/learnings-providers.json" ] || exit 0

DIR="$(cd "$(dirname "$0")" && pwd)"

case "$(uname -s)-$(uname -m)" in
  Darwin-arm64)   BIN="$DIR/bin/learnings-read-log-aarch64-darwin" ;;
  Darwin-x86_64)  BIN="$DIR/bin/learnings-read-log-x86_64-darwin" ;;
  Linux-x86_64)   BIN="$DIR/bin/learnings-read-log-x86_64-linux-gnu" ;;
  Linux-aarch64)  BIN="$DIR/bin/learnings-read-log-aarch64-linux-gnu" ;;
  *)              exit 0 ;;
esac

[ -x "$BIN" ] && exec "$BIN"
exit 0
